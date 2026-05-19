import Coords
import Foundation
import Metadata
import SwiftUI
import Testing
@testable import ImageData

@Suite( "Image Data Color Tests")
struct ImageDataColorTests {
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

        var imageData = ImageData(metadata: metadata, name: "name.img")
        imageData.original = Metadata(copying: metadata)
        return imageData
    }

    @Test func timestampColor() async throws {
        var imageData = imageData()
        #expect(imageData.timestampTextColor == Color.primary)
        imageData.metadata.dateTimeCreated = nil
        #expect(imageData.timestampTextColor == Color.changed)
        imageData.original = nil
        #expect(imageData.timestampTextColor == Color.secondary)
    }

    @Test func locationColor() async throws {
        var imageData = imageData()
        #expect(imageData.locationTextColor == Color.primary)
        imageData.metadata.location = nil
        #expect(imageData.locationTextColor == Color.changed)
        imageData.original = nil
        #expect(imageData.locationTextColor == Color.secondary)
    }
}
