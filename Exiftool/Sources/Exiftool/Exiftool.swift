import Coords
import Metadata
import OSLog
import SwiftUI

public struct Exiftool: Sendable {
    // singleton instance of this class
    public static let helper = Exiftool()

    public enum ExiftoolError: Error {
        case runFailed(code: Int)
    }

    // URL of the embedded version of ExifTool
    var url: URL

    let dateFormatter = DateFormatter()

    // Build the url needed to access to the embedded version of ExifTool

    private init() {
        if let exiftoolUrl = Bundle.module.url(
            forResource: "ExifToolCommand",
            withExtension: nil) {
            url = exiftoolUrl.appendingPathComponent("exiftool")
        } else {
            fatalError("The Application Bundle is corrupt.")
        }
    }
}

// Define a logger for the package

extension Exiftool {
    static let logger =
        Logger(subsystem: Bundle.main.bundleIdentifier ?? "ExiftoolTest",
               category: "ExifTool")
}

// Run the embedded exiftool to get its version. Used
// when testing to verify the embedded program can be
// accessed

extension Exiftool {
    public func version() throws -> String? {
        let data = try run(["-ver"])
        if data.count > 0,
            let string = String(data: data, encoding: String.Encoding.utf8) {
            return string
        }
        return nil
    }
}

// known file types as reported by exiftool. These are the types
// that core graphics can read (usually) and exiftool can write.

extension Exiftool {
    // Last updated to match ExifTool version 12.30

    static private let writableTypes: Set = [
        "360", "3G2", "3GP", "AAX", "AI", "ARQ", "ARW", "AVIF", "CR2", "CR3",
        "CRM", "CRW", "CS1", "DCP", "DNG", "DR4", "DVB", "EPS", "ERF", "EXIF",
        "EXV", "F4A/V", "FFF", "FLIF", "GIF", "GPR", "HDP", "HEIC", "HEIF",
        "ICC", "IIQ", "IND", "INSP", "JNG", "JP2", "JPEG", "LRV", "M4A/V",
        "MEF", "MIE", "MNG", "MOS", "MOV", "MP4", "MPO", "MQV", "MRW",
        "NEF", "NRW", "ORF", "ORI", "PBM", "PDF", "PEF", "PGM", "PNG",
        "PPM", "PS", "PSB", "PSD", "QTIF", "RAF", "RAW", "RW2",
        "RWL", "SR2", "SRW", "THM", "TIFF", "VRD", "WDP", "X3F", "XMP"
    ]

    // Return true if the given URL is a known file type.

    public func fileTypeIsWritable(for file: URL) -> Bool {
        let args = [
            "-m", "-q", "-S", "-fast3", "-FileType", file.path
        ]
        do {
            let data = try run(args)
            if data.count > 0,
                let str = String(data: data,
                                 encoding: String.Encoding.utf8) {
                let trimmed = str.trimmingCharacters(
                    in: CharacterSet.whitespacesAndNewlines)
                let strparts = trimmed.components(
                    separatedBy: CharacterSet.whitespaces)
                if let filetype = strparts.last {
                    return Self.writableTypes.contains(filetype)
                }
            }
        } catch {
            Self.logger.error(
                "\(#function): \(error.localizedDescription, privacy: .public)")
        }
        return false
    }
}

// Use exiftool to create a sidecar file from an image file.
// The sidecar file will be in the same location as the image
// file.

extension Exiftool {
    public func makeSidecar(from imageURL: URL) throws {
        let sidecarURL = imageURL.deletingPathExtension()
            .appendingPathExtension(Metadata.xmpExtension)
        let args = [
            "-tagsfromfile", imageURL.path, sidecarURL.path
        ]
        do {
            // ignore any returned output
            try run(args)
        } catch {
            Self.logger.error(
                "\(#function): \(error.localizedDescription, privacy: .public)")
            throw error
        }
    }
}

// use exiftool to read the contents of a sidecar file and extract
// the metadata needed to create and return an Metadata struct.
// Used as Apple's ImageIO functions can not extract metadata from XMP
// sidecar files.

extension Exiftool {

    // swiftlint:disable cyclomatic_complexity
    public func metadata(from xmp: URL?, primaryURL: URL) -> Metadata {
        let url: URL
        var metadata: Metadata
        if let xmp {
            url = xmp
            metadata = Metadata(source: .xmp(primaryURL))
        } else {
            url = primaryURL
            metadata = Metadata(source: .image(primaryURL))
        }
        let args = [
            "-args", "-c", "%.15f", "-createdate",
            "-gpsstatus", "-gpslatitude", "-gpslongitude",
            "-gpsaltitude", "-xmp:city", "-xmp:state",
            "-xmp:country", "-xmp:countrycode", url.path
        ]

        do {
            let data = try run(args)
            if data.count > 0,
                let str = String(data: data,
                                 encoding: String.Encoding.utf8) {
                var gpsStatus = true
                var lat: Double?
                var lon: Double?
                var ele: Double?
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
                        metadata.dateTimeCreated = String(value.split(separator: ".")[0])
                    case "-GPSStatus":
                        if value.hasSuffix("Void") {
                            gpsStatus = false
                        }
                    case "-GPSLatitude":
                        let parts = value.split(separator: " ")
                        if var latValue = Double(parts[0]),
                           parts.count == 2 {
                            if parts[1] == "S" {
                                latValue = -latValue
                            }
                            lat = latValue
                        }
                    case "-GPSLongitude":
                        let parts = value.split(separator: " ")
                        if var lonValue = Double(parts[0]),
                           parts.count == 2 {
                            if parts[1] == "W" {
                                lonValue = -lonValue
                            }
                            lon = lonValue
                        }
                    case "-GPSAltitude":
                        let parts = value.split(separator: " ")
                        if let eleValue = Double(parts[0]),
                           parts.count >= 3 {
                            ele = parts[2] == "Above" ? eleValue : -eleValue
                        }
                    case "-City":
                        metadata.city = String(value)
                    case "-State":
                        metadata.state = String(value)
                    case "-Country":
                        metadata.country = String(value)
                    case "-CountryCode":
                        metadata.countryCode = String(value)
                    default:
                        break
                    }
                }
                if gpsStatus, let lat, let lon {
                    metadata.location =
                        Coords.ifValid(latitude: lat,
                                       longitude: lon)
                    metadata.elevation = ele
                }
            }
        } catch {
            Self.logger.error(
                "\(#function): \(error.localizedDescription, privacy: .public)")
        }
        return metadata
    }
    // swiftlint:enable cyclomatic_complexity
}

