//
//  ViewModel.swift
//  GeoTag
//
//  Created by Marco S Hyman on 12/13/22.
//

import SwiftUI
import MapKit

// maintain state for GeoTag when running.  An instance if this class is
// created as a StateObject by GeoTagApp and passed in the environment.

@MainActor
final class ViewModel: ObservableObject {
    // The Apps main window.
    var mainWindow: NSWindow?
    var undoManager = UndoManager()

    // Let the user know when the app is busy
    @Published var showingProgressView = false

    // Fields used select a sheet to attach to the content view
    // some sheets are associated with errors.  Setting sheetType will
    // trigger display of the sheet
    var sheetStack = [SheetInfo]()
    var sheetError: NSError?
    var sheetMessage: String?
    var saveIssues = [ImageModel.ID : String ]()
    @Published var sheetType: SheetType?

    // Confirmation required
    var confirmationMessage: String?
    var confirmationAction: (@MainActor () -> Void)?
    @Published var presentConfirmation = false

    // Images to edit.
    @Published var images = [ImageModel]()
    @AppStorage(AppSettings.hideInvalidImagesKey) var hideInvalidImages = false

    // A second save can not be triggered while a save is in progress.
    // App termination is denied, too.
    var saveInProgress = false

    // get/set an image from the table of images  given its ID.
    subscript(id: ImageModel.ID?) -> ImageModel {
         get {
             if let id {
                 if let image = images.first(where: { $0.id == id }) {
                     return image
                 }
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

    // Selected Image(s) by ID and the most selected image
    @Published var selection = Set<ImageModel.ID>()
    @Published var mostSelected: ImageModel.ID?
    @Published var onlyMostSelected = true

    // State that changes when a menu item is picked.
    @Published var selectedMenuAction: MenuAction = .none

    // Tracks displayed on map
    var gpxTracks = [Gpx]()

    // The timezone to use when matching image timestamps to track logs and
    // setting the GPS time stamp when saving images.  When nil the system
    // time zone is used.
    var timeZone: TimeZone?

    // GPX File Loading sheet information
    var gpxGoodFileNames = [String]()
    var gpxBadFileNames = [String]()

    // Keep track of the coords for the center of the map
    var mapCenter = Coords()
    var mapAltitude = 50000.0

    // Map Tracks and the containing span of the last track added
    var mapLines = [MKPolyline]()
    var mapSpan: MKCoordinateSpan?
    @Published var refreshTracks = false

    // The URL of the folder where image backups are save when backups
    // are enabled.  The URL comes from a security scoped bookmark in
    // AppStorage.
    @Published var backupURL: URL?

    // The folder containing backups is scanned at startup and the user
    // is given the option to remove backups older than 7 days.
    var oldFiles = [URL]()
    var folderSize = 0
    var deletedSize = 0
    @Published var removeOldFiles = false

    // get the backupURL from AppStorage if needed.  This will also trigger
    // a scan of the backup folder for old backups that can be removed.
    
    init() {
        @AppStorage(AppSettings.doNotBackupKey) var doNotBackup = false

        if !doNotBackup {
            backupURL = getBackupURL()
        }
    }
}

// Add a sheet to display

extension ViewModel {
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
}

// convenience init for use with swiftui previews.  Provide a list
// of test images suitable for swiftui previews.

extension ViewModel {
    convenience init(images: [ImageModel]) {
        self.init()
        self.images = images
    }
}
