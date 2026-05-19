import Coords
import Foundation
import Testing
import UDF

@testable import GeoTag

@MainActor
struct OpenHelperTests {
    @Test func openHelperTest() async throws {
        let store = Store(initialState: GeoTagState(), reduce: GeoTagReducer())

        var urls = store.state.previewURLs()
        if let trackURL = Bundle.main.url(forResource: "TestTrack",
                                          withExtension: "GPX") {
            urls.append(trackURL)
        }
        await store.send(.openFiles(urls)) {
            if let urls = store.uniqueURLs {
                let task = OpenHelper.open(store, urls: urls,
                                           description: "openhelper test",
                                           spinnerEnabled: nil)
                _ = await task.result
            } else {
                Issue.record("No unique URLs found to open")
            }
        }
        #expect(!store.imageData.isEmpty)
        #expect(!store.gpxTracks.isEmpty)
    }
}
