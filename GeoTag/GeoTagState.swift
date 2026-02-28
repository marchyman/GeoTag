import AppKit
import Coords
import GpxTrackLog
import ImageData
import OSLog
import SwiftUI

// GeoTag application state

struct GeoTagState {
    var version = 1
    var imageData: [ImageData] = []

    // individual images are accessed by ID.
    subscript(id: ImageData.ID?) -> ImageData {
        get {
            if let index = imageData.firstIndex(where: { $0.id == id }) {
                return imageData[index]
            }

            // A view may hold on to an ID that is no longer in the table
            // If it tries to access the image associated with that id
            // return a fake image
            return ImageData()
        }
        set {
            if let index = imageData.firstIndex(where: { $0.id == id }) {
                imageData[index] = newValue
            } else {
                let badId = id ?? -1
                Logger(subsystem: Bundle.main.bundleIdentifier ?? "GeoTag",
                       category: "GeoTagState")
                    .error("no data for id \(badId, privacy: .public)")
            }
        }
    }

    var selection: Set<ImageData.ID> = []
    var mostSelected: ImageData.ID?
    var currentLocation: Coords? {
        if let id = mostSelected {
            return self[id].metadata.location
        }
        return nil
    }
    var sortOrder = [KeyPathComparator(\ImageData.name)]

    @MainActor
    var unsavedChanges = false {
        didSet {
            mainWindow?.isDocumentEdited = unsavedChanges
        }
    }

    // Search exists for items in the Image Table and locations
    // on a map.
    var searchActive = false
    var searchText = ""
    var mapSearchActive = false
    var places: [Place] = []

    // Image import variables
    var importFiles = false
    var uniqueURLs: [URL]?
    var scopedURLs: [URL] = []

    // GPX File Loading information
    var gpxTracks: [GpxTrackLog] = []
    var gpxGoodFileNames: [String] = []
    var gpxBadFileNames: [String] = []

    // image save/update variables
    var saveInProgress = false
    var libraryImages: [ImageData.ID] = []
    var fileImages: [ImageData.ID] = []
    var xmpImages: [ImageData.ID] = []
    var backupURL: URL?

    var mainWindow: NSWindow?
    var showLogWindow = false
    var showTimeZoneWindow = false
    var timeZone = TimeZone.current

    // confirmation required properties
    // A confirmation may required optional data or an action
    var presentConfirmation = false
    var confirmationMessage: String?
    var confirmationEvent: GeoTagEvent?

    // various actions can cause a sheet to be presented.  A stack of sheets
    // is supported so important notifications are not lost
    var sheetType: SheetType?
    var sheetStack: [SheetInfo] = []
    var sheetError: String?
    var sheetMessage: String?
    var saveIssues: [ImageData.ID: String] = [:]

    // The folder containing backups is scanned at startup and when a
    // new backup folder is selected. The user is given the option to remove
    // backups older than 7 days.

    var oldFiles: [URL] = []
    var folderSize = 0
    var deletedSize = 0
}

// GeoTagState is only updated in the reducer.  Every pass through
// the reducer the version property is updated. It is sufficient to
// compare versions to determine if two instances are the same.

extension GeoTagState: Equatable {
    static func == (lhs: GeoTagState, rhs: GeoTagState) -> Bool {
        return lhs.version == rhs.version
    }
}