extension Exiftool {

    // Use the embedded copy of exiftool to update the geolocation metadata
    // in the file referenced by the given URL

    public func update(image: URL,
                       from metadata: Metadata,
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

        let usingSidecar = image.pathExtension.lowercased() == Metadata.xmpExtension

        // Build ExifTool latitude, longitude, and elevation argument values
        if let location = metadata.location {
            latArg += "\(location.latitude)"
            latRefArg += "\(location.latitude)"
            lonArg += "\(location.longitude)"
            lonRefArg += "\(location.longitude)"
            if let ele = metadata.elevation {
                if ele >= 0 {
                    eleArg += "\(ele)"
                    eleRefArg += "0"
                } else {
                    eleArg += "\(-ele)"
                    eleRefArg += "1"
                }
            }
            cityArg += metadata.city ?? ""
            stateArg += metadata.state ?? ""
            countryArg += metadata.country ?? ""
            countryCodeArg += metadata.countryCode ?? ""
        }

        // build exiftool arguments array
        var args = [
            "-q", "-m", "-overwrite_original_in_place",
            latArg, latRefArg,
            lonArg, lonRefArg,
            eleArg, eleRefArg,
            cityArg, stateArg,
            countryArg, countryCodeArg
        ]

        // add args to update date/time if present
        if let dateTimeCreated = metadata.dateTimeCreated {
            let dtoArg = "-datetimeoriginal=" + dateTimeCreated
            let cdArg = "-createdate=" + dateTimeCreated
            args += [dtoArg, cdArg]
            // and update the file modification date if requested
            @AppStorage(Self.updateFileModificationTimesKey)
            var updateFileModificationTimes = false
            if updateFileModificationTimes {
                let fmd = "-filemodifydate=" + dateTimeCreated
                args += [fmd]
                // note: do not use -filemodifydate<datetimecreated as
                // that will use the current date which might be
                // different than that updated above.
            }
        }

        // user option to update file modify time

        // user option to update GPS timestamp
        @AppStorage(Self.updateGPSTimestampsKey)
        var updateGPSTimestamps = false

        if updateGPSTimestamps,
            let gpsTimestamp = gpsTimestamp(for: metadata.dateTimeCreated,
                                            in: timeZone) {

            // args vary depending upon saving to an image file or a gpx file
            if usingSidecar {
                gpsDTArg += gpsTimestamp
                args += [gpsDTArg]
            } else {
                let dtargs = gpsTimestamp.split(separator: " ")
                gpsDArg += dtargs[0]
                gpsTArg += dtargs[1]
                args += [gpsDArg, gpsTArg]
            }
        }

        args += ["-gpsstatus=", image.path]

        try run(args)
    }

    // convert the dateTimeCreated string to a string with time zone to
    // update GPS timestamp fields.  Return nil if there is
    // no timestamp or formatting failed.

    func gpsTimestamp(for dateTime: String?,
                      in timeZone: TimeZone?) -> String? {
        if let dateTime {
            dateFormatter.dateFormat = Metadata.dateFormat
            dateFormatter.timeZone = timeZone
            if let date = dateFormatter.date(from: dateTime) {
                dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
                return dateFormatter.string(from: date) + "Z"
            }
        }
        return nil
    }
}

// Test support functions. Extract the GPS Timestamp if present
extension Exiftool {
    public func getGPSTimestamp(for url: URL) async throws -> String? {
        var args = [
            "-q", "-m", "-s3", "-GPSDateTime"
        ]
        args += [url.path]
        let data = try run(args)
        if data.count > 0 {
            let string = String(data: data, encoding: String.Encoding.utf8)
            return string
        }
        return nil
    }
}

// Common code to call Exiftool with given arguments
// returns any data read; might be zero sized

extension Exiftool {
    @discardableResult
    func run(_ args: [String]) throws -> Data {
        #if DEBUG
        Self.logger.info("\(args, privacy: .public)")
        #endif
        let exiftool = Process()
        let pipe = Pipe()
        let err = Pipe()
        exiftool.standardOutput = pipe
        exiftool.standardError = err
        exiftool.executableURL = url
        exiftool.arguments = args
        try exiftool.run()
        exiftool.waitUntilExit()
        logFrom(pipe: err)
        let status = Int(exiftool.terminationStatus)
        if exiftool.terminationStatus != 0 {
            throw ExiftoolError.runFailed(code: status)
        }
        return pipe.fileHandleForReading.availableData
    }

    // Write log data from a pipe

    private func logFrom(pipe: Pipe) {
        let data = pipe.fileHandleForReading.availableData
        if data.count > 0,
            let string = String(data: data, encoding: String.Encoding.utf8) {
            Self.logger.warning("stderr: \(string, privacy: .public)")
        }
    }
}

// Exiftool update defaults keys

extension Exiftool {
    public static let updateFileModificationTimesKey = "UpdateFileModificationTimes"
    public static let updateGPSTimestampsKey = "UpdateGPSTimestamps"
}
