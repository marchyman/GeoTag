//
// Copyright 2022 Marco S Hyman
// See LICENSE file for info
// https://www.snafu.org/
//

import GpxTrackLog
import MapAndSearchViews
import SwiftUI

@MainActor
@Observable
final class AppState {

    // MARK: Application wide state properties

    var applicationBusy = false
    var inspectorPresented = false
    var isDocumentEdited = false {
        didSet {
            Task { @MainActor in
                self.mainWindow?.isDocumentEdited = isDocumentEdited
            }
        }
    }

    // The Apps main window
    var mainWindow: NSWindow?
    let undoManager = UndoManager()

    // when set the import files dialog will be opened
    var importFiles = false

    // A second save can not be triggered while a save is in progress.
    // App termination is denied, too.
    var saveInProgress = false

    // The timezone to use when matching image timestamps to track logs and
    // setting the GPS time stamp when saving images.  When nil the system
    // time zone is used.
    var timeZone: TimeZone?

    // various actions can cause a sheet to be presented.  A stack of sheets
    // is supported so important notifications are not lost
    var sheetType: SheetType?
    var sheetStack = [SheetInfo]()
    var sheetError: Error?
    var sheetMessage: String?
    var saveIssues = [ImageModel.ID: String]()

    // confirmation required properties
    // A confirmation may required optional data or an action
    var presentConfirmation = false
    var confirmationMessage: String?
    @ObservationIgnored
    var confirmationAction: (@MainActor () -> Void)?

    var removeOldFiles = false
    var changeTimeZoneWindow = false
    var showLogWindow = false

    // The folder containing backups is scanned at startup and the user
    // is given the option to remove backups older than 7 days.  This info
    // is used in an alert when files that can be deleted are found.

    var oldFiles = [URL]()
    var folderSize = 0
    var deletedSize = 0

    // TableView items go in their own class
    var tvm: TableViewModel = TableViewModel()

    // Map and Search View items go in their own class, part of the
    // MapAndSearchViews package

    var masData: MapAndSearchData = MapAndSearchData()

    // Tracks displayed on map
    var gpxTracks: [GpxTrackLog] = []

    // GPX File Loading sheet information
    var gpxGoodFileNames: [String] = []
    var gpxBadFileNames: [String] = []

    // The URL of the folder where image backups are save when backups
    // are enabled.  The URL comes from a security scoped bookmark in
    // AppStorage.  When changed to a non-nil value the bookmark is updated
    // and the new folder is checked to see if there are old backups that
    // can be removed.
    @ObservationIgnored
    var backupURL: URL? {
        didSet {
            @AppStorage(AppSettings.savedBookmarkKey) var savedBookmark = Data()

            if let url = backupURL {
                savedBookmark = getBookmark(from: url)
                checkBackupFolder(url)
            }
        }
    }
    @ObservationIgnored
    var initialBackupURLCheck = false

    // URLs obtained from the open panel are security scoped.  Keep track of
    // them so we can  run stopSecurityScopedResource() when the files/folders
    // are no longer needed
    @ObservationIgnored
    var scopedURLs: [URL] = []

    // MARK: initialization

    // get the backupURL from AppStorage if needed.  This will also trigger
    // a scan of the backup folder for old backups that can be removed.

    init() {
        @AppStorage(AppSettings.doNotBackupKey) var doNotBackup = false
        @AppStorage(AppSettings.savedBookmarkKey) var savedBookmark = Data()

        // blow away settings when user interface testing
        if ProcessInfo.processInfo.environment["UITESTS"] != nil {
            AppSettings.resetSettings()
        }

        // also for UI testing... assign a backup folder
        if let testBackup = ProcessInfo.processInfo.environment["BACKUP"] {
            let testURL = URL(fileURLWithPath: testBackup, isDirectory: true)
            savedBookmark = getBookmark(from: testURL)
        }

        if !doNotBackup {
            backupURL = getBackupURL()
        }
        Self.logger.notice("AppState created")
    }
}

// MARK: Security scoping methods

extension AppState {

    func startSecurityScoping(urls: [URL]) {
        for url in urls where url.startAccessingSecurityScopedResource() {
            scopedURLs.append(url)
        }
    }

    func stopSecurityScoping() {
        for url in scopedURLs {
            url.stopAccessingSecurityScopedResource()
        }
    }
}

// MARK: Sheet related methods

extension AppState {

    struct SheetInfo {
        let sheetType: SheetType
        let sheetError: Error?
        let sheetMessage: String?
    }

    func addSheet(type: SheetType, error: Error? = nil, message: String? = nil) {
        if sheetType == nil {
            sheetType = type
            sheetError = error
            sheetMessage = message
        } else {
            // create a SheetInfo and add it to the stack of pending sheets
            sheetStack.append(
                SheetInfo(
                    sheetType: type,
                    sheetError: error,
                    sheetMessage: message))
        }
    }

    // Add a sheet of a given type only once.
    // [unused]

    // func hasSheet(type: SheetType) -> Bool {
    //     if sheetType == type {
    //         return true
    //     }
    //     return sheetStack.contains { $0.sheetType == type }
    // }

    // func addSheetOnce(type: SheetType, error: NSError? = nil, message: String? = nil) {
    //     if !hasSheet(type: type) {
    //         addSheet(type: type, error: error, message: message)
    //     }
    // }
}
