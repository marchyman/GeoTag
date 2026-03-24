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
import Photos
import PhotosUI
import SwiftUI

public enum MetadataSource: Equatable, Sendable {
    case image(URL)
    case xmp(URL)
    case photos(PhotosPickerItem, PHAsset?)
    case copy
}

// Metadata structure:
// Note: when dateTimeCreated is nil in data passed to Exiftool
// the resulting metadata in the image or xmp file will not be changed.
// There is no way to delete that metadata from an image file.
// It can only be changed to some other value.

public struct Metadata: Sendable {
    public let source: MetadataSource

    public var readable = true
    public var dateTimeCreated: String?
    public var location: Coords?
    public var elevation: Double?
    public var city: String?
    public var state: String?
    public var country: String?
    public var countryCode: String?

    // Create a new Metadata entry. Set the source to the given
    // value but leave the data fields nil

    public init(source: MetadataSource) {
        self.source = source
    }

    // convert a metadata by creating a new instance with the
    // given source type.

    public init(converting: Metadata, to source: MetadataSource) {
        self.source = source

        dateTimeCreated = converting.dateTimeCreated
        location = converting.location
        elevation = converting.elevation
        city = converting.city
        state = converting.state
        country = converting.country
        countryCode = converting.countryCode
    }

    // Create a new Metadata entry. Set the source to `.copy`
    // and intialize data fields from `copy`.

    public init(copying metadata: Metadata) {
        self.init(converting: metadata, to: .copy)
    }

}

// Update an existing metadata from a copy

extension Metadata {
    public mutating func restore(from copy: Metadata) {
        dateTimeCreated = copy.dateTimeCreated
        location = copy.location
        elevation = copy.elevation
        city = copy.city
        state = copy.state
        country = copy.country
        countryCode = copy.countryCode
    }
}

// Create an xmp metadata from an image metadata

extension Metadata {
    public func xmp() -> Metadata {
        guard case .image(let url) = source else { return self }
        return .init(converting: self, to: .xmp(url))
    }
}

// Create a CLLocation from metadata

extension Metadata {
    public func clLocation(_ timeZone: TimeZone?) -> CLLocation? {
        if let coords = location {
            let altitude: Double
            let verticalAccuracy: Double
            if let elevation = elevation {
                altitude = elevation
                verticalAccuracy = 20 // a number picked out of the air
            } else {
                altitude = 0
                verticalAccuracy = 0
            }
            let timestamp = date(timeZone: timeZone)
            return CLLocation(coordinate: coords,
                              altitude: altitude,
                              horizontalAccuracy: 10,
                              verticalAccuracy: verticalAccuracy,
                              timestamp: timestamp)
        }
        return nil
    }
}

// Metadata location and elevation formatting

extension Metadata {
    public var formattedLatitude: String {
        location?.formatted(.latitude) ?? ""
    }
    public var formattedLongitude: String {
        location?.formatted(.longitude) ?? ""
    }
    public var formattedElevation: String {
        var value = "Elevation: "
        if let elevation {
            value += String(format: "% 4.2f", elevation)
            value += " meters"
        } else {
            value += "Unknown"
        }
        return value
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
