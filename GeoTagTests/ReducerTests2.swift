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
        #expect(store.unsavedChanges)
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

    @Test func mainWindowChangeEvent() async throws {
        let store = Store(initialState: GeoTagState(), reduce: GeoTagReducer())
        #expect(store.mainWindow == nil)
        let window = NSWindow()
        store.send(.mainWindowChange(window))
        #expect(store.mainWindow == window)
    }

    @Test func mostSelectedChangedEvent() async throws {
        let store = Store(initialState: GeoTagState(forPreview: true),
                          reduce: GeoTagReducer())
        store.send(.selectAllRequest)
        var selection = store.selection
        let mostSelected = try #require(store.mostSelected)

        // Should be no change
        store.send(.mostSelectedChanged(mostSelected))
        #expect(selection == store.selection)
        #expect(mostSelected == store.mostSelected)

        selection.remove(mostSelected)
        store.send(.selectionChanged(selection))
        #expect(mostSelected != store.mostSelected)
        store.send(.mostSelectedChanged(mostSelected))
        #expect(mostSelected == store.mostSelected)
        #expect(store.selection.contains(mostSelected))

        store.send(.selectionChanged([]))
        store.send(.mostSelectedChanged(mostSelected))
        #expect(mostSelected == store.mostSelected)
        #expect(store.selection.contains(mostSelected))
    }

    @Test func newThumbnailEvent() async throws {
        var state = GeoTagState(forPreview: true)
        let ids = Set(state.imageData.filter { $0.updatable }
                                     .map { $0.id })
        state.selection = ids
        state.mostSelected = state.selection.first
        let store = Store(initialState: state, reduce: GeoTagReducer())
        let id = try #require(store.mostSelected)
        #expect(store[id].thumbnail == nil)
        let thumbnail = await store[id].makeThumbnail(scale: 1.0)
        store.send(.newThumbnail(thumbnail))
        #expect(store[id].thumbnail == thumbnail)
    }

    @Test func newTimestampEvent() async throws {
        var state = GeoTagState(forPreview: true)
        var ids: [ImageData.ID] = []
        for ix in state.imageData.indices {
            if case .image = state.imageData[ix].metadata.source,
               state.imageData[ix].updatable {
                ids.append(state.imageData[ix].id)
            }
        }
        #expect(ids.count > 2)
        let id = ids[0]
        let id2 = ids[1]
        state.selection = Set(ids)
        state.mostSelected = id
        state[id2].metadata.dateTimeCreated = nil
        let store = Store(initialState: state, reduce: GeoTagReducer())
        let oldDate = store[id].metadata.date()
        let adjustment: TimeInterval = 60 * 60
        let newDate = oldDate.addingTimeInterval(adjustment)
        store.send(.newTimestamp(newDate, adjustment))
        #expect(store[id].metadata.date() == newDate)
        #expect(store[id2].metadata.date() == newDate)
        #expect(store.unsavedChanges)
    }

    @Test func openCommandEvent() async throws {
        let store = Store(initialState: GeoTagState(), reduce: GeoTagReducer())
        #expect(!store.importFiles)
        store.send(.openCommand)
        #expect(store.importFiles)
    }

    @Test func openFilesEvent() async throws {
        let store = Store(initialState: GeoTagState(), reduce: GeoTagReducer())
        let urls = store.state.previewURLs()
        store.send(.openFiles(urls))
        let openedURLs = try #require(store.uniqueURLs)
        #expect(openedURLs.count == urls.count)
        #expect(store.sheetType == nil)

        // Try adding them in a store where they are allready loaded
        let loaded = Store(initialState: GeoTagState(forPreview: true),
                           reduce: GeoTagReducer())
        loaded.send(.openFiles(urls))
        #expect(loaded.uniqueURLs == nil)
        #expect(loaded.sheetType == .duplicateImageSheet)
        loaded.send(.sheetDismissed)

        // build a hierarchy of files and open the items by only providing
        // the URL of the top of the hierarchy
        let fm = FileManager.default
        let url =
            URL.temporaryDirectory.appending(components: UUID().uuidString,
                                             directoryHint: .isDirectory)
        try fm.createDirectory(at: url, withIntermediateDirectories: true)
        defer {
            try? fm.removeItem(at: url)
        }
        for ix in 1...3 {
            let name = "dir\(ix)"
            let folder =
                url.appending(components: name, directoryHint: .isDirectory)
            try fm.createDirectory(at: folder, withIntermediateDirectories: true)
            let filename = urls[ix].lastPathComponent
            let copy = folder.appending(component: filename)
            try fm.copyItem(at: urls[ix], to: copy)
        }
        let nextLevel = url.appending(path: "dir1/subdir/")
        try fm.createDirectory(at: nextLevel, withIntermediateDirectories: true)
        for ix in 4...6 {
            let filename = urls[ix].lastPathComponent
            let copy = nextLevel.appending(component: filename)
            try fm.copyItem(at: urls[ix], to: copy)
        }
        loaded.send(.openFiles([url]))
        let filesLoaded = try #require(loaded.uniqueURLs)
        #expect(filesLoaded.count == 6)
        #expect(loaded.sheetType == nil)
    }

    @Test func pasteRequestEvent() async throws {
        let store = Store(initialState: GeoTagState(forPreview: true),
                          reduce: GeoTagReducer())
        store.send(.selectAllRequest)

        let pb = NSPasteboard.general

        // nothing should change when the pasteboard doesn't hold a location
        pb.clearContents()
        pb.setString("not a location", forType: .string)
        store.send(.pasteRequest)
        for id in store.selection where store[id].updatable {
            #expect(store[id].metadata == store[id].original)
        }

        // note: Coords tests validate the various ways coordinates
        // can be formatted. There is no reason to test the same here

        // location without elevation
        pb.clearContents()
        pb.setString("37.890, -122.3456", forType: .string)
        store.send(.pasteRequest)
        for id in store.selection where store[id].updatable {
            #expect(store[id].metadata.location?.latitude == 37.890)
            #expect(store[id].metadata.location?.longitude == -122.3456)
            #expect(store[id].metadata.elevation == nil)
        }

        // location with elevation
        pb.clearContents()
        pb.setString("-37.890, 122.3456, 123.4", forType: .string)
        store.send(.pasteRequest)
        for id in store.selection where store[id].updatable {
            #expect(store[id].metadata.location?.latitude == -37.890)
            #expect(store[id].metadata.location?.longitude == 122.3456)
            #expect(store[id].metadata.elevation == 123.4)
        }
    }
}
