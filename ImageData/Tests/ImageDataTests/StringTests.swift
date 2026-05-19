import Coords
import Foundation
import Metadata
import SwiftUI
import Testing
@testable import ImageData

@Suite( "Image Data String Tests", .serialized)
struct ImageDataStringTests {

    func imageData() -> ImageData {
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

        return ImageData(metadata: metadata, name: "name.img")
    }

    @Test func stringRep() async throws {
        let noData = ImageData()
        #expect(noData.stringRepresentation == "")
    }

    @Test(.serialized, arguments: [
        (CoordFormat.deg, " 37.087691, -122.088502, 101.0"),
        (CoordFormat.degMin, "37° 5.261460' N, 122° 5.310120' W, 101.0"),
        (CoordFormat.degMinSec, "37° 5' 15.69\" N, 122° 5' 18.61\" W, 101.0")
    ])
    func stringRepWithLocation(format: CoordFormat,
                               stringRep: String) async throws {
        let imageData = imageData()
        @AppStorage(Coords.coordFormatKey) var coordFormat: CoordFormat = .deg
        coordFormat = format

        #expect(imageData.stringRepresentation == stringRep)
    }

    @Test(.serialized, arguments: [
        (CoordFormat.deg, " 37.087691, -122.088502"),
        (CoordFormat.degMin, "37° 5.261460' N, 122° 5.310120' W"),
        (CoordFormat.degMinSec, "37° 5' 15.69\" N, 122° 5' 18.61\" W")
    ])
    func stringRepNoElevation(format: CoordFormat,
                              stringRep: String) async throws {
        var imageData = imageData()
        imageData.metadata.elevation = nil
        @AppStorage(Coords.coordFormatKey) var coordFormat: CoordFormat = .deg
        coordFormat = format

        #expect(imageData.stringRepresentation == stringRep)
    }

    @Test(.serialized, arguments: [
        (" 37.087691, -122.088502, 101.0",
            37.087691, -122.088502, 101.0),
        (" 37.087691, -122.088502",
            37.087691, -122.088502, 0.0),
        ("37° 5.261460' N, 122° 5.310120' W, 101.0",
            37.087691, -122.088502, 101.0),
        ("37° 5.261460' N, 122° 5.310120' W",
            37.087691, -122.088502, 0.0),
        ("37° 5' 15.69\" N, 122° 5' 18.61\" W, 101.0",
            37.08769166666667, -122.08850277777778, 101.0),
        ("37° 5' 15.69\" N, 122° 5' 18.61\" W",
            37.08769166666667, -122.08850277777778, 0.0)
    ])
    func stringRepDecode(rep: String, lat: Double, lon: Double,
                         elevation: Double) async throws {
        let (coords, ele) = try #require(ImageData.decodeStringRep(value: rep))
        #expect(coords.latitude == lat)
        #expect(coords.longitude == lon)
        if let ele {
            #expect(ele == elevation)
        } else {
            #expect(elevation == 0)
        }
    }
}
