import AppKit
import Foundation
import ImageData
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
    case terminateRequest
    case discardRequest
    case searchFor(String)
    case clearSearch
    case sortImages([KeyPathComparator<ImageData>])
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
        case .terminateRequest: "terminateRequest"
        case .discardRequest: "discardRequest"
        case .searchFor: "searchFor"
        case .clearSearch: "clearSearch"
        case .sortImages: "sortImages"
        }
    }
}

struct GeoTagReducer: Reducer {
    let logger =
        Logger(subsystem: Bundle.main.bundleIdentifier ?? "GeoTag",
               category: "reducer")

    func reduce(_ state: GeoTagState,
                _ event: GeoTagEvent) -> GeoTagState {
        var newState = state
        newState.version &+= 1
        logger.debug("event: \(event)")

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
        case .terminateRequest:
            newState.isDocumentEdited = false
            NSApp.terminate(nil)
        case .discardRequest:
            // TODO
            break
        case let .searchFor(name):
            logger.info("Search for \(name, privacy: .public)")
            newState.searchImages = newState.imageData.filter {
                $0.updatable && $0.name.fuzzy(name)
            }
        case .clearSearch:
            logger.info("Clearing search")
            newState.searchImages = []
        case let .sortImages(comparator):
            newState.imageData.sort(using: comparator)
            newState.searchImages.sort(using: comparator)
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
            state.confirmationMessage = """
                If you quit GeoTag before saving changes the changes \
                will be lost.  Are you sure you want to quit?
                """
            state.confirmationEvent = .terminateRequest
            state.presentConfirmation.toggle()
        }
    }
}

// a simple, fast enough search. Return true if the string characters match
// "pattern" characters in the given order ignoring case.

extension String {
    func fuzzy(_ pattern: String) -> Bool {
        // an empty pattern matches anything
        guard !pattern.isEmpty else { return true }
        var remainder = pattern[...]
        for char in self
        where char.lowercased() == remainder[remainder.startIndex].lowercased() {
            remainder.removeFirst()
            if remainder.isEmpty { return true }
        }
        return false
    }
}
