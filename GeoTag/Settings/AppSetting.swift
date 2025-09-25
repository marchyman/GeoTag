//
// Copyright 2022 Marco S Hyman
// See LICENSE file for info
// https://www.snafu.org/
//

import SwiftUI

// enum instead of struct as it is not intended to be instantiated.
// Keys used to access values stored in user defaults

enum AppSettings {
    enum CoordFormat: Int {
        case deg
        case degMin
        case degMinSec
    }

    static let alternateLayoutKey = "AlternateLayout"
    static let addTagsKey = "AddTags"
    static let coordFormatKey = "CoordFormat"
    static let createSidecarFilesKey = "CreateSidecarsFile"
    static let disablePairedJpegsKey = "DisablePairedJpegs"
    static let doNotBackupKey = "DoNotBackup"
    static let extendedTimeKey = "ExtendedTime"
    static let finderTagKey = "FinderTag"
    static let hideInvalidImagesKey = "HideInvalidImages"
    static let imageTableConfigKey = "ImageTableConfig"
    static let savedBookmarkKey = "SavedBookmark"
    static let splitHNormalKey = "SplitHNormalPercent"
    static let splitHAlternateKey = "SplitHAlternatePercent"
    static let splitVNormalKey = "SplitVNormalPercent"
    static let splitVAlternateKey = "SplitVAlternatePercent"
    static let updateFileModificationTimesKey = "UpdateFileModificationTimes"
    static let updateGPSTimestampsKey = "UpdateGPSTimestamps"

    // Remove all user defaults for the app. Used to set the app to a known
    // state when user interface testing.
    static func resetSettings() {
        let domain = Bundle.main.bundleIdentifier!
        UserDefaults.standard.removePersistentDomain(forName: domain)
        UserDefaults.standard.synchronize()
    }
}
