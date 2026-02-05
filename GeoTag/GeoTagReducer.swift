import AppKit
import Foundation
import OSLog
import UDF

enum GeoTagEvent: Equatable {
    case mainWindowChange(NSWindow?)
    case quitRequested
    case goodGpxFile(String)
    case badGpxFile(String)
    case gpxLoadViewClosed

}

extension GeoTagEvent: CustomStringConvertible {
    var description: String {
        switch self {
        case .mainWindowChange: "mainWindowChange"
        case .quitRequested: "quitRequested"
        case .gpxLoadViewClosed: "gpxLoadViewClosed"
        case .goodGpxFile: "goodGpxFile"
        case .badGpxFile: "badGpxFile"
        }
    }
}

struct GeoTagReducer: Reducer {
    let logger = Logger(subsystem: "org.snafu", category: "reducer")

    func reduce(_ state: GeoTagState,
                _ event: GeoTagEvent) -> GeoTagState {
        var newState = state
        logger.info("reduce \(event)")

        switch event {
        case let .mainWindowChange(window):
            newState.mainWindow = window
        case .quitRequested:
            quitRequested(&newState)
        case let .goodGpxFile(filename):
            newState.gpxGoodFileNames.append(filename)
        case let .badGpxFile(filename):
            newState.gpxBadFileNames.append(filename)
        case .gpxLoadViewClosed:
            newState.gpxGoodFileNames = []
            newState.gpxBadFileNames = []
        }

        return newState
    }
}

// Quit (or last window close) requested when there was a save
// in progress or there are unsaved changes.

extension GeoTagReducer {
    func quitRequested(_ state: inout GeoTagState) {
        if state.saveInProgress {
            // state.addSheet(type: .savingUpdatesSheet)
        }

        if state.isDocumentEdited {
            // state.confirmationMessage = """
            //         If you quit GeoTag before saving changes the changes \
            //         will be lost.  Are you sure you want to quit?
            //         """
            // state.confirmationAction = terminateIgnoringEdits
            // state.presentConfirmation = true
        }
    }
}
