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

    // swiftlint:disable:next function_body_length
    func reduce(_ state: GeoTagState,
                _ event: GeoTagEvent) -> GeoTagState {
        var newState = state
        newState.version &+= 1
        logger.debug("event: \(event)")

        switch event {
        case .addImage(let imageData):
            newState.imageData.append(imageData)

        case .addressChanged(let selected, let address):
            update(&newState, selected: selected, address: address)

        case .backupFolderSizeCheck:
            checkBackupFolderSize(&newState)

        case .backupURLChanged(let backupURL):
            newBackupFolder(&newState, url: backupURL)

        case .badGpxFile(let filename):
            newState.gpxBadFileNames.append(filename)

        case .catchUnexpectedError(let error, let message):
            newState.addSheet(type: .unexpectedErrorSheet,
                              error: error,
                              message: message)

        case .changeTimeZone:
            newState.showTimeZoneWindow.toggle()

        case .clearPlaces:
            clearPlaces(&newState)

        case .findInMap(let value):
            newState.mapSearchActive = value

        case .finishedAddingTracks:
            newState.addSheet(type: .gpxFileNameSheet)

        case .goodGpxFile(let filename):
            newState.gpxGoodFileNames.append(filename)

        case .gpxLoadViewClosed:
            newState.gpxGoodFileNames.removeAll()
            newState.gpxBadFileNames.removeAll()

        case .initBackupURL:
            getBackupURL(&newState)

        case .initialBackupNotice:
            newState.addSheet(type: .noBackupFolderSheet)

        case .initPlaces(let places):
            newState.places = places

        case .linkPairedImages:
            linkPairedImages(&newState)

        case .locationChanged(let coords):
            update(&newState, coords: coords)

        case .locationFromTrack(let updates):
            for entry in updates {
                update(&newState, id: entry.id,
                       location: entry.coords, elevation: entry.elevation)
            }

        case .mainWindowChange(let window):
            newState.mainWindow = window

        case .newThumbnail(let image):
            if let id = newState.mostSelected {
                newState[id].thumbnail = image
            }

        case .openCommand:
            newState.importFiles.toggle()

        case .openFiles(let urls):
            openFiles(&newState, urls: urls)

        case .quitRequested:
            quitRequested(&newState)

        case .readTrackLog(let path, let tracklog):
            addTrackLog(&newState, path: path, tracklog: tracklog)

        case .removeOldFiles:
            removeFiles(filesToRemove: newState.oldFiles,
                        from: newState.backupURL)
            newState.oldFiles = []

        case .searchActiveChanged(let searchActive):
            newState.searchActive = searchActive

        case .placeSelection(let place):
            savePlace(&newState, place)

        case .searchTextChanged(let text):
            newState.searchText = text

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

        case .selectionChanged(let selection):
            selectionChanged(&newState, selection: selection)

        case .sortUsingCurrentComparator:
            newState.imageData.sort(using: newState.sortOrder)

        case .sortOrderChanged(let comparator):
            newState.sortOrder = comparator
            newState.imageData.sort(using: comparator)

        case .terminateRequest:
            newState.unsavedChanges = false

        case .timeZoneChanged(let newTimeZone):
            newState.timeZone = newTimeZone

        case .toggleLogWindow:
            newState.showLogWindow.toggle()

        // pasteboard events
        case .pasteRequest:
            paste(&newState)

        case .deleteRequest:
            delete(&newState)

        case .selectAllRequest:
            selectAll(&newState)

        // SaveItem events
        case .saveRequest:
            save(&newState)

        case .discardChangesRequest:
            discardChanges(&newState)

        case .discardTracksRequest:
            newState.gpxTracks.removeAll()

        case .clearImagesRequest:
            clearImages(&newState)
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
