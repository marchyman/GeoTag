import Coords
import MapKit
import OSLog
import SwiftUI

public struct Exiftool: Sendable {
    @AppStorage(Exiftool.updateFileModificationTimesKey)
    var updateFileModificationTimes = false
    @AppStorage(Exiftool.updateGPSTimestampsKey)
    var updateGPSTimestamps = false

    // singleton instance of this class
    public static let helper = Exiftool()

    public enum ExiftoolError: Error {
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

    let dateFormatter = DateFormatter()

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

    // Use the embedded copy of exiftool to update the geolocation metadata
    // in the file containing the passed image

    public func update(image: URL,
                       from exifData: ExifData,
                       timeZone: TimeZone?) async throws {
        // ExifTool argument names
        var latArg = "-GPSLatitude="
        var lonArg = "-GPSLongitude="
        var latRefArg = "-GPSLatitudeRef="
        var lonRefArg = "-GPSLongitudeRef="
        var eleArg = "-GPSaltitude="
        var eleRefArg = "-GPSaltitudeRef="
        var cityArg = "-xmp:city="
        var stateArg = "-xmp:state="
        var countryArg = "-xmp:country="
        var countryCodeArg = "-xmp:countryCode="

        // ExifTool GSPDateTime arg storage
        var gpsDArg = "-GPSDateStamp="  // for non XMP files
        var gpsTArg = "-GPSTimeStamp="  // for non XMP files
        var gpsDTArg = "-GPSDateTime="  // for XMP files

        let usingSidecar = image.pathExtension.lowercased() == ExifData.xmpExtension

        // Build ExifTool latitude, longitude, and elevation argument values
        if let location = exifData.location {
            latArg += "\(location.latitude)"
            latRefArg += "\(location.latitude)"
            lonArg += "\(location.longitude)"
            lonRefArg += "\(location.longitude)"
            if let ele = exifData.elevation {
                if ele >= 0 {
                    eleArg += "\(ele)"
                    eleRefArg += "0"
                } else {
                    eleArg += "\(-ele)"
                    eleRefArg += "1"
                }
            }
            cityArg += exifData.city ?? ""
            stateArg += exifData.state ?? ""
            countryArg += exifData.country ?? ""
            countryCodeArg += exifData.countryCode ?? ""
        }

        // path to image (or XMP) file to update.
        let path = image.path
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
            let gpsTimestamp = gpsTimestamp(for: exifData.dateTimeCreated,
                                            in: timeZone)
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

        // add args to update date/time if present
        if let dateTimeCreated = exifData.dateTimeCreated {
            let dtoArg =
                "-DateTimeOriginal=" + dateTimeCreated
            let cdArg = "-CreateDate=" + dateTimeCreated
            exiftool.arguments! += [dtoArg, cdArg]
        }
        exiftool.arguments! += ["-GPSStatus=", path]
        Self.logger.info("\(exiftool.arguments!, privacy: .public)")
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

    func gpsTimestamp(for dateTime: String?,
                      in timeZone: TimeZone?) -> String? {
        if let dateTime {
            dateFormatter.dateFormat = ExifData.dateFormat
            dateFormatter.timeZone = timeZone
            if let date = dateFormatter.date(from: dateTime) {
                dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
                return dateFormatter.string(from: date) + "Z"
            }
        }
        return nil
    }

    // Check if exiftool supports writing to a type of file
    // - Parameter file: a URL of a file to check
    // - Returns: true if exiftool can write to the file type of the URL

    public func fileTypeIsWritable(for file: URL) -> Bool {
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

    // create a sidecar file from an image file

    public func makeSidecar(from imageURL: URL) {
        let sidecarURL = imageURL.deletingPathExtension()
            .appendingPathExtension(ExifData.xmpExtension)
        let exiftool = Process()
        let err = Pipe()
        exiftool.standardOutput = FileHandle.nullDevice
        exiftool.standardError = err
        exiftool.executableURL = url
        exiftool.arguments = [
            "-tagsfromfile",
            imageURL.path,
            sidecarURL.path
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
    // - Returns: ExifData structure containing the data read
    //
    // Apple's ImageIO functions can not extract metadata from XMP sidecar
    // files.  ExifTool is used for that purpose. XmpMetadata contains the
    // data that may be returned from the file.

    // swiftlint:disable cyclomatic_complexity
    public func metadataFrom(xmp: URL) -> ExifData {
        let exiftool = Process()
        let pipe = Pipe()
        let err = Pipe()
        exiftool.standardOutput = pipe
        exiftool.standardError = err
        exiftool.executableURL = url
        exiftool.arguments = [
            "-args", "-c", "%.15f", "-createdate",
            "-gpsstatus", "-gpslatitude", "-gpslongitude",
            "-gpsaltitude", "-xmp:city", "-xmp:state",
            "-xmp:country", "-xmp:countryCode", xmp.path
        ]
        do {
            try exiftool.run()
        } catch {
            Self.logger.error(
                "metadataFrom: \(error.localizedDescription, privacy: .public)")
        }
        exiftool.waitUntilExit()
        logFrom(pipe: err)

        var exifData = ExifData()
        exifData.location = CLLocationCoordinate2D()

        if exiftool.terminationStatus == 0 {
            let data = pipe.fileHandleForReading.availableData
            if data.count > 0,
                let str = String(data: data,
                                 encoding: String.Encoding.utf8) {
                var gpsStatus = true
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
                        exifData.dateTimeCreated = String(value.split(separator: ".")[0])
                    case "-GPSStatus":
                        if value.hasSuffix("Void") {
                            gpsStatus = false
                            exifData.location = nil
                            exifData.elevation = nil
                        }
                    case "-GPSLatitude":
                        let parts = value.split(separator: " ")
                        if var latValue = Double(parts[0]),
                           parts.count == 2, gpsStatus {
                            if parts[1] == "S" {
                                latValue = -latValue
                            }
                            exifData.location?.latitude = latValue
                        }
                    case "-GPSLongitude":
                        let parts = value.split(separator: " ")
                        if var lonValue = Double(parts[0]),
                           parts.count == 2, gpsStatus {
                            if parts[1] == "W" {
                                lonValue = -lonValue
                            }
                            exifData.location?.longitude = lonValue
                        }
                    case "-GPSAltitude":
                        let parts = value.split(separator: " ")
                        if let eleValue = Double(parts[0]),
                           parts.count == 2, gpsStatus {
                            exifData.elevation = parts[1] == "1" ? eleValue : -eleValue
                        }
                    case "-City":
                        exifData.city = String(value)
                    case "-State":
                        exifData.state = String(value)
                    case "-Country":
                        exifData.country = String(value)
                    case "-CountryCode":
                        exifData.countryCode = String(value)
                    default:
                        break
                    }
                }
            }
        }
        return exifData
    }
    // swiftlint:enable cyclomatic_complexity

    private func logFrom(pipe: Pipe) {
        let data = pipe.fileHandleForReading.availableData
        if data.count > 0,
            let string = String(data: data, encoding: String.Encoding.utf8)
        {
            Self.logger.warning("stderr: \(string, privacy: .public)")
        }
    }
}

// Exiftool update defaults keys

extension Exiftool {
    public static let updateFileModificationTimesKey = "UpdateFileModificationTimes"
    public static let updateGPSTimestampsKey = "UpdateGPSTimestamps"
}
