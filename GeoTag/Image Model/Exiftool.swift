//
// Copyright 2016 Marco S Hyman
// See LICENSE file for info
// https://www.snafu.org/
//

import MapKit
import OSLog
import SwiftUI

/// manage GeoTag's use of exiftool

struct Exiftool {
    @AppStorage(AppSettings.updateFileModificationTimesKey)
    var updateFileModificationTimes = false
    @AppStorage(AppSettings.updateGPSTimestampsKey) var updateGPSTimestamps =
        false

    // singleton instance of this class
    static let helper = Exiftool()
    let dateFormatter = DateFormatter()

    enum ExiftoolError: Error {
        case runFailed(code: Int)
    }

    // URL of the embedded version of ExifTool
    var url: URL

    // File Type codes for the file types that exiftool can write
    //
    // Last updated to match ExifTool version 12.30
    let writableTypes: Set = [
        "360", "3G2", "3GP", "AAX", "AI", "ARQ", "ARW", "AVIF", "CR2", "CR3",
        "CRM", "CRW", "CS1", "DCP", "DNG", "DR4", "DVB", "EPS", "ERF", "EXIF",
        "EXV", "F4A/V", "FFF", "FLIF", "GIF", "GPR", "HDP", "HEIC", "HEIF",
        "ICC", "IIQ", "IND", "INSP", "JNG", "JP2", "JPEG", "LRV", "M4A/V",
        "MEF", "MIE", "MNG", "MOS", "MOV", "MP4", "MPO", "MQV", "MRW",
        "NEF", "NRW", "ORF", "ORI", "PBM", "PDF", "PEF", "PGM", "PNG",
        "PPM", "PS", "PSB", "PSD", "QTIF", "RAF", "RAW", "RW2",
        "RWL", "SR2", "SRW", "THM", "TIFF", "VRD", "WDP", "X3F", "XMP"
    ]

    // Build the url needed to access to the embedded version of ExifTool

    private init() {
        if let exiftoolUrl = Bundle.main.url(
            forResource: "ExifTool",
            withExtension: nil)
        {
            url = exiftoolUrl.appendingPathComponent("exiftool")
        } else {
            fatalError("The Application Bundle is corrupt.")
        }
    }
}

extension Exiftool {
    static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier!,
        category: "ExifTool")

}

extension Exiftool {

    /// Use the embedded copy of exiftool to update the geolocation metadata
    /// in the file containing the passed image
    /// - Parameter image: the image to update.  image contains the URL
    ///     of the original file plus the assigned location.
    /// - Parameter timeZone: time zone used to calculate the GPS timestamp

