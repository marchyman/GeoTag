// Metadata is the core of GeoTag.  It is the subset of image metadata
// that GeoTag reads, displays, and updates.
//
// Image metadata is sourced from one of the following
// - Image files using core graphics
// - Sidecare files using Exiftool
// - Photos library using the Photos framework
// - A copy of another Metadata
//
// Exiftool is used to update metadata sourced from image and sidecar files.

import Coords
import Foundation

// interesting note: both PhotosUI and SwiftUI must be imported
// or PhotosPickerItem isn't seen

import PhotosUI
import SwiftUI

public enum MetadataSource: Sendable {
    case image(URL)
    case xmp(URL)
    case photos(PhotosPickerItem, PHAsset)
    case copy
}

// Metadata source is Equatable
// Add the special case where it is only desired to compare
// on case without associated values

extension MetadataSource: Equatable {}

// Metadata structure:
// Note: when dateTimeCreated is nil in data passed to Exiftool
// the resulting metadata in the image or xmp file will not be changed.
// There is no way to delete that metadata from an image file.
// It can only be changed to some other value.

public struct Metadata: Identifiable {
    public let id: Int
    public let source: MetadataSource

    public var dateTimeCreated: String?
    public var location: Coords?
    public var elevation: Double?
    public var city: String?
    public var state: String?
    public var country: String?
    public var countryCode: String?

    // Create a new Metadata entry with a unique id. Set the
    // source to the given value but leave the data fields nil

    public init(source: MetadataSource) {
        id = Metadata.nextId()
        self.source = source
    }

    // Create a new Metadata entry with a unique id. Set the
    // source to `.copy` and intialize data fields from `copy`.

    public init(copying copy: Metadata) {
        id = Metadata.nextId()
        source = .copy

        dateTimeCreated = copy.dateTimeCreated
        location = copy.location
        elevation = copy.elevation
        city = copy.city
        state = copy.state
        country = copy.country
        countryCode = copy.countryCode
    }
}

// Metadata date handling

extension Metadata {
    public static let dateFormat = "yyyy:MM:dd HH:mm:ss"

    // Create a timestamp in Metadata date format
    public static func timestamp(from date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = Self.dateFormat
        return dateFormatter.string(from: date)
    }

    // dateTimeCreated as a string, empty when nil
    public var timestamp: String {
        dateTimeCreated ?? ""
    }


    // dateTimeCreated as a date relative to the given timeZone.
    // timeZone defaults to the current time zone.
    public func date(timeZone: TimeZone? = nil) -> Date {
        if let dateTimeCreated {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = Self.dateFormat
            dateFormatter.timeZone = timeZone
            if let date =  dateFormatter.date(from: dateTimeCreated) {
                return date
            }
        }
        return Date.now
    }
}

// Extension use by sidecar files

extension Metadata {
    public static let xmpExtension = "xmp"
}

// Metadata id and source are not included when comparing this type

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
