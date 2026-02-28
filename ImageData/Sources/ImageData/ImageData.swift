import Coords
import Exiftool
import Foundation
import Imagetool
import Metadata
import OSLog
import PhotosUI
import Phototool
import SwiftUI

public struct ImageData: Identifiable, Sendable {
    public let id: Int
    public let name: String
    public var metadata: Metadata
    public var original: Metadata?
    public var pairedID: ImageData.ID?
    public var thumbnail: Image?

    // a copy of the metadata before any changes will only exist if
    // the metadata is updatable. Use it's presence to determine
    // if this instance can be updated.

    public var updatable: Bool {
        original != nil
    }

    // init given a Metadata and a String name.

    public init(metadata: Metadata, name: String) {
        id = ImageData.nextId()
        self.name = name
        self.metadata = metadata
        switch metadata.source {
        case .image(let url):
            if url.pathExtension.lowercased() != xmpExtension &&
               Exiftool.helper.fileTypeIsWritable(for: url) {
                original = Metadata(copying: metadata)
            }
        case .xmp:
            original = Metadata(copying: metadata)
        case .photos(_, let assets):
            if assets != nil {
                original = Metadata(copying: metadata)
            }
        default:
            break
        }
    }

    // init given a URL. A URL to the image or, if present, a sidecar
    // file url will be used to create a Metadata initialized from
    // the data in the image then initialize an ImageData with
    // metadata and name.

    public init(from url: URL) {
        let sidecarURL = url.deletingPathExtension()
            .appendingPathExtension(xmpExtension)
        let hasSidecar = url != sidecarURL &&
            FileManager.default.fileExists(atPath: sidecarURL.path)
        let name = url.lastPathComponent + (hasSidecar ? "*" : "")

        var metadata: Metadata
        if hasSidecar {
            metadata = Imagetool.metadata(from: url, xmp: sidecarURL)
        } else {
            metadata = Imagetool.metadata(from: url)
        }
        self.init(metadata: metadata, name: name)
    }

    // init given a PhotosPickerItem and an asset

    public init(from item: PhotosPickerItem, asset: PHAsset?) {
        let name = Phototool.name(from: asset)
        let metadata = Phototool.metadata(from: item, asset: asset)
        self.init(metadata: metadata, name: name)
    }

    // fake data synthesized to allow lookup of images by an ID
    // that no longer exists.

    public init() {
        let fakeURL = URL(string: "file:///unknown.img")!
        let fakeName = "unknown.img"
        let metadata = Metadata(source: .image(fakeURL))
        self.init(metadata: metadata, name: fakeName)
    }
}

extension ImageData {
    static let id = Bundle.main.bundleIdentifier ?? "ImageData"
    static let logger = Logger(subsystem: id, category: "ImageData")
}

extension ImageData: Equatable {}

extension ImageData: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}


// The full path to the image for display only. A fake path is created
// for images in a Photos library.

extension ImageData {
    public var fullPath: String {
        switch metadata.source {
        case let .image(url):
            return url.path
        case let .xmp(url):
            return url.path
        case .photos:
            return "photos://\(name)"
        case .copy:
            Self.logger.error("Requested fullPath of metadata copy")
            return "unknown"
        }
    }
}
