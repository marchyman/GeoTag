import AppKit
import Foundation
import OSLog
import UDF

enum GeoTagEvent: Equatable {
    case mainWindowChange(NSWindow?)
    case quitRequested
    case initialBackupCheck
    case sheetDismissed
    case goodGpxFile(String)
    case badGpxFile(String)
    case gpxLoadViewClosed
    case toggleLogWindow
}

extension GeoTagEvent: CustomStringConvertible {
    var description: String {
        switch self {
        case .mainWindowChange: "mainWindowChange"
        case .quitRequested: "quitRequested"
        case .initialBackupCheck: "initialBackupCheck"
        case .sheetDismissed: "sheetDismissed"
        case .gpxLoadViewClosed: "gpxLoadViewClosed"
        case .goodGpxFile: "goodGpxFile"
        case .badGpxFile: "badGpxFile"
        case .toggleLogWindow: "toggleLogWindow"
        }
    }
}

struct GeoTagReducer: Reducer {
    let logger = Logger(subsystem: "org.snafu", category: "reducer")

    func reduce(_ state: GeoTagState,
                _ event: GeoTagEvent) -> GeoTagState {
        var newState = state
        newState.version &+= 1
        logger.info("reduce \(event)")

        switch event {
        case let .mainWindowChange(window):
            newState.mainWindow = window
        case .quitRequested:
            quitRequested(&newState)
        case .initialBackupCheck:
            newState.addSheet(type: .noBackupFolderSheet)
        case .sheetDismissed:
            if newState.sheetStack.isEmpty {
                newState.sheetMessage = nil
                newState.sheetError = nil
            } else {
                let sheetInfo = newState.sheetStack.removeFirst()
                newState.sheetMessage = sheetInfo.sheetMessage
                newState.sheetError = sheetInfo.sheetError
                newState.sheetType = sheetInfo.sheetType
            }
        case let .goodGpxFile(filename):
            newState.gpxGoodFileNames.append(filename)
        case let .badGpxFile(filename):
            newState.gpxBadFileNames.append(filename)
        case .gpxLoadViewClosed:
            newState.gpxGoodFileNames = []
            newState.gpxBadFileNames = []
        case .toggleLogWindow:
            newState.showLogWindow.toggle()
        }

        return newState
    }
}

// Quit (or last window close) requested when there was a save
// in progress or there are unsaved changes.

extension GeoTagReducer {
    func quitRequested(_ state: inout GeoTagState) {
        if state.saveInProgress {
            state.addSheet(type: .savingUpdatesSheet)
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
