import Foundation
import PhotosUI
import SwiftUI

import Testing
@testable import Metadata

let imageURL = URL(string: "file://test/file/name.img")!
let sidecarURL = URL(string: "file://test/file/name.xmp")!

struct MetadataTests {
    @Test(arguments: [
        MetadataSource.image(imageURL),
        MetadataSource.xmp(sidecarURL),
        MetadataSource.photos(PhotosPickerItem(itemIdentifier: "foo"),
                              PHAsset())
    ])
    func createFromSource(source: MetadataSource) async throws {
        let metadata = Metadata(source: source)
        #expect(metadata.id != 0)
        #expect(metadata.source == source)
        switch metadata.source {
        case .image (let url):
            #expect(url == imageURL)
        case .xmp (let url):
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
}

