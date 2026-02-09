import AppKit
import ImageData
import OSLog

// GeoTag application state

struct GeoTagState {
    var version = 1
    var imageData: [ImageData] = []

    // individual images are accessed by ID. No setter is defined.
    subscript(id: ImageData.ID?) -> ImageData {
        if let index = imageData.firstIndex(where: { $0.id == id }) {
            return imageData[index]
        }

        // A view may hold on to an ID that is no longer in the table
        // If it tries to access the image associated with that id
        // return a fake image
        return ImageData()
    }

    var applicationBusy = false
    var saveInProgress = false
    var importFiles = false

    var searchImages: [ImageData] = []
    var selection: Set<ImageData.ID> = []
    var mostSelected: ImageData.ID?

    // keep track of security scoped URLs so they may be released when the
    // table of images is cleared.

    var scopedURLs: [URL] = []

    @ObservationIgnored
    var mainWindow: NSWindow?
    var showLogWindow = false

    // confirmation required properties
    // A confirmation may required optional data or an action
    var presentConfirmation = false
    var confirmationMessage: String?
    @ObservationIgnored
    var confirmationEvent: GeoTagEvent?

    // various actions can cause a sheet to be presented.  A stack of sheets
    // is supported so important notifications are not lost
    var sheetType: SheetType?
    var sheetStack: [SheetInfo] = []
    @ObservationIgnored
    var sheetError: String?
    var sheetMessage: String?
    // var saveIssues = [ImageModel.ID: String]()

    // GPX File Loading sheet information
    var gpxGoodFileNames: [String] = []
    var gpxBadFileNames: [String] = []
}

// GeoTagState is only updated in the reducer.  Every pass through
// the reducer the version property is updated. It is sufficient to
// compare versions to determine if two instances are the same.

extension GeoTagState: Equatable {
    static func == (lhs: GeoTagState, rhs: GeoTagState) -> Bool {
        return lhs.version == rhs.version
    }
}

// The window isDocumentEdited flag is used both to inform the user
// that there are unsaved changes and as a flag to track that state
// within the app.

extension GeoTagState {
    @MainActor
    var isDocumentEdited: Bool {
        get {
            mainWindow?.isDocumentEdited ?? false
        }
        set {
            mainWindow?.isDocumentEdited = newValue
        }
    }
}