    func update(from sandbox: Sandbox, timeZone: TimeZone?) async throws {
        // ExifTool argument names
        var latArg = "-GPSLatitude="
        var lonArg = "-GPSLongitude="
        var latRefArg = "-GPSLatitudeRef="
        var lonRefArg = "-GPSLongitudeRef="
        var eleArg = "-GPSaltitude="
        var eleRefArg = "-GPSaltitudeRef="
        var cityArg = "-city="
        var stateArg = "-state="
        var countryArg = "-country="
        var countryCodeArg = "-countryCode="

        // ExifTool GSPDateTime arg storage
        var gpsDArg = "-GPSDateStamp="  // for non XMP files
        var gpsTArg = "-GPSTimeStamp="  // for non XMP files
        var gpsDTArg = "-GPSDateTime="  // for XMP files

        var usingSidecar = false

        // Build ExifTool latitude, longitude, and elevation argument values
        if let location = sandbox.image.location {
            latArg += "\(location.latitude)"
            latRefArg += "\(location.latitude)"
            lonArg += "\(location.longitude)"
            lonRefArg += "\(location.longitude)"
            if let ele = sandbox.image.elevation {
                if ele >= 0 {
                    eleArg += "\(ele)"
                    eleRefArg += "0"
                } else {
                    eleArg += "\(-ele)"
                    eleRefArg += "1"
                }
            }
            cityArg += sandbox.image.city ?? ""
            stateArg += sandbox.image.state ?? ""
            countryArg += sandbox.image.country ?? ""
            countryCodeArg += sandbox.image.countryCode ?? ""
        }

        // path to image (or XMP) file to update.
        var path = sandbox.imageURL.path
        if sandbox.image.sidecarExists {
            path = sandbox.sidecarURL.path
            usingSidecar = true
        }

        let exiftool = Process()
        let pipe = Pipe()
        exiftool.standardOutput = FileHandle.nullDevice
        exiftool.standardError = pipe
        exiftool.executableURL = url
        exiftool.arguments = [
            "-q",
            "-m",
            "-overwrite_original_in_place",
            latArg, latRefArg,
            lonArg, lonRefArg,
            eleArg, eleRefArg,
            cityArg, stateArg,
            countryArg, countryCodeArg
        ]
        if updateFileModificationTimes {
            exiftool.arguments! += ["-FileModifyDate<DateTimeOriginal"]
        }

        if updateGPSTimestamps,
            let gpsTimestamp = gpsTimestamp(for: sandbox.image, in: timeZone)
        {

            // args vary depending upon saving to an image file or a GPX file
            if usingSidecar {
                gpsDTArg += gpsTimestamp
                exiftool.arguments?.append(gpsDTArg)
            } else {
                let dtArgs = gpsTimestamp.split(separator: " ")
                gpsDArg += dtArgs[0]
                gpsTArg += dtArgs[1]
                exiftool.arguments? += [gpsDArg, gpsTArg]
            }
        }

        // add args to update date/time if changed
        if sandbox.image.dateTimeCreated
            != sandbox.image.originalDateTimeCreated
        {
            let dtoArg =
                "-DateTimeOriginal=" + (sandbox.image.dateTimeCreated ?? "")
            let cdArg = "-CreateDate=" + (sandbox.image.dateTimeCreated ?? "")
            exiftool.arguments! += [dtoArg, cdArg]
        }
        exiftool.arguments! += ["-GPSStatus=", path]
        //        dump(exiftool.arguments!)
        try exiftool.run()
        exiftool.waitUntilExit()
        logFrom(pipe: pipe)
        if exiftool.terminationStatus != 0 {
            throw ExiftoolError.runFailed(code: Int(exiftool.terminationStatus))
        }
    }

    // convert the dateTimeCreated string to a string with time zone to
    // update GPS timestamp fields.  Return nil if there is
    // no timestamp or formatting failed.

    func gpsTimestamp(
        for image: ImageModel,
        in timeZone: TimeZone?
    ) -> String? {
        if let dateTime = image.dateTimeCreated {
            dateFormatter.dateFormat = ImageModel.dateFormat
            dateFormatter.timeZone = timeZone
            if let date = dateFormatter.date(from: dateTime) {
                dateFormatter.dateFormat = "yyyy:MM:dd HH:mm:ss"
                dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
                return dateFormatter.string(from: date) + "Z"
            }
        }
        return nil
    }

    /// Check if exiftool supports writing to a type of file
    /// - Parameter for: a URL of a file to check
    /// - Returns: true if exiftool can write to the file type of the URL

    func fileTypeIsWritable(for file: URL) -> Bool {
        let exiftool = Process()
        let pipe = Pipe()
        let err = Pipe()
        exiftool.standardOutput = pipe
        exiftool.standardError = err
        exiftool.executableURL = url
        exiftool.arguments = [
            "-m", "-q", "-S", "-fast3", "-FileType", file.path
        ]
        do {
            try exiftool.run()
            exiftool.waitUntilExit()
            logFrom(pipe: err)
            if exiftool.terminationStatus == 0 {
                let data = pipe.fileHandleForReading.availableData
                if data.count > 0,
                    let str = String(data: data, encoding: String.Encoding.utf8)
                {
                    let trimmed = str.trimmingCharacters(
                        in: CharacterSet.whitespacesAndNewlines)
                    let strParts = trimmed.components(
                        separatedBy: CharacterSet.whitespaces)
                    if let fileType = strParts.last {
                        return writableTypes.contains(fileType)
                    }
                }
            }
        } catch {
            Self.logger.error(
                "fileTypeIsWritable: \(error.localizedDescription, privacy: .public)"
            )
        }
        return false
    }

