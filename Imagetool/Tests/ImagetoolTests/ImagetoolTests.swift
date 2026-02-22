import Foundation
import Metadata
import Testing
@testable import Imagetool

struct ImagetoolTests {
    @Test func imageSourceCreateFailure() async throws {
        let url = URL(string: "bad url")!
        let metadata = Imagetool.metadata(from: url)
        #expect(metadata.dateTimeCreated == nil)
        #expect(metadata.location == nil)
    }

    // this test used to fail. It looks like Apple can now handle compressed
    // RAW Fuji files.  I'll need to find another file that fails in order
    // to re-enable this test.

    @Test(.disabled()) func imageSourceNoMetadata() async throws {
        let url = try #require(
            Bundle.module.url(forResource: "nometadata",
                              withExtension: "RAF")
        )
        let metadata = Imagetool.metadata(from: url)
        #expect(metadata.dateTimeCreated == nil)
        #expect(metadata.location == nil)
    }

    @Test func imageWithTimestamp() async throws {
        let url = try #require(
            Bundle.module.url(forResource: "nolocation",
                              withExtension: "jpg")
        )
        let metadata = Imagetool.metadata(from: url)
        #expect(metadata.timestamp == "2026:01:23 09:20:11")
        #expect(metadata.location == nil)
        #expect(metadata.city == nil)
    }

    @Test func imageWithLocation() async throws {
        let url = try #require(
            Bundle.module.url(forResource: "location",
                              withExtension: "jpg")
        )
        let metadata = Imagetool.metadata(from: url)
        #expect(metadata.timestamp == "2025:10:12 09:38:23")
        let location = try #require(metadata.location)
        #expect(location.latitude == 37.837316666666666)
        #expect(location.longitude == -122.47303666666667)
        #expect(metadata.elevation == 31.0)
        #expect(metadata.city == nil)
    }

    @Test func imageWithVoidStatus() async throws {
        let url = try #require(
            Bundle.module.url(forResource: "status",
                              withExtension: "DNG")
        )
        let metadata = Imagetool.metadata(from: url)
        #expect(metadata.timestamp == "2016:04:01 15:54:48")
        #expect(metadata.location == nil)
        #expect(metadata.elevation == nil)
        #expect(metadata.city == nil)
    }

    @Test func imageNoElevation() async throws {
        let url = try #require(
            Bundle.module.url(forResource: "noelevation",
                              withExtension: "jpg")
        )
        let metadata = Imagetool.metadata(from: url)
        #expect(metadata.timestamp == "2016:04:24 12:12:47")
        let location = try #require(metadata.location)
        #expect(location.latitude == 21.27491)
        #expect(location.longitude == -157.82393666666667)
        #expect(metadata.elevation == nil)
        #expect(metadata.city == "Honolulu")
        #expect(metadata.state == "HI")
        #expect(metadata.country == "United States")
        #expect(metadata.countryCode == "US")
    }

    @Test func imageAllData() async throws {
        let url = try #require(
            Bundle.module.url(forResource: "alldata",
                              withExtension: "jpg")
        )
        let metadata = Imagetool.metadata(from: url)
        #expect(metadata.timestamp == "2025:12:07 10:00:51")
        let location = try #require(metadata.location)
        #expect(location.latitude == 37.224048333333336)
        #expect(location.longitude == -122.40566666666666)
        #expect(metadata.elevation == 2.0)
        #expect(metadata.city == "Pescadero")
        #expect(metadata.state == "CA")
        #expect(metadata.country == "United States")
        #expect(metadata.countryCode == "US")
    }

    @Test func imageWithXmp() async throws {
        let url = try #require(
            Bundle.module.url(forResource: "262M1559",
                              withExtension: "DNG"))
        let xmp = try #require(
            Bundle.module.url(forResource: "262M1559",
                              withExtension: "xmp"))
        let metadata = Imagetool.metadata(from: url, xmp: xmp)
        #expect(metadata.dateTimeCreated == "2019:03:11 11:47:20")
        #expect(metadata.location == nil)
        #expect(metadata.elevation == nil)
        #expect(metadata.city == nil)
        #expect(metadata.state == nil)
        #expect(metadata.country == nil)
        #expect(metadata.countryCode == nil)
    }
}
