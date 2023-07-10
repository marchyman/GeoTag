//
//  Settings.swift
//  GeoTag
//
//  Created by Marco S Hyman on 12/17/22.
//

import Foundation
import SwiftUI

// enum instead of struct as it is not intended to be instantiated.

enum AppSettings {
    enum CoordFormat: Int {
        case deg
        case degMin
        case degMinSec
    }

    static let addTagsKey = "AddTags"
    static let coordFormatKey = "CoordFormat"
    static let createSidecarFilesKey = "CreateSidecarsFile"
    static let disablePairedJpegsKey = "DisablePairedJpegs"
    static let dividerPositionKey = "DividerPosition"
    static let doNotBackupKey = "DoNotBackup"
    static let finderTagKey = "FinderTag"
    static let hideInvalidImagesKey = "HideInvalidImages"
    static let imageTableConfigKey = "ImageTableConfig"
    static let initialMapAltitudeKey = "InitialMapAltitude"
    static let initialMapLatitudeKey = "InitialMapLatitude"
    static let initialMapLongitudeKey = "InitialMapLongitude"
    static let mapConfigurationKey = "MapConfiguration"
    static let savedBookmarkKey = "SavedBookmark"
    static let trackColorKey = "TrackColor"
    static let trackWidthKey = "TrackWidth"
    static let updateFileModificationTimesKey = "UpdateFileModificationTimes"
    static let updateGPSTimestampsKey = "UpdateGPSTimestamps"
}

// Extend Color to conform to Rawrepresentable.  The raw representation
// is a base64 encoded string.
// This extension allows a Color to be stored in AppStorage

extension Color: RawRepresentable {
    public init?(rawValue: String) {
        guard let data = Data(base64Encoded: rawValue) else {
            self = .blue
            return
        }

        do {
            let color = try NSKeyedUnarchiver
                .unarchivedObject(ofClass: NSColor.self,
                                  from: data) ?? .systemBlue
            self = Color(color)
        } catch {
            self = .blue
        }
    }

    public var rawValue: String {
        do {
            let data = try NSKeyedArchiver
                .archivedData(withRootObject: NSColor(self),
                              requiringSecureCoding: false)
            return data.base64EncodedString()
        } catch {
            return ""
        }
    }
}
