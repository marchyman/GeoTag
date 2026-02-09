import Coords
import Exiftool
import Foundation
import Metadata

public struct ImageData: Identifiable {
    public let id: Int
    public let name: String
    public var metadata: Metadata
    public var original: Metadata?

    // a copy of the metadata before any changes will only exist if
    // the metadata is updatable. Use it's presence to determine
    // if this instance can be updated.

    public var updatable: Bool {
        original != nil
    }

    public init(metadata: Metadata, name: String) {
        id = ImageData.nextId()
        self.name = name
        self.metadata = metadata
        switch metadata.source {
        case let .image(url):
            if Exiftool.helper.fileTypeIsWritable(for: url) {
                original = Metadata(copying: metadata)
            }
        case .xmp, .photos:
            original = Metadata(copying: metadata)
        default:
            break
        }
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

extension ImageData: Equatable {}

extension ImageData: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
