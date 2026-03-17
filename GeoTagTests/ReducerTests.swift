import ImageData
import SwiftUI
import Testing
import UDF

@testable import GeoTag

@MainActor
struct ReducerTests {
    func testPlace(_ id: Int = 1) -> Place {
        return Place(name: "Test Place \(id)",
                     city: "Test City",
                     state: "Test State",
                     country: "Test Country",
                     countryCode: "Test Country Code",
                     coordinate: Coordinate(latitude: 37.123,
                                            longitude: -123.456))
    }

    @Test func addImageEvent() async throws {
        let store = Store(initialState: GeoTagState(forPreview: true),
                          reduce: GeoTagReducer())
        #expect(!store.imageData.isEmpty)
        let count = store.imageData.count
        store.send(.addImage(ImageData()))
        let expectedCount = count + 1
        #expect(store.imageData.count == expectedCount)
    }

    @Test func addressChangedEvent() async throws {
        let store = Store(initialState: GeoTagState(forPreview: true),
                          reduce: GeoTagReducer())
        #expect(!store.imageData.isEmpty)
        let id = store.imageData[1].id
        let selection: Set<ImageData.ID> = [id]
        let place = testPlace()
        store.send(.addressChanged(selection, place))
        #expect(store[id].metadata.city == place.city)
        #expect(store[id].metadata.state == place.state)
        #expect(store[id].metadata.country == place.country)
        #expect(store[id].metadata.countryCode == place.countryCode)
        // .addressChanged event does not update location/coordinate
    }

    @Test func backupFolderSizeEvent() async throws {
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
        let store = Store(initialState: state, reduce: GeoTagReducer())

        // check with empty folder
        store.send(.backupFolderSizeCheck)
        #expect(store.oldFiles.isEmpty)
        #expect(store.folderSize == 0)
        #expect(store.deletedSize == 0)

        // check with data
        let urls = state.previewURLs()
        print(urls)
        for url in urls {
            let name = url.lastPathComponent
            try fm.copyItem(at: url, to: backupURL.appending(component: name))
        }
        store.send(.backupFolderSizeCheck)
        #expect(store.oldFiles.count == 0)
        #expect(store.folderSize == 226059455)
        #expect(store.deletedSize == 0)

        // no test for old files
    }

    @Test func backupURLChangedEvent() async throws {
        let fm = FileManager.default
        let backupURL =
            URL.temporaryDirectory.appending(components: UUID().uuidString,
                                             directoryHint: .isDirectory)
        try fm.createDirectory(at: backupURL,
                               withIntermediateDirectories: true)
        defer {
            try? fm.removeItem(at: backupURL)
        }
        var state = GeoTagState()
        state.backupURL = nil
        let store = Store(initialState: state, reduce: GeoTagReducer())

        store.send(.backupURLChanged(backupURL))

        #expect(store.backupURL == backupURL)
    }

    @Test func badGpxFileEvent() async throws {
        let badFileName = "/Bad/File/Name"
        var state = GeoTagState()
        state.gpxBadFileNames = []
        let store = Store(initialState: state, reduce: GeoTagReducer())

        store.send(.badGpxFile(badFileName))

        #expect(store.gpxBadFileNames.count == 1)
        #expect(store.gpxBadFileNames[0] == badFileName)
    }

    @Test func catchUnexpectedErrorEvent() async throws {
        let error = "The error string goes here"
        let message = "An optional message to go with the error"
        let store = Store(initialState: GeoTagState(), reduce: GeoTagReducer())

        store.send(.catchUnexpectedError(nil, nil))
        #expect(store.sheetType == .unexpectedErrorSheet)
        #expect(store.sheetError == nil)
        #expect(store.sheetMessage == nil)
        #expect(store.sheetStack.isEmpty)

        store.send(.catchUnexpectedError(nil, message))
        #expect(store.sheetStack.count == 1)
        #expect(store.sheetStack[0].sheetType == .unexpectedErrorSheet)
        #expect(store.sheetStack[0].sheetError == nil)
        #expect(store.sheetStack[0].sheetMessage == message)

        store.send(.catchUnexpectedError(error, message))
        #expect(store.sheetStack.count == 2)
        #expect(store.sheetStack[1].sheetType == .unexpectedErrorSheet)
        #expect(store.sheetStack[1].sheetError == error)
        #expect(store.sheetStack[1].sheetMessage == message)
    }

    @Test func changeTimeZoneEvent() async throws {
        let store = Store(initialState: GeoTagState(), reduce: GeoTagReducer())
        #expect(!store.showTimeZoneWindow)
        store.send(.changeTimeZone)
        #expect(store.showTimeZoneWindow)
    }

