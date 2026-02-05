import AppKit
import ImageData
import OSLog

// GeoTag application state

struct GeoTagState {
    var imageData: [ImageData] = []
    var saveInProgress = false

    @ObservationIgnored
    var mainWindow: NSWindow?

    // confirmation required properties
    // A confirmation may required optional data or an action
    var presentConfirmation = false
    var confirmationMessage: String?
    @ObservationIgnored
    var confirmationAction: (@MainActor () -> Void)?

    // various actions can cause a sheet to be presented.  A stack of sheets
    // is supported so important notifications are not lost
    var sheetType: SheetType?
    var sheetStack: [SheetInfo] = []
    @ObservationIgnored
    var sheetError: Error?
    var sheetMessage: String?
    // var saveIssues = [ImageModel.ID: String]()

    // GPX File Loading sheet information
    var gpxGoodFileNames: [String] = []
    var gpxBadFileNames: [String] = []
}

// Compare GeoTagState only on items that could effect a View
// In particular ignore any items marked @ObservationIgnored

extension GeoTagState: Equatable {
    static func ==(lhs: GeoTagState, rhs: GeoTagState) -> Bool {
        if lhs.imageData == rhs.imageData,
           lhs.saveInProgress == rhs.saveInProgress,
           lhs.presentConfirmation == rhs.presentConfirmation,
           lhs.confirmationMessage == rhs.confirmationMessage,
           lhs.sheetType == rhs.sheetType,
           lhs.sheetStack == rhs.sheetStack,
           lhs.sheetMessage == rhs.sheetMessage,
           lhs.gpxGoodFileNames == rhs.gpxGoodFileNames,
           lhs.gpxBadFileNames == rhs.gpxBadFileNames {
            return true
        }
        return false
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
