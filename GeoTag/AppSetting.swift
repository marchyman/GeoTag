//
//  Settings.swift
//  GeoTag
//
//  Created by Marco S Hyman on 12/17/22.
//

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
    static let doNotBackupKey = "DoNotBackup"
    static let finderTagKey = "FinderTag"
    static let hideInvalidImagesKey = "HideInvalidImages"
    static let imageTableConfigKey = "ImageTableConfig"
    static let savedBookmarkKey = "SavedBookmark"
    static let splitHContentKey = "SplitHContentPercent"
    static let splitVImageMapKey = "SplitVImageMapPercent"
    static let updateFileModificationTimesKey = "UpdateFileModificationTimes"
    static let updateGPSTimestampsKey = "UpdateGPSTimestamps"

    // reset all settings to their defaults.  Used to set the app to a known
    // state for user interface testing.
    static func resetSettings() {
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: addTagsKey)
        defaults.removeObject(forKey: coordFormatKey)
        defaults.removeObject(forKey: createSidecarFilesKey)
        defaults.removeObject(forKey: disablePairedJpegsKey)
        defaults.removeObject(forKey: doNotBackupKey)
        defaults.removeObject(forKey: finderTagKey)
        defaults.removeObject(forKey: hideInvalidImagesKey)
        defaults.removeObject(forKey: imageTableConfigKey)
        defaults.removeObject(forKey: savedBookmarkKey)
        defaults.removeObject(forKey: splitHContentKey)
        defaults.removeObject(forKey: splitVImageMapKey)
        defaults.removeObject(forKey: updateFileModificationTimesKey)
        defaults.removeObject(forKey: updateGPSTimestampsKey)
    }
}
