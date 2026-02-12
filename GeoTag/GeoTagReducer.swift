import AppKit
import Foundation
import ImageData
import OSLog
import UDF

// Update state given an event

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

        case .backupFolderSizeCheck:
            checkBackupFolderSize(&newState)

        case let .backupURLChanged(backupURL):
            newBackupFolder(&newState, url: backupURL)

        case let .badGpxFile(filename):
            newState.gpxBadFileNames.append(filename)

        case let .catchUnexpectedError(error, message):
            newState.addSheet(type: .unexpectedErrorSheet,
                              error: error,
                              message: message)

        case .changeTimeZone:
            newState.showTimeZoneWindow.toggle()

        case .discardRequest:
            // TODO
            break

        case .finishedAddingTracks:
            newState.addSheet(type: .gpxFileNameSheet)

        case let .goodGpxFile(filename):
            newState.gpxGoodFileNames.append(filename)

        case .gpxLoadViewClosed:
            newState.gpxGoodFileNames = []
            newState.gpxBadFileNames = []

        case .initBackupURL:
            getBackupURL(&newState)

        case .initialBackupNotice:
            newState.addSheet(type: .noBackupFolderSheet)

        case let .mainWindowChange(window):
            newState.mainWindow = window

        case .openCommand:
            newState.importFiles.toggle()

        case let .openFiles(urls):
            openFiles(&newState, urls: urls)

        case .quitRequested:
            quitRequested(&newState)

        case let .readTrackLog(path, tracklog):
            addTrackLog(&newState, path: path, tracklog: tracklog)

        case .removeOldFiles:
            removeFiles(filesToRemove: newState.oldFiles,
                        from: newState.backupURL)
            newState.oldFiles = []

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

        case .showInFinder:
            // TODO
            break

        case .sortUsingCurrentComparator:
            newState.imageData.sort(using: newState.sortOrder)
            newState.searchImages.sort(using: newState.sortOrder)

        case let .sortOrderChanged(comparator):
            newState.sortOrder = comparator
            newState.imageData.sort(using: comparator)
            newState.searchImages.sort(using: comparator)

        case .terminateRequest:
            newState.isDocumentEdited = false
            NSApp.terminate(nil)

        case let .timeZoneChanged(newTimeZone):
            newState.timeZone = newTimeZone

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
