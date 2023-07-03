//
//  ViewModel.swift
//  GeoTag
//
//  Created by Marco S Hyman on 12/13/22.
//

import SwiftUI
import MapKit
import OSLog

let avmLog = Logger(subsystem: Bundle.main.bundleIdentifier!,
                    category: "AppViewModel")

// maintain state for GeoTag when running.  An instance if this class is
// created as a Statet by GeoTagApp and passed in the environment.

// Observable currently requires all items to be initialized.
// Tell swiftlint to be quiet about setting optionals to nil
// swiftlint:disable redundant_optional_initialization

@Observable
final class AppViewModel {
    var images: [ImageModel] = []
    var selection: Set<ImageModel.ID> = []
    var mostSelected: ImageModel.ID? = nil

    // get/set an image from the table of images  given its ID.
    subscript(id: ImageModel.ID?) -> ImageModel {
        get {
            if let index = images.firstIndex(where: { $0.id == id }) {
                return images[index]
            }

            // A view may hold on to an ID that is no longer in the table
            // If it tries to access the image associated with that id
            // return a fake image
            return ImageModel()
        }

        set(newValue) {
            if let index = images.firstIndex(where: { $0.id == newValue.id }) {
                images[index] = newValue
            }
        }
    }

    // A copy of the current sort order
    var sortOrder = [KeyPathComparator(\ImageModel.name)]

    // A second save can not be triggered while a save is in progress.
    // App termination is denied, too.
    var saveInProgress = false

    // The Apps main window.
    var mainWindow: NSWindow? = nil
    var undoManager = UndoManager()

    // State that changes when a menu item is picked.

    // Tracks displayed on map
    var gpxTracks: [Gpx] = []

    // The timezone to use when matching image timestamps to track logs and
    // setting the GPS time stamp when saving images.  When nil the system
    // time zone is used.
    var timeZone: TimeZone? = nil

    // GPX File Loading sheet information
    var gpxGoodFileNames: [String] = []
    var gpxBadFileNames: [String] = []

    // The URL of the folder where image backups are save when backups
    // are enabled.  The URL comes from a security scoped bookmark in
    // AppStorage.  When changed to a non-nil value the bookmark is updated
    // and the new folder is checked to see if there are old backups that
    // can be removed.
    var backupURL: URL? = nil {
        didSet {
            @AppStorage(AppSettings.saveBookmarkKey) var saveBookmark = Data()

            if let url = backupURL {
                saveBookmark = getBookmark(from: url)
                checkBackupFolder(url)
            }
        }
    }

    // get the backupURL from AppStorage if needed.  This will also trigger
    // a scan of the backup folder for old backups that can be removed.

    init() {
        @AppStorage(AppSettings.doNotBackupKey) var doNotBackup = false

        if !doNotBackup {
            backupURL = getBackupURL()
        }
    }

    // a version for previews that doesn't check for backups as that can not be
    // done from the nonisolated context of a preview.

    nonisolated init(forPreview: Bool) {
        // nothing
    }
}

// convenience init for use with swiftui previews.  Provide a list
// of test images suitable for swiftui previews.

extension AppViewModel {
    convenience init(images: [ImageModel]) {
        self.init(forPreview: true)
        self.images = images
    }
}

// swiftlint:enable redundant_optional_initialization
