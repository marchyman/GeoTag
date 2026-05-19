import Foundation
import Metadata
import Photos
import PhotosUI
import SwiftUI
import Testing
@testable import ImageData

let imageURL = URL(string: "file://test/file/name.img")!
let imgSource = MetadataSource.image(imageURL)
let xmpSource = MetadataSource.xmp(imageURL)
let photosSource = MetadataSource.photos(PhotosPickerItem(itemIdentifier: "TestItem"), PHAsset())

struct ImageDataTests {
    @Test(arguments: [
        (Metadata(source: imgSource), "Image Source", false),
        (Metadata(source: xmpSource), "Sidecar Source", true),
        (Metadata(source: photosSource), "Photos Source", true)
    ])
    func initFromMetadata(metadata: Metadata, name: String,
                          updatable: Bool) async throws {
        let imageData = ImageData(metadata: metadata, name: name)
        #expect(imageData.name == name)
        #expect(imageData.updatable == updatable)
    }

    @Test func initFromURL() async throws {
        let url = try #require(
            Bundle.module.url(forResource: "alldata",
                              withExtension: "jpg")
        )
        let imageData = ImageData(from: url)
        #expect(imageData.name == "alldata.jpg")
        #expect(imageData.updatable)
        #expect(imageData.fullPath == url.path)
    }

    @Test func initFromURLWithSidecar() async throws {
        let url = try #require(
            Bundle.module.url(forResource: "262M1559",
                              withExtension: "DNG")
        )
        let imageData = ImageData(from: url)
        #expect(imageData.name == "262M1559.DNG*")
        #expect(imageData.updatable)
        #expect(imageData.fullPath == url.path)
    }

    @Test func initFromPhotos() async throws {
        let imageData = ImageData(from: PhotosPickerItem(itemIdentifier: "TestItem"),
                                  asset: nil)
        #expect(imageData.name == "unknown")
        #expect(!imageData.updatable)
        #expect(imageData.fullPath == "photos://unknown")
    }

    @Test func initFake() async throws {
        let imageData = ImageData()
        #expect(imageData.name == "unknown.img")
        #expect(!imageData.updatable)
    }

    @Test func fullPathCopy() async throws {
        var imageData = ImageData()
        let copy = Metadata(copying: imageData.metadata)
        imageData.metadata = copy
        #expect(imageData.fullPath == "unknown")
    }
}
