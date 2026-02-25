import Coords
import Foundation
import ImageData
import Metadata
import SwiftUI
import UDF

extension GeoTagState {
    init(forPreview: Bool = false) {
        if forPreview {
            loadPreviewData()
        }
    }

    mutating func loadPreviewData() {
        imageData.append(testImage1())
        imageData.append(testImage2())
        imageData.append(testImage3())
        selection = [imageData[0].id]
        mostSelected = imageData[0].id
    }

    private func testImage1() -> ImageData {
        let url = URL(string: "file://test1.jpg")!
        var metadata = Metadata(source: .image(url))
        metadata.location = Coords(latitude: 37.1234, longitude: -121.765)
        metadata.elevation = 182.7
        return ImageData(metadata: metadata, name: "test1.jpg")
    }

    private func testImage2() -> ImageData {
        let url = URL(string: "file://test2.jpg")!
        var metadata = Metadata(source: .image(url))
        metadata.location = Coords(latitude: 37.1234, longitude: -121.765)
        metadata.elevation = 182.7
        metadata.city = "some city"
        metadata.state = "some state"
        metadata.country = "some country"
        metadata.countryCode = "SCC"
        return ImageData(metadata: metadata, name: "test2.jpg")
    }

    private func testImage3() -> ImageData {
        let url = URL(filePath: "TestData/TestPictures/IMG_7158.CR2")
        return ImageData(from: url)
    }
}

struct StoreTrait: PreviewModifier {
    func body(content: Content, context: Void) -> some View {
        content
            .environment(Store(initialState: GeoTagState(forPreview: true),
                               reduce: GeoTagReducer()))
    }
}

extension PreviewTrait where T == Preview.ViewTraits {
    static var store: Self = .modifier(StoreTrait())
}
