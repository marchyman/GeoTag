import AppKit
import Foundation
import ImageData
import OSLog
import UDF

// events that trigger a change of state

enum GeoTagEvent: Equatable {
    case addImage(ImageData)
    case badGpxFile(String)
    case catchUnexpectedError(String?, String?)
    case discardRequest
    case goodGpxFile(String)
    case gpxLoadViewClosed
    case initialBackupCheck
    case mainWindowChange(NSWindow?)
    case openCommand
    case openFiles([URL])
    case quitRequested
    case searchForChanged(String)
    case searchForCleared
    case selectionChanged(Set<ImageData.ID>)
    case sheetDismissed
    case sortOrderChanged([KeyPathComparator<ImageData>])
    case terminateRequest
    case toggleLogWindow
}

// A description for each state

extension GeoTagEvent: CustomStringConvertible {
    var description: String {
        switch self {
        case .addImage: "addImage"
        case .badGpxFile: "badGpxFile"
        case .catchUnexpectedError: "catchUnexpectedError"
        case .discardRequest: "discardRequest"
        case .goodGpxFile: "goodGpxFile"
        case .gpxLoadViewClosed: "gpxLoadViewClosed"
        case .initialBackupCheck: "initialBackupCheck"
        case .mainWindowChange: "mainWindowChange"
        case .openCommand: "openCommand"
        case .openFiles: "openFiles"
        case .quitRequested: "quitRequested"
        case .searchForChanged: "searchForChanged"
        case .searchForCleared: "clearSearchCleared"
        case .selectionChanged: "selectionChanged"
        case .sheetDismissed: "sheetDismissed"
        case .sortOrderChanged: "sortOrderChanged"
        case .terminateRequest: "terminateRequest"
        case .toggleLogWindow: "toggleLogWindow"
        }
    }
}

// Update state changes given an event

struct GeoTagReducer: Reducer, Sendable {
    let logger =
        Logger(subsystem: Bundle.main.bundleIdentifier ?? "GeoTag",
               category: "reducer")

    func reduce(_ state: GeoTagState,
                _ event: GeoTagEvent) -> GeoTagState {
        var newState = state
        newState.version &+= 1
        logger.debug("event: \(event)")

        switch event {
        case let .addImage(imageData):
            newState.imageData.append(imageData)

        case let .badGpxFile(filename):
            newState.gpxBadFileNames.append(filename)

        case let .catchUnexpectedError(error, message):
            newState.addSheet(type: .unexpectedErrorSheet,
                              error: error,
                              message: message)

        case .discardRequest:
            // TODO
            break

        case let .goodGpxFile(filename):
            newState.gpxGoodFileNames.append(filename)

        case .gpxLoadViewClosed:
            newState.gpxGoodFileNames = []
            newState.gpxBadFileNames = []

        case .initialBackupCheck:
            newState.addSheet(type: .noBackupFolderSheet)

        case let .mainWindowChange(window):
            newState.mainWindow = window

        case .openCommand:
            newState.importFiles.toggle()

        case let .openFiles(urls):
            openFiles(&newState, urls: urls)

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

        case .quitRequested:
            quitRequested(&newState)

        case let .searchForChanged(name):
            logger.info("Search for \(name, privacy: .public)")
            newState.searchImages = newState.imageData.filter {
                $0.updatable && $0.name.fuzzy(name)
            }

        case .searchForCleared:
            logger.info("Clearing search")
            newState.searchImages = []

        case let .selectionChanged(selection):
            selectionChanged(&newState, selection: selection)

        case let .sortOrderChanged(comparator):
            newState.imageData.sort(using: comparator)
            newState.searchImages.sort(using: comparator)

        case .terminateRequest:
            newState.isDocumentEdited = false
            NSApp.terminate(nil)

        case .toggleLogWindow:
            newState.showLogWindow.toggle()

        }

        return newState
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
