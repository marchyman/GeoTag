//
//  AppState.swift
//  GeoTag
//
//  Created by Marco S Hyman on 7/9/23.
//

import OSLog
import SwiftUI

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
    var undoManager = UndoManager()

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
    var sheetError: NSError?
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

    // The folder containing backups is scanned at startup and the user
    // is given the option to remove backups older than 7 days.  This info
    // is used in an alert when files that can be deleted are found.

    var oldFiles = [URL]()
    var folderSize = 0
    var deletedSize = 0

    // TableView items go in their own class
    var tvm: TableViewModel = TableViewModel()

    // Tracks displayed on map
    var gpxTracks: [Gpx] = []

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

        if !doNotBackup {
            backupURL = getBackupURL()
        }
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
        let sheetError: NSError?
        let sheetMessage: String?
    }

    func addSheet(type: SheetType, error: NSError? = nil, message: String? = nil) {
        if sheetType == nil {
            sheetType = type
            sheetError = error
            sheetMessage = message
        } else {
            // create a SheetInfo and add it to the stack of pending sheets
            sheetStack.append(SheetInfo(sheetType: type,
                                      sheetError: error,
                                      sheetMessage: message))
        }
    }

    // return true if a sheet of the given type is enqueued

    func hasSheet(type: SheetType) -> Bool {
        if sheetType == type {
            return true
        }
        return sheetStack.contains { $0.sheetType == type }
    }

    func addSheetOnce(type: SheetType, error: NSError? = nil, message: String? = nil) {
        if !hasSheet(type: type) {
            addSheet(type: type, error: error, message: message)
        }
    }
}

extension AppState {
    static var logger = Logger(subsystem: Bundle.main.bundleIdentifier!,
                               category: "AppState")
    private static let signposter = OSSignposter(logger: logger)

    func withInterval<T>(_ desc: StaticString,
                         around task: () throws -> T) rethrows -> T {
        try Self.signposter.withIntervalSignpost(desc) {
            try task()
        }
    }

    func markStart(_ desc: StaticString) -> OSSignpostIntervalState {
        let signpostID = Self.signposter.makeSignpostID()
        let interval = Self.signposter.beginInterval(desc, id: signpostID)
        return interval
    }

    func markEnd(_ desc: StaticString, interval: OSSignpostIntervalState) {
        Self.signposter.endInterval(desc, interval)
    }

}
