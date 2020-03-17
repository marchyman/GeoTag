//
//  Exiftool.swift
//  GeoTag
//
//  Created by Marco S Hyman on 7/15/16.
//  Copyright 2016-2019 Marco S Hyman
//
// Permission is hereby granted, free of charge, to any person obtaining a copy of
// this software and associated documentation files (the "Software"), to deal in the
// Software without restriction, including without limitation the rights to use,
// copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the
// Software, and to permit persons to whom the Software is furnished to do so,
// subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
// FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
// COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN
// AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
// WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

import Foundation
import AppKit

/// manage GeoTag's use of exiftool

struct Exiftool {

    /// singleton instance of this class
    static let helper = Exiftool()

    // URL of the embedded version of ExifTool
    var url: URL

    // Build the url needed to access to the embedded version of ExifTool
    init() {
        if let exiftoolUrl = Bundle.main.url(forResource: "ExifTool",
                                             withExtension: nil) {
            url = exiftoolUrl.appendingPathComponent("exiftool")
        } else {
            fatalError("The Application Bundle is corrupt.")
        }
    }

    /// Use the embedded copy of exiftool to update the geolocation metadata
    /// in the file containing the passed image
    /// - Parameter imageData: the image to update.  imageData contains the URL
    ///     of the original file plus the assigned location.
    /// - Returns: ExifTool exit status

    func updateLocation(from imageData: ImageData) -> Int32 {

        // ExifTool latitude and longitude exiftool argument names
        var latArg = "-GPSLatitude="
        var lonArg = "-GPSLongitude="
        var latRefArg = "-GPSLatitudeRef="
        var lonRefArg = "-GPSLongitudeRef="

        // ExifTool GSPDateTime arg storage
        var gpsDArg = "-GPSDateStamp="      // for non XMP files
        var gpsTArg = "-GPSTimeStamp="      // for non XMP files
        var gpsDTArg = "-GPSDateTime="      // for XMP files

        // Build ExifTool latitude, longitude argument values
        if let location = imageData.location {
            let lat = location.latitude
            latArg += "\(lat)"
            latRefArg += "\(lat)"
            let lon = location.longitude
            lonArg += "\(lon)"
            lonRefArg += "\(lon)"

            // set GPS date/time stamp for current location if enabled
            if let dto = dtoWithZone(from: imageData),
               Preferences.dateTimeGPS() {
                gpsDArg += "\(dto)"
                gpsTArg += "\(dto)"
                gpsDTArg += "\(dto)"
            }
        }

        // path to image (or XMP) file to update
        var path = imageData.sandboxUrl.path
        if let xmp = imageData.sandboxXmp {
            path = xmp.path
        }

        let exiftool = Process()
        exiftool.standardOutput = FileHandle.nullDevice
        exiftool.standardError = FileHandle.nullDevice
        exiftool.launchPath = url.path
        exiftool.arguments = ["-q",
                              "-m",
                              "-overwrite_original_in_place",
                              latArg, latRefArg,
                              lonArg, lonRefArg]
        if Preferences.dateTimeGPS() {
            if imageData.sandboxXmp == nil {
                exiftool.arguments! += [gpsDArg, gpsTArg]
            } else {
                exiftool.arguments?.append(gpsDTArg)
            }
        }
        // add args to update date/time if changed
        if imageData.dateTime != imageData.originalDateTime {
            let dtoArg = "-DateTimeOriginal=" + imageData.dateTime
            let cdArg = "-CreateDate=" + imageData.dateTime
            exiftool.arguments! += [dtoArg, cdArg]
        }
        exiftool.arguments! += ["-GPSStatus=", path]
//      dump(exiftool.arguments!)
        exiftool.launch()
        exiftool.waitUntilExit()
        return exiftool.terminationStatus
    }

    /// File Type codes for the file types that exiftool can write

