import Coords
import ImageData
import Metadata
import SwiftUI
import Testing
import UDF

@testable import GeoTag

extension ReducerTests {
    @Test func placeRequestedEvent() async throws {
        var state = GeoTagState()
        for id in 1..<maxPlaces {
            state.places.append(testPlace(id))
        }
        let store = Store(initialState: state, reduce: GeoTagReducer())

        // add a place
        let place = testPlace(maxPlaces)
        store.send(.placeSelection(place))
        #expect(store.places.contains { $0.name == place.name })
        #expect(store.places.count == maxPlaces)

        // Add a dup, should be ignored
        store.send(.placeSelection(place))
        #expect(store.places.count == maxPlaces)
        #expect(store.places.filter { $0.name == place.name }
                            .count == 1)

        // Add a new entry.  The first entry should have been dropped
        let firstName = store.places.first?.name
        let lastPlace = testPlace(maxPlaces + 1)
        store.send(.placeSelection(lastPlace))
        #expect(store.places.count == maxPlaces)
        #expect(store.places.first?.name != firstName)
        #expect(store.places.last?.name == lastPlace.name)
    }

    @Test func quitRequestedEvent() async throws {
        var state = GeoTagState()
        let storeNormal = Store(initialState: state, reduce: GeoTagReducer())
        storeNormal.send(.quitRequested)
        // nothing happens save the state version being bumped
        #expect(storeNormal.state.version == state.version + 1)

        state.saveInProgress = true
        let storeSaving = Store(initialState: state, reduce: GeoTagReducer())
        storeSaving.send(.quitRequested)
        #expect(storeSaving.sheetType == .savingUpdatesSheet)

        state.saveInProgress = false
        state.unsavedChanges = true
        let storeUnsaved = Store(initialState: state, reduce: GeoTagReducer())
        storeUnsaved.send(.quitRequested)
        #expect(storeUnsaved.confirmationEvent == .terminateRequest)
        #expect(storeUnsaved.confirmationMessage != nil)
        #expect(storeUnsaved.presentConfirmation)
    }

    @Test func readTrackLogEvent() async throws {
        let store = Store(initialState: GeoTagState(), reduce: GeoTagReducer())
        let goodName = "TestTrack.GPX"
        let badName = "BadTrack.GPX"
        let track = store.state.previewTrack()

        store.send(.readTrackLog(goodName, track))
        #expect(!store.gpxTracks.isEmpty)
        #expect(!store.gpxGoodFileNames.isEmpty)
        #expect(store.gpxGoodFileNames.first == goodName)
        #expect(store.gpxBadFileNames.isEmpty)

        store.send(.readTrackLog(badName, nil))
        #expect(!store.gpxBadFileNames.isEmpty)
        #expect(store.gpxBadFileNames.first == badName)
    }

    @Test func removeOldFilesEvent() async throws {
        // create a backup folder
        let fm = FileManager.default
        var state = GeoTagState()
        let backupURL =
            URL.temporaryDirectory.appending(components: UUID().uuidString,
                                             directoryHint: .isDirectory)
        try fm.createDirectory(at: backupURL,
                               withIntermediateDirectories: true)
        defer {
            try? fm.removeItem(at: backupURL)
        }
        state.backupURL = backupURL

        // put some files in the folder and add each to the list
        // of oldfiles
        let urls = state.previewURLs()
        for url in urls {
            let name = url.lastPathComponent
            let oldFileName = backupURL.appending(component: name)
            try fm.copyItem(at: url, to: oldFileName)
            state.oldFiles.append(oldFileName)
        }

        let store = Store(initialState: state, reduce: GeoTagReducer())
        store.send(.removeOldFiles)
        #expect(store.oldFiles.isEmpty)

        // files are removed in a task... wait a bit to give the task
        // a chance to complete before verifying.
        try await Task.sleep(for: .milliseconds(300))
        store.send(.backupFolderSizeCheck)
        #expect(store.oldFiles.isEmpty)
        #expect(store.folderSize == 0)
        #expect(store.deletedSize == 0)
    }

    @Test func saveCompleteEvent() async throws {
        var state = GeoTagState()
        state.saveInProgress = true
        state.unsavedChanges = true
        let store = Store(initialState: state, reduce: GeoTagReducer())

        store.send(.saveComplete(.saveErrorSupressWarning))
        #expect(!store.saveInProgress)
        #expect(store.unsavedChanges)
        #expect(store.sheetType == nil)

        store.send(.saveComplete(.saveError))
        #expect(!store.saveInProgress)
        #expect(store.unsavedChanges)
        #expect(store.sheetType == .saveErrorSheet)

        store.send(.saveComplete(.saveOK))
        #expect(!store.unsavedChanges)
    }

    @Test func saveRequestEvent() async throws {
        let store = Store(initialState: GeoTagState(forPreview: true),
                          reduce: GeoTagReducer())
        store.send(.saveRequest)
        #expect(store.saveInProgress)
        #expect(store.libraryImages.isEmpty)
        #expect(store.fileImages.isEmpty)
        #expect(store.xmpImages.isEmpty)

        store.send(.selectAllRequest)
        store.send(.locationChanged(Coords(latitude: 34.567,
                                           longitude: -122.235)))
        store.send(.saveRequest)
        #expect(store.libraryImages.isEmpty)
        #expect(store.fileImages.count == 13)
        #expect(store.xmpImages.count == 2)
    }

    @Test func searchActiveChangedEvent() async throws {
        let store = Store(initialState: GeoTagState(), reduce: GeoTagReducer())
        store.send(.searchActiveChanged(true))
        #expect(store.searchActive)
        store.send(.searchActiveChanged(false))
        #expect(!store.searchActive)
    }

    @Test func searchTextChangedEvent() async throws {
        let store = Store(initialState: GeoTagState(), reduce: GeoTagReducer())
        let text = "search text"
        store.send(.searchTextChanged(text))
        #expect(store.searchText == text)
    }

    @Test func selectAllRequestEvent() async throws {
        let store = Store(initialState: GeoTagState(), reduce: GeoTagReducer())
        store.send(.selectAllRequest)
        #expect(store.mostSelected == nil)
        #expect(store.selection.isEmpty)

        let state = GeoTagState(forPreview: true)
        let storeImages = Store(initialState: state, reduce: GeoTagReducer())
        storeImages.send(.selectAllRequest)
        #expect(storeImages.mostSelected != nil)
        #expect(storeImages.selection.count == 15)
    }

    @Test func selectionChangedEvent() async throws {
        let store = Store(initialState: GeoTagState(forPreview: true),
                          reduce: GeoTagReducer())
        let proposedSelection = Set(store.imageData.map { $0.id })
        store.send(.selectionChanged(proposedSelection))
        #expect(store.selection != proposedSelection)
        #expect(store.selection.count == 15)
        for id in store.selection {
            #expect(store[id].updatable)
        }
    }

    @Test func sheetDismissedEvent() async throws {
        let store = Store(initialState: GeoTagState(), reduce: GeoTagReducer())
        store.send(.duplicateImages)
        store.send(.finishedAddingTracks)
        #expect(store.sheetType == .duplicateImageSheet)

        store.send(.sheetDismissed)
        #expect(store.sheetType == .gpxFileNameSheet)

        store.send(.sheetDismissed)
        #expect(store.sheetType == nil)
    }

    @Test func sidecarCreatedEvent() async throws {
        let store = Store(initialState: GeoTagState(forPreview: true),
                          reduce: GeoTagReducer())
        var id: ImageData.ID?
        for ix in store.imageData.indices {
            if case .image = store.imageData[ix].metadata.source {
                id = store.imageData[ix].id
                break
            }
        }
        let imageId = try #require(id)
        store.send(.sidecarCreated(imageId))
        if case .xmp = store[imageId].metadata.source {
            return
        }
        Issue.record(".sidecarCreated failed")
    }

    @Test func sortOrderChangedEvent() async throws {
        let store = Store(initialState: GeoTagState(forPreview: true),
                          reduce: GeoTagReducer())

        let nameOrder = [KeyPathComparator(\ImageData.name)]
        let timeOrder = [KeyPathComparator(\ImageData.metadata.timestamp)]

        #expect(store.sortOrder == nameOrder)
        store.send(.sortOrderChanged(timeOrder))
        #expect(store.sortOrder == timeOrder)
        var prevOrder = ""
        for ix in store.imageData.indices {
            #expect(prevOrder <= store.imageData[ix].metadata.timestamp)
            prevOrder = store.imageData[ix].metadata.timestamp
        }
    }

    @Test func sortUsingCurrentComparatorEvent() async throws {
        var state = GeoTagState(forPreview: true)
        state.sortOrder = [KeyPathComparator(\ImageData.metadata.timestamp)]
        let store = Store(initialState: state, reduce: GeoTagReducer())
        store.send(.sortUsingCurrentComparator)

        var prevOrder = ""
        for ix in store.imageData.indices {
            #expect(prevOrder <= store.imageData[ix].metadata.timestamp)
            prevOrder = store.imageData[ix].metadata.timestamp
        }
    }

    @Test func terminateRequestEvent() async throws {
        var state = GeoTagState()
        state.unsavedChanges = true
        let store = Store(initialState: state, reduce: GeoTagReducer())
        store.send(.terminateRequest)
        #expect(!store.unsavedChanges)
    }

    @Test func textfieldFocusChangedEvent() async throws {
        let store = Store(initialState: GeoTagState(), reduce: GeoTagReducer())
        store.send(.textfieldFocusChanged(true))
        #expect(store.textfieldActive)
        store.send(.textfieldFocusChanged(false))
        #expect(!store.textfieldActive)
    }

    @Test func timeZoneChangedEvent() async throws {
        let store = Store(initialState: GeoTagState(), reduce: GeoTagReducer())
        #expect(store.timeZone == TimeZone.current)
        let timeZone = TimeZoneName.plus3.timeZone
        store.send(.timeZoneChanged(timeZone))
        #expect(store.timeZone == timeZone)
    }

    @Test func toggleLogWindowEvent() async throws {
        let store = Store(initialState: GeoTagState(), reduce: GeoTagReducer())
        store.send(.toggleLogWindow)
        #expect(store.showLogWindow)
    }
}