    @Test func clearImagesRequestEvent() async throws {
        let store = Store(initialState: GeoTagState(forPreview: true),
                          reduce: GeoTagReducer())
        #expect(!store.imageData.isEmpty)
        store.send(.clearImagesRequest)
        #expect(store.mostSelected == nil)
        #expect(store.selection.isEmpty)
        #expect(store.scopedURLs.isEmpty)
        #expect(store.imageData.isEmpty)
    }

    @Test func clearPlacesEvent() async throws {
        var state = GeoTagState()
        let place = testPlace()
        state.places.append(place)
        let store = Store(initialState: state, reduce: GeoTagReducer())
        store.send(.clearPlaces)
        #expect(store.places.isEmpty)
        // The disk file containing save places is updated in a task
        // give the task time to complete before verifying that the
        // file has been emptied. Fragile.
        try? await Task.sleep(for: .milliseconds(300))
        let savedPlaces = await PlaceSaver.shared.read()
        #expect(savedPlaces.isEmpty)
    }

    @Test func deleteRequestEvent() async throws {
        var state = GeoTagState(forPreview: true)
        state.selection = Set(state.imageData.filter { $0.metadata.location != nil }
                                             .map { $0.id })
        #expect(!state.selection.isEmpty)
        state.mostSelected = state.selection.first

        let store = Store(initialState: state, reduce: GeoTagReducer())
        store.send(.deleteRequest)

        for id in state.selection {
            #expect(store[id].metadata.location == nil)
            #expect(store[id].metadata.city == nil)
            #expect(store[id].metadata.state == nil)
            #expect(store[id].metadata.country == nil)
            #expect(store[id].metadata.countryCode == nil)
            if let pairedID = store[id].pairedID, store[pairedID].updatable {
                #expect(store[pairedID].metadata.location == nil)
                #expect(store[pairedID].metadata.city == nil)
                #expect(store[pairedID].metadata.state == nil)
                #expect(store[pairedID].metadata.country == nil)
                #expect(store[pairedID].metadata.countryCode == nil)
            }
        }
    }

    @Test func discardChangesRequestEvent() async throws {
        var state = GeoTagState(forPreview: true)
        let ids = state.imageData
                       .filter { $0.metadata.location != nil }
                       .map { $0.id }
        for id in ids {
            state[id].metadata.location = nil
        }
        let store = Store(initialState: state, reduce: GeoTagReducer())

        store.send(.discardChangesRequest)
        for id in ids {
            #expect(store[id].metadata.location != nil)
        }
    }

    @Test func discardTracksRequestEvent() async throws {
        let state = GeoTagState(forPreview: true)
        #expect(!state.gpxTracks.isEmpty)
        let store = Store(initialState: state, reduce: GeoTagReducer())

        store.send(.discardTracksRequest)
        #expect(store.gpxTracks.isEmpty)
    }

    @Test func duplicateImagesEvent() async throws {
        let store = Store(initialState: GeoTagState(), reduce: GeoTagReducer())
        store.send(.duplicateImages)
        #expect(store.sheetType == .duplicateImageSheet)
        #expect(store.sheetError == nil)
        #expect(store.sheetMessage == nil)
    }

    @Test func findInMapEvent() async throws {
        let store = Store(initialState: GeoTagState(), reduce: GeoTagReducer())
        store.send(.findInMap(true))
        #expect(store.mapSearchActive)
        store.send(.findInMap(false))
        #expect(!store.mapSearchActive)
    }

    @Test func finishAddingTracksEvent() async throws {
        let store = Store(initialState: GeoTagState(), reduce: GeoTagReducer())
        store.send(.finishedAddingTracks)
        #expect(store.sheetType == .gpxFileNameSheet)
        #expect(store.sheetError == nil)
        #expect(store.sheetMessage == nil)
    }

    @Test func goodGpxFileEvent() async throws {
        let store = Store(initialState: GeoTagState(), reduce: GeoTagReducer())
        let name = "Good/file.gpx"
        store.send(.goodGpxFile(name))
        #expect(store.gpxGoodFileNames.count == 1)
        #expect(store.gpxGoodFileNames[0] == name)
    }

    @Test func gpxLoadViewClosedEvent() async throws {
        var state = GeoTagState()
        state.gpxGoodFileNames.append("Good/File/Name:")
        state.gpxBadFileNames.append("Bad/File/Name:")
        let store = Store(initialState: state, reduce: GeoTagReducer())

        store.send(.gpxLoadViewClosed)
        #expect(store.gpxBadFileNames.isEmpty)
        #expect(store.gpxGoodFileNames.isEmpty)
    }
}
