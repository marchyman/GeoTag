import Coords
import Foundation
import Photos

import Testing
@testable import Metadata

let imageURL = URL(string: "file://test/file/name.img")!
let sidecarURL = URL(string: "file://test/file/name.xmp")!

struct MetadataTests {
    @Test(arguments: [
        MetadataSource.image(imageURL),
        MetadataSource.xmp(sidecarURL),
        MetadataSource.photos(PHAsset())
    ])
    func createFromSource(source: MetadataSource) async throws {
        let metadata = Metadata(source: source)
        #expect(metadata.source == source)
        switch metadata.source {
        case let .image(url):
            #expect(url == imageURL)
        case let .xmp(url):
            #expect(url == sidecarURL)
        case .photos:
            // not sure if there is anything I can test here
            break
        case .copy:
            Issue.record(".copy case not expected in this test")
        }

        #expect(metadata.dateTimeCreated == nil)
        #expect(metadata.location == nil)
        #expect(metadata.elevation == nil)
        #expect(metadata.city == nil)
        #expect(metadata.state == nil)
        #expect(metadata.country == nil)
        #expect(metadata.countryCode == nil)
    }

    // Copy an existing Metadata

    @Test func copy() async throws {
        var metadata = Metadata(source: .image(imageURL))

        // supply test metadata
        metadata.dateTimeCreated = "2025:02:02 11:06:03"
        metadata.location = Coords(latitude: 37.087691,
                                   longitude: -122.088502)
        metadata.elevation = nil
        metadata.city = "Ben Lomond"
        metadata.state = "CA"
        metadata.country = "United States"
        metadata.countryCode = "US"

        let copy = Metadata(copying: metadata)

        #expect(metadata.source == .image(imageURL))
        #expect(copy.source == .copy)

        #expect(metadata.dateTimeCreated == copy.dateTimeCreated)
        #expect(metadata.location == copy.location)
        #expect(metadata.elevation == copy.elevation)
        #expect(metadata.city == copy.city)
        #expect(metadata.state == copy.state)
        #expect(metadata.country == copy.country)
        #expect(metadata.countryCode == copy.countryCode)
    }
}
