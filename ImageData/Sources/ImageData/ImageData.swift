import Coords
import Exiftool
import Foundation
import Metadata
import SwiftUI

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

// various image metadata values are displayed in different colors
// depending upon current state.  The colors used in addition to
// .primary and .secondary are defined here.

extension Color {
    public static let changed = Color(nsColor: .systemGreen)
    public static let mostSelected = Color(nsColor: .systemYellow)
}

// and the code to select the appropriate color for timestamps
// and location fields

extension ImageData {
    public var timestampTextColor: Color {
        if updatable {
            return metadata.dateTimeCreated == original?.dateTimeCreated
                ? .primary
                : .changed
        }
        return .secondary
    }

    public var locationTextColor: Color {
        if updatable {
            return metadata.location == original?.location
                ? .primary
                : .changed
        }
        return .secondary
    }
}
