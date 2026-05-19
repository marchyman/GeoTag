import Coords
import Foundation
import Photos
import PhotosUI
import SwiftUI

import Testing
@testable import Metadata

let imageURL = URL(string: "file://test/file/name.img")!
let sidecarURL = URL(string: "file://test/file/name.xmp")!

struct MetadataTests {
    func imageMetadata() -> Metadata {
        var metadata = Metadata(source: .image(imageURL))

        // supply test metadata
        metadata.dateTimeCreated = "2025:02:02 11:06:03"
        metadata.location = Coords(latitude: 37.087691,
                                   longitude: -122.088502)
        metadata.elevation = 101.0
        metadata.city = "Ben Lomond"
        metadata.state = "CA"
        metadata.country = "United States"
        metadata.countryCode = "US"

        return metadata
    }

    @Test(arguments: [
        MetadataSource.image(imageURL),
        MetadataSource.xmp(sidecarURL),
        MetadataSource.photos(PhotosPickerItem(itemIdentifier: "TestItem"), PHAsset())
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

    // Convert one metadata to another source type
    @Test func convert() async throws {
        let metadata = imageMetadata()
        let converted = Metadata(converting: metadata,
                                 to: .xmp(imageURL))
        #expect(converted.source == .xmp(imageURL))
        #expect(metadata == converted)
    }

    // Copy an existing Metadata

    @Test func copy() async throws {
        let metadata = imageMetadata()
        let copy = Metadata(copying: metadata)

        #expect(metadata.source == .image(imageURL))
        #expect(copy.source == .copy)

        #expect(metadata == copy)
    }

    @Test func restore() async throws {
        var start = Metadata(source: .image(imageURL))
        let metadata = imageMetadata()
        #expect(start.dateTimeCreated == nil)
        #expect(start.countryCode == nil)
        start.restore(from: metadata)
        #expect(start == metadata)
    }

    @Test func makeXmp() async throws {
        let metadata = imageMetadata()
        let xmpcopy = metadata.xmp()
        #expect(xmpcopy.source == .xmp(imageURL))
        #expect(metadata == xmpcopy)
        // check return self if passsed xmp
        let xmpdata = Metadata(source: .xmp(imageURL))
        let copy = xmpdata.xmp()
        #expect(xmpdata.source == copy.source)
        #expect(xmpdata == copy)
    }

    @Test func location() async throws {
        var metadata = imageMetadata()
        let location1 = try #require(metadata.clLocation(nil))
        #expect(location1.coordinate == metadata.location)
        #expect(location1.altitude == 101.0)
        let location2 = try #require(metadata.clLocation(TimeZone(secondsFromGMT: 0)))
        #expect(location2.timestamp != location1.timestamp)
        metadata.elevation = nil
        let location3 = try #require(metadata.clLocation(nil))
        #expect(location3.altitude == 0)
        metadata.location = nil
        let location4 = metadata.clLocation(nil)
        #expect(location4 == nil)
    }

    @Test(.serialized, arguments: [
        (CoordFormat.deg, " 37.087691", "-122.088502"),
        (CoordFormat.degMin, "37° 5.261460' N", "122° 5.310120' W"),
        (CoordFormat.degMinSec, "37° 5' 15.69\" N", "122° 5' 18.61\" W")
    ])
    func formats(format: CoordFormat, lat: String, lon: String) async throws {
        let metadata = imageMetadata()
        @AppStorage(Coords.coordFormatKey) var coordFormat: CoordFormat = .deg
        coordFormat = format
        #expect(metadata.formattedLatitude == lat)
        #expect(metadata.formattedLongitude == lon)
    }

    @Test func elevationFormat() async throws {
        var metadata = imageMetadata()
        #expect(metadata.formattedElevation == "Elevation:  101.00 meters")
        metadata.elevation = nil
        #expect(metadata.formattedElevation == "Elevation: Unknown")
    }
}
