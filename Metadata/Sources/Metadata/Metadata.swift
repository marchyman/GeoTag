// Metadata is the core of GeoTag.  It is the subset of image metadata
// that GeoTag reads, displays, and updates.
//
// Image metadata is sourced from one of the following
// - Image files using core graphics
// - Sidecare files using Exiftool
// - Photos library using the Photos framework
//
// Exiftool is used to update metadata sourced from image and sidecar files.

import Coords
import Foundation

// interesting note: both PhotosUI and SwiftUI must be imported
// or PhotosPickerItem isn't seen

import PhotosUI
import SwiftUI

// Note: when dateTimeCreated is nil in data passed to Exiftool
// the resulting metadata in the image or xmp file will not be changed.
// There is no way to delete that metadata from an image file.
// It can only be changed to some other value.

public enum MetadataSource {
    case image(URL)
    case xmp(URL)
    case photos(PhotosPickerItem, PHAsset)
}

public struct Metadata {
    public let source: MetadataSource

    public var dateTimeCreated: String?
    public var location: Coords?
    public var elevation: Double?
    public var city: String?
    public var state: String?
    public var country: String?
    public var countryCode: String?

    public init(source: MetadataSource) {
        self.source = source
    }
}

extension Metadata {
    // Date format for timestamps
    public static let dateFormat = "yyyy:MM:dd HH:mm:ss"

    // Extension use by sidecar files
    public static let xmpExtension = "xmp"
}

// Metadata source is not included when comparing this type

extension Metadata: Equatable {
    static public func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.dateTimeCreated == rhs.dateTimeCreated
            && lhs.location == rhs.location
            && lhs.elevation == rhs.elevation
            && lhs.city == rhs.city
            && lhs.state == rhs.state
            && lhs.country == rhs.country
            && lhs.countryCode == rhs.countryCode
    }
}