    // note: png files are read/writable by exiftool, but macOS can not
    // read the resulting metadata.  Remove it from the table.
    let writableTypes: Set = [
        "3G2", "3GP", "AAX", "AI", "ARQ", "ARW", "CR2", "CR3", "CRM",
        "CRW", "CS1", "DCP", "DNG", "DR4", "DVB", "EPS", "ERF", "EXIF",
        "EXV", "F4A/V", "FFF", "FLIF", "GIF", "GPR", "HDP", "HEIC", "HEIF",
        "ICC", "IIQ", "IND", "JNG", "JP2", "JPEG", "LRV", "M4A/V", "MEF",
        "MIE", "MNG", "MOS", "MOV", "MP4", "MPO", "MQV", "MRW",
        "NEF", "NRW", "ORF", "PBM", "PDF", "PEF", "PGM", // "PNG",
        "PPM", "PS", "PSB", "PSD", "QTIF", "RAF", "RAW", "RW2",
        "RWL", "SR2", "SRW","THM", "TIFF", "VRD", "WDP", "X3F", "XMP" ]

    /// Check if exiftool supports writing to a type of file
    /// - Parameter for: a URL of a file to check
    /// - Returns: true if exiftool can write to the file type of the URL
    func fileTypeIsWritable(for file: URL) -> Bool {
        let exiftool = Process()
        let pipe = Pipe()
        exiftool.standardOutput = pipe
        exiftool.standardError = FileHandle.nullDevice
        exiftool.launchPath = url.path
        exiftool.arguments = [ "-m", "-q", "-S", "-fast3", "-FileType", file.path]
        exiftool.launch()
        exiftool.waitUntilExit()
        if exiftool.terminationStatus == 0 {
            let data = pipe.fileHandleForReading.availableData
            if data.count > 0,
               let str = String(data: data, encoding: String.Encoding.utf8) {
                let trimmed = str.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                let strParts = trimmed.components(separatedBy: CharacterSet.whitespaces)
                if let fileType = strParts.last {
                    return writableTypes.contains(fileType)
                }
            }
        }
        return false
    }
    
    /// return selected metadate from a file
    /// - Parameter xmp: URL of XMP file
    /// - Returns: (dto: String, lat: Double, latRef: String, lon: Double, lonRef: String)
    ///
    /// Apple's ImageIO functions can not extract metadata from XMP sidecar
    /// files.  ExifTool is used for that purpose.
    func metadataFrom(xmp: URL) -> (dto: String, valid: Bool, location: Coord) {
        let exiftool = Process()
        let pipe = Pipe()
        exiftool.standardOutput = pipe
        exiftool.standardError = FileHandle.nullDevice
        exiftool.launchPath = url.path
        exiftool.arguments = [ "-args", "-c", "%.15f", "-createdate",
                               "-gpsstatus", "-gpslatitude", "-gpslongitude",
                               xmp.path ]
        exiftool.launch()
        exiftool.waitUntilExit()

        var createDate = ""
        var location = Coord()
        var validGPS = false

        if exiftool.terminationStatus == 0 {
            let data = pipe.fileHandleForReading.availableData
            if data.count > 0,
               let str = String(data: data, encoding: String.Encoding.utf8) {
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
                            parts.count == 2 {
                            location.latitude = latValue
                            if parts[1] == "S" {
                                location.latitude = -location.latitude
                            }
                            gpsLat = true
                        }
                    case "-GPSLongitude":
                        let parts = value.split(separator: " ")
                        if let lonValue = Double(parts[0]),
                            parts.count == 2 {
                            location.longitude = lonValue
                            if parts[1] == "W" {
                                location.longitude = -location.longitude
                            }
                            gpsLon = true
                        }
                    default:
                        break
                    }
                }
                validGPS = gpsStatus && gpsLat && gpsLon
            }
        }
        return (createDate, validGPS, location)
    }

    /// return image date and time stamp including time zone
    /// - Parameter imageData: image used to obtain date/time
    /// - Returns: optional date/time string with time zone
    ///
    /// Nil is returned if there was no date/time original or we couldn't get the
    /// appropriate time zone from image geolocation data.

    private
    func dtoWithZone(from imageData: ImageData) -> String? {
        if imageData.timeZone != nil,
           let dateValue = imageData.dateValueWithZone {
            let format = DateFormatter()
            format.dateFormat = "yyyy:MM:dd HH:mm:ss xxx"
            return format.string(from: dateValue)
        }
        return nil
    }
}