    /// create a sidecar file from an image file

    func makeSidecar(from sandbox: Sandbox) {
        let exiftool = Process()
        let err = Pipe()
        exiftool.standardOutput = FileHandle.nullDevice
        exiftool.standardError = err
        exiftool.executableURL = url
        exiftool.arguments = [
            "-tagsfromfile",
            sandbox.imageURL.path,
            sandbox.sidecarURL.path
        ]
        do {
            try exiftool.run()
        } catch {
            Self.logger.error(
                "makeSidecar: \(error.localizedDescription, privacy: .public)")
        }
        exiftool.waitUntilExit()
        logFrom(pipe: err)
    }

    // return selected metadate from a file
    // - Parameter xmp: URL of XMP file
    // - Returns: (dto: String, lat: Double, latRef: String, lon: Double, lonRef: String)
    //
    // Apple's ImageIO functions can not extract metadata from XMP sidecar
    // files.  ExifTool is used for that purpose.
    // swiftlint:disable large_tuple
    // swiftlint:disable cyclomatic_complexity
    func metadataFrom(xmp: URL) -> (
        dto: String,
        valid: Bool,
        location: Coords,
        elevation: Double?
    ) {
        let exiftool = Process()
        let pipe = Pipe()
        let err = Pipe()
        exiftool.standardOutput = pipe
        exiftool.standardError = err
        exiftool.executableURL = url
        exiftool.arguments = [
            "-args", "-c", "%.15f", "-createdate",
            "-gpsstatus", "-gpslatitude", "-gpslongitude",
            "-gpsaltitude", xmp.path
        ]
        do {
            try exiftool.run()
        } catch {
            Self.logger.error(
                "metadataFrom: \(error.localizedDescription, privacy: .public)")
        }
        exiftool.waitUntilExit()
        logFrom(pipe: err)

        var createDate = ""
        var location = Coords()
        var elevation: Double?
        var validGPS = false

        if exiftool.terminationStatus == 0 {
            let data = pipe.fileHandleForReading.availableData
            if data.count > 0,
                let str = String(data: data, encoding: String.Encoding.utf8)
            {
                var gpsStatus = true
                var gpsLat = false
                var gpsLon = false
                let strings = str.split(separator: "\n")
                for entry in strings {
                    let key = entry.prefix { $0 != "=" }
                    var value = entry.dropFirst(key.count)
                    if !value.isEmpty {
                        value = value.dropFirst(1)
                    }
                    switch key {
                    case "-CreateDate":
                        // get rid of any trailing parts of a second
                        createDate = String(value.split(separator: ".")[0])
                    case "-GPSStatus":
                        if value.hasSuffix("Void") {
                            gpsStatus = false
                        }
                    case "-GPSLatitude":
                        let parts = value.split(separator: " ")
                        if let latValue = Double(parts[0]),
                            parts.count == 2
                        {
                            location.latitude = latValue
                            if parts[1] == "S" {
                                location.latitude = -location.latitude
                            }
                            gpsLat = true
                        }
                    case "-GPSLongitude":
                        let parts = value.split(separator: " ")
                        if let lonValue = Double(parts[0]),
                            parts.count == 2
                        {
                            location.longitude = lonValue
                            if parts[1] == "W" {
                                location.longitude = -location.longitude
                            }
                            gpsLon = true
                        }
                    case "-GPSAltitude":
                        let parts = value.split(separator: " ")
                        if let eleValue = Double(parts[0]),
                            parts.count == 2
                        {
                            elevation = parts[1] == "1" ? eleValue : -eleValue
                        }

                    default:
                        break
                    }
                }
                // elevation (altitude) is optional
                validGPS = gpsStatus && gpsLat && gpsLon
            }
        }
        return (createDate, validGPS, location, elevation)
    }
    // swiftlint:enable cyclomatic_complexity
    // swiftlint:enable large_tuple

    private func logFrom(pipe: Pipe) {
        let data = pipe.fileHandleForReading.availableData
        if data.count > 0,
            let string = String(data: data, encoding: String.Encoding.utf8)
        {
            Self.logger.warning("stderr: \(string, privacy: .public)")
        }
    }
}
