//
//  Exiftool.swift
//  GeoTag
//
//  Created by Marco S Hyman on 7/15/16.
//  Copyright © 2016 Marco S Hyman. All rights reserved.
//

import Foundation
import AppKit

/// manage GeoTag's use of exiftool
struct Exiftool {
    /// singleton instance of this class
    static let helper = Exiftool()

    // URL of the embedded version of ExifTool
    var url: URL

    // Verify access to the embedded version of ExifTool
    init() {
        if let exiftoolUrl = Bundle.main.url(forResource: "ExifTool", withExtension: nil) {
            url = exiftoolUrl
            print("Exiftool url = \(url)")
        } else {
            fatalError("The Application Bundle is corrupt.")
        }
    }

    func updateLocation(from imageData: ImageData, overwriteOriginal: Bool) {

        // latitude exiftool args
        var latArg = "-GPSLatitude="
        var latRefArg = "-GPSLatitudeRef="
        if var lat = imageData.latitude {
            if lat < 0 {
                latRefArg += "S"
                lat = -lat
            } else {
                latRefArg += "N"
            }
            latArg += "\(lat)"
        }

        // longitude exiftool args
        var lonArg = "-GPSLongitude="
        var lonRefArg = "-GPSLongitudeRef="
        if var lon = imageData.longitude {
            if lon < 0 {
                lonRefArg += "W"
                lon = -lon
            } else {
                lonRefArg += "E"
            }
            lonArg += "\(lon)"
        }

        let exiftool = Process()
        exiftool.standardOutput = FileHandle.nullDevice
        exiftool.standardError = FileHandle.nullDevice
        exiftool.launchPath = url.path
        exiftool.arguments = ["-q", "-m", "-DateTimeOriginal>FileModifyDate",
            latArg, latRefArg, lonArg, lonRefArg, imageData.path]

        // add -overwrite_original option to the exiftool args if we were
        // able to create a backup.
        if overwriteOriginal {
            exiftool.arguments?.insert("-overwrite_original", at: 2)
        }
        exiftool.launch()
        exiftool.waitUntilExit()
        print("Exiftool status \(exiftool.terminationStatus)")
    }
}
