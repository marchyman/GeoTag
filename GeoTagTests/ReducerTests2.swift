import Coords
import ImageData
import Metadata
import SwiftUI
import Testing
import UDF

@testable import GeoTag

extension ReducerTests {
    @Test func imageSavedEvent() async throws {
        var state = GeoTagState(forPreview: true)
        var id: ImageData.ID!
        for ix in state.imageData.indices
            where state.imageData[ix].original != nil {
            id = state.imageData[ix].id
        }
        try #require(id != nil)
        state[id].metadata.location = Coords(latitude: 37.891,
                                             longitude: -122.345)
        let store = Store(initialState: state, reduce: GeoTagReducer())
        #expect(store[id].metadata != store[id].original)
        store.send(.imageSaved(id, store[id].metadata))
        #expect(store[id].metadata == store[id].original)
    }

    @Test func initBackupURLEvent() async throws {
        @AppStorage(GeoTagApp.savedBookmarkKey) var savedBookmark = Data()
        savedBookmark = Data()
        let store = Store(initialState: GeoTagState(), reduce: GeoTagReducer())
        store.send(.initBackupURL)
        #expect(store.backupURL == nil)

        let fm = FileManager.default
        let backupURL =
            URL.temporaryDirectory.appending(components: UUID().uuidString,
                                             directoryHint: .isDirectory)
        try fm.createDirectory(at: backupURL,
                               withIntermediateDirectories: true)
        defer {
            try? fm.removeItem(at: backupURL)
        }
        savedBookmark = try backupURL.bookmarkData(options: .withSecurityScope)
        store.send(.initBackupURL)
        #expect(store.backupURL == backupURL)
    }

    @Test func noBackupNoticeEvent() async throws {
        let store = Store(initialState: GeoTagState(), reduce: GeoTagReducer())
        store.send(.noBackupNotice)
        #expect(store.sheetType == .noBackupFolderSheet)
        #expect(store.sheetError == nil)
        #expect(store.sheetMessage == nil)
    }

    @Test func initPlacesEvent() async throws {
        let store = Store(initialState: GeoTagState(), reduce: GeoTagReducer())
        let noPlaces: [Place] = []
        store.send(.initPlaces(noPlaces))
        #expect(store.places.isEmpty)
        store.send(.initPlaces([testPlace()]))
        #expect(store.places.count == 1)
        let storePlace = store.places[0]
        let testPlace = testPlace()
        #expect(storePlace.name == testPlace.name)
        #expect(storePlace.city == testPlace.city)
        #expect(storePlace.state == testPlace.state)
        #expect(storePlace.country == testPlace.country)
        #expect(storePlace.countryCode == testPlace.countryCode)
        #expect(storePlace.coordinate == testPlace.coordinate)
    }

    @Test(arguments: [true, false])
    func linkPairedImagesEvent(arg: Bool) async throws {
        var state = GeoTagState()

        let dng = try #require(Bundle.main.url(forResource: "L1000051",
                                               withExtension: "DNG"))
        var dngItem = ImageData(from: dng)
        dngItem.original = Metadata(copying: dngItem.metadata)
        state.imageData.append(dngItem)

        let jpg = try #require(Bundle.main.url(forResource: "L1000051",
                                               withExtension: "JPG"))
        var jpgItem = ImageData(from: jpg)
        jpgItem.original = Metadata(copying: jpgItem.metadata)
        state.imageData.append(jpgItem)

        let store = Store(initialState: state, reduce: GeoTagReducer())
        store.send(.linkPairedImages(arg))
        #expect(store.imageData[0].pairedID == store.imageData[1].id)
        #expect(store.imageData[1].pairedID == store.imageData[0].id)
        #expect(store.imageData[1].updatable == !arg)
    }

    @Test func locationChangedEvent() async throws {
        var state = GeoTagState(forPreview: true)
        let ids = Set(state.imageData.filter { $0.updatable }
                                     .map { $0.id })
        state.selection = ids
        state.mostSelected = state.selection.first
        let store = Store(initialState: state, reduce: GeoTagReducer())
        let testCoords = Coords(latitude: 1.23, longitude: 4.56)

        store.send(.locationChanged(testCoords))
        for id in ids {
            #expect(store[id].metadata.location == testCoords)
        }
    }

    @Test func locationFromTrackEvent() async throws {
        var state = GeoTagState(forPreview: true)
        let ids = Set(state.imageData.map { $0.id })
        state.selection = ids
        state.mostSelected = state.selection.first
        let store = Store(initialState: state, reduce: GeoTagReducer())
        // use the LocationHelper which preps data and sends
        // the .locationFromTrack event with appropriate data
        let task = LocationHelper.locationFromTrack(store, extendedTime: 120)
        _ = await task.result
        for id in ids where store[id].updatable {
            // Two of the selected files should not have been updated
            if store[id].name == "Screenshot.png" ||
               store[id].name == "P1000686.JPG" {
                #expect(store[id].metadata.location == nil)
            } else {
                #expect(store[id].metadata.location != nil)
            }
        }
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
}
