import Coords
import Foundation
import Testing
import UDF

@testable import GeoTag

@MainActor
struct SaveHelperTests {
    func copyTestImages(_ state: GeoTagState) throws -> URL {
        let url = URL.documentsDirectory.appending(component: UUID().uuidString,
                                                   directoryHint: .isDirectory)
        let fm = FileManager.default
        try fm.createDirectory(at: url, withIntermediateDirectories: true)
        var images = state.previewURLs()
        // copy the xmp files, too
        if let xmps = Bundle.main.urls(forResourcesWithExtension: "xmp",
                                       subdirectory: nil) {
            images.append(contentsOf: xmps)
        }
        for image in images {
            let dest = url.appending(component: image.lastPathComponent)
            try fm.copyItem(at: image, to: dest)
        }

        return url
    }

    func createBackupFolder(for store: Store<GeoTagState, GeoTagEvent>) throws {
        let fm = FileManager.default
        let backupURL =
            URL.temporaryDirectory.appending(components: UUID().uuidString,
                                             directoryHint: .isDirectory)
        try fm.createDirectory(at: backupURL,
                               withIntermediateDirectories: true)
        store.send(.backupURLChanged(backupURL))
    }

    @Test func saveHelperTest() async throws {
        // create the test store
        let store = Store(initialState: GeoTagState(), reduce: GeoTagReducer())
        let fm = FileManager.default

        // copy images to be updated to a temporary location
        let userFolder = try copyTestImages(store.state)
        defer {
            try? fm.removeItem(at: userFolder)
        }

        // add the images to the store
        await store.send(.openFiles([userFolder]), undoable: false) {
            if let urls = store.uniqueURLs {
                let task = OpenHelper.open(store, urls: urls,
                                           description: "add files",
                                           spinnerEnabled: nil)
                _ = await task.result
            } else {
                Issue.record("No unique URLs found to open")
            }
        }
        #expect(!store.imageData.isEmpty)

        // - create a backup folder
        try createBackupFolder(for: store)
        defer {
            if let url = store.backupURL {
                try? fm.removeItem(at: url)
            }
        }

        // - modify the image metadata
        store.send(.selectAllRequest)
        store.send(.locationChanged(Coords(latitude: 34.567,
                                           longitude: -122.345)))
        #expect(store.unsavedChanges)

        // now invoke the save helper
        await store.send(.saveRequest) {
            let task = SaveHelper.save(store)
            _ = await task.result
        }
        #expect(!store.unsavedChanges)
    }
}
