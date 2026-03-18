import AppKit
import Foundation
import ImageData
import Metadata
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

        case .clearImagesRequest:
            clearImages(&newState)

        case .clearPlaces:
            clearPlaces(&newState)

        case .deleteRequest:
            delete(&newState)

        case .discardChangesRequest:
            discardChanges(&newState)

        case .discardTracksRequest:
            newState.gpxTracks.removeAll()

        case .duplicateImages:
            newState.addSheet(type: .duplicateImageSheet)

        case .findInMap(let value):
            newState.mapSearchActive = value

        case .finishedAddingTracks:
            newState.addSheet(type: .gpxFileNameSheet)

        case .goodGpxFile(let filename):
            newState.gpxGoodFileNames.append(filename)

        case .gpxLoadViewClosed:
            newState.gpxGoodFileNames.removeAll()
            newState.gpxBadFileNames.removeAll()

        case .imageSaved(let id, let metadata):
            newState[id].original = Metadata(copying: metadata)

        case .initBackupURL:
            getBackupURL(&newState)

        case .noBackupNotice:
            newState.addSheet(type: .noBackupFolderSheet)

        case .initPlaces(let places):
            newState.places = places

        case .linkPairedImages(let disablePairedJpegs):
            newState.linkPairedImages(disablePairedJpegs)

        case .locationChanged(let coords):
            update(&newState, coords: coords)

        case .locationFromTrack(let updates):
            for entry in updates {
                update(&newState, id: entry.id,
                       location: entry.coords, elevation: entry.elevation)
            }

        case .mainWindowChange(let window):
            newState.mainWindow = window

        case .mostSelectedChanged(let mostSelected):
            mostSelectedChanged(&newState, mostSelected: mostSelected)

        case .newThumbnail(let image):
            if let id = newState.mostSelected {
                newState[id].thumbnail = image
            }

        case .newTimestamp(let date, let adjustment):
                update(&newState, date: date, adjustment: adjustment)

        case .openCommand:
            newState.importFiles.toggle()

        case .openFiles(let urls):
            openFiles(&newState, urls: urls)

        case .pasteRequest:
            paste(&newState)

        case .placeSelection(let place):
            savePlace(&newState, place)

        case .quitRequested:
            quitRequested(&newState)

        case .readTrackLog(let path, let tracklog):
            addTrackLog(&newState, path: path, tracklog: tracklog)

        case .removeOldFiles:
            removeFiles(filesToRemove: newState.oldFiles,
                from: newState.backupURL)
            newState.oldFiles = []

        case .saveComplete(let ok):
            newState.saveInProgress = false
            if ok {
                newState.unsavedChanges = false
            } else {
                newState.addSheet(type: .saveErrorSheet)
            }

        case .saveRequest:
            save(&newState)

        case .searchActiveChanged(let searchActive):
            newState.searchActive = searchActive

        case .searchTextChanged(let text):
            newState.searchText = text

        case .selectAllRequest:
            selectAll(&newState)

        case .selectionChanged(let selection):
            selectionChanged(&newState, selection: selection)

        case .sheetDismissed:
            if newState.sheetStack.isEmpty {
                newState.sheetMessage = nil
                newState.sheetError = nil
                newState.sheetType = nil
            } else {
                let sheetInfo = newState.sheetStack.removeFirst()
                newState.sheetMessage = sheetInfo.sheetMessage
                newState.sheetError = sheetInfo.sheetError
                newState.sheetType = sheetInfo.sheetType
            }

        case .sidecarCreated(let id):
            if case .image = newState[id].metadata.source {
                newState[id].metadata = newState[id].metadata.xmp()
            }

        case .sortOrderChanged(let comparator):
            newState.sortOrder = comparator
            newState.imageData.sort(using: comparator)

        case .sortUsingCurrentComparator:
            newState.imageData.sort(using: newState.sortOrder)

        case .terminateRequest:
            newState.unsavedChanges = false

        case .timeZoneChanged(let newTimeZone):
            newState.timeZone = newTimeZone

        case .toggleLogWindow:
            newState.showLogWindow.toggle()

        }

        // update the window document edited indicator when the
        // unsavedChanges is modified.

        if state.unsavedChanges != newState.unsavedChanges {
            newState.mainWindow?.isDocumentEdited = newState.unsavedChanges
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
