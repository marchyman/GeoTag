// Struct containing metadata read or written by Exiftool

import Coords
import Foundation

// Note: when dateTimeCreated is nil in data passed to Exiftool
// the resulting metadata in the image filed will not be changed.
// There is no way to delete that metadata from an image file.
// It can only be changed to some other value.

public struct ExifData {
    public var dateTimeCreated: String?
    public var location: Coords?
    public var elevation: Double?
    public var city: String?
    public var state: String?
    public var country: String?
    public var countryCode: String?
}

extension ExifData {
    // Date format used by exiftool
    public static let dateFormat = "yyyy:MM:dd HH:mm:ss"

    // Extension use by sidecar files
    public static let xmpExtension = "xmp"
}

extension ExifData: Equatable {}
