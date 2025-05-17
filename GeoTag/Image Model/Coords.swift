//
// Copyright 2019 Marco S Hyman
// See LICENSE file for info
// https://www.snafu.org/
//

import CoreLocation
import Foundation
import SwiftUI

// MARK: Coords -- another name for CLLocationCoordinate2D

// A shorter name for a type I'll often use
typealias Coords = CLLocationCoordinate2D

// Equatable Coords
// The MapAndSearchViews package now provides this extension
#if false
    extension Coords: @retroactive Equatable {
        static public func == (lhs: Self, rhs: Self) -> Bool {
            return lhs.latitude == rhs.latitude
                && lhs.longitude == rhs.longitude
        }
    }
#endif

// define Coordinate latitude and longitude references

extension Coords {
    static let latRef = ["N", "S"]
    static let lonRef = ["E", "W"]
}

// MARK: Coord output formatting for latitude and longitude

// Add coord formating given a format style
extension Coords {
    func formatted<S: FormatStyle>(_ style: S) -> S.FormatOutput
    where S.FormatInput == Self {
        style.format(self)
    }
}

// latitude format style
struct CoordsLatitudeStyle: FormatStyle {
    func format(_ value: Coords) -> String {
        coordToString(for: value.latitude, ref: Coords.latRef)
    }
}
extension FormatStyle where Self == CoordsLatitudeStyle {
    static var latitude: CoordsLatitudeStyle { .init() }
}

// longitude format style
struct CoordsLongitudeStyle: FormatStyle {
    func format(_ value: Coords) -> String {
        coordToString(for: value.longitude, ref: Coords.lonRef)
    }
}
extension FormatStyle where Self == CoordsLongitudeStyle {
    static var longitude: CoordsLongitudeStyle { .init() }
}

// MARK: Latitude format used with TextFields

struct LatitudeStyle: ParseableFormatStyle {
    var parseStrategy: LatitudeStrategy = .init()

    func format(_ value: Double?) -> String {
        return coordToString(for: value, ref: Coords.latRef)
    }
}

struct LatitudeStrategy: ParseStrategy {
    func parse(_ value: String) throws -> Double? {
        return value.validateLatitude()
    }
}

extension FormatStyle where Self == LatitudeStyle {
    static var latitude: LatitudeStyle { .init() }
}

// MARK: Longitude format used with TextFields

struct LongitudeStyle: ParseableFormatStyle {
    var parseStrategy: LongitudeStrategy = .init()

    func format(_ value: Double?) -> String {
        return coordToString(for: value, ref: Coords.lonRef)
    }
}

struct LongitudeStrategy: ParseStrategy {
    func parse(_ value: String) throws -> Double? {
        return value.validateLongitude()
    }
}

extension FormatStyle where Self == LongitudeStyle {
    static var longitude: LongitudeStyle { .init() }
}

// MARK: convert a coordinate to a string using the desired format

private func coordToString(
    for coord: Double?,
    ref: [String]
) -> String {
    @AppStorage(AppSettings.coordFormatKey) var coordFormat: AppSettings.CoordFormat =
        .deg

    if let coord {
        switch coordFormat {
        case .deg:
            return String(format: "% 2.6f", coord)
        case .degMin:
            return String(
                format: "%d° %.6f' %@",
                Int(abs(coord)),
                coord.minutes,
                coord >= 0 ? ref[0] : ref[1])
        case .degMinSec:
            return String(
                format: "%d° %d' %.2f\" %@",
                Int(abs(coord)),
                Int(abs(coord.minutes)),
                coord.seconds,
                coord >= 0 ? ref[0] : ref[1])
        }
    }
    return ""
}

// extend string to validate and return a latitude/longitude as a double

extension String {

    // Types of error

    enum CoordFormatError: Error {
        case formatError(String)
    }

    // latitude and longitude validation

    func validateLatitude() -> Double? {
        return try? validateCoord(range: 0 ... 90, reference: Coords.latRef)
    }

    func validateLongitude() -> Double? {
        return try? validateCoord(range: 0 ... 180, reference: Coords.lonRef)
    }

    // swiftlint:disable cyclomatic_complexity

    /// Convert a string assumed to contain a coordinate to a double
    /// value representing the coordinate.
    ///
    /// - Parameter range: the allowable range for the number of degrees
    /// - Parameter reference: the allowable reference values
    /// - Returns: the coordinate converted to a double
    ///
    /// Possible inputs
    /// -dd.dddd R              Coordinate in degrees
    /// -dd mm.mmmm R   Coordinate in degrees and minutes
    /// -dd mm ss.ssss R    Coordinate in degrees, minutes, and seconds
    ///
    /// S latitudes and W longitudes can be indicated by a negative number
    /// of degrees or the appropriate reference.  It is an error if both
    /// are used.  Degree (°), Minute ('), and Second (") marks are optional
    /// and ignored if found at the end of a value.

    func validateCoord(range: ClosedRange<UInt>, reference: [String]) throws
        -> Double
    {
        var invert = false
        let maxParts = 3  // maximum numeric parts to a coordinate
        let delims = ["°", "'", "\""]
        var subStrings = self.split(separator: " ")

        // See if the last part of the input string matches one of the
        // given reference values.
        if let ref = subStrings.last?.uppercased() {
            for validRef in reference where validRef.uppercased() == ref {
                if ref == "S" || ref == "W" {
                    invert = true
                }
                subStrings.removeLast()
                break
            }
        }

        // There sould be from 1...maxParts substrings to process
        guard (1 ... maxParts).contains(subStrings.count) else {
            throw CoordFormatError.formatError("Too many substrings")
        }

        var dms = [0.0, 0.0, 0.0]  // degrees, minutes, seconds
        var index = 0
        for str in subStrings {
            var digits: Substring
            if str.hasSuffix(delims[index]) {
                digits = str.dropLast()
            } else {
                digits = str
            }
            if let val = Double(digits) {
                // verify the number of degrees/min/sec is in the allowed range
                if index == 0 {
                    if invert && val < 0 {
                        throw CoordFormatError.formatError("Negative coordinate with reference")
                    }
                    if !range.contains(Int(val).magnitude) {
                        throw CoordFormatError.formatError("Value out of range")
                    }
                } else if !(0 ..< 60).contains(Int(val)) {
                    throw CoordFormatError.formatError("Value out of range")
                }
                dms[index] = val
            } else {
                throw CoordFormatError.formatError("Value out of range")
            }
            index += 1
        }
        var coordinate = dms[0] + (dms[1] / 60) + (dms[2] / 60 / 60)
        if coordinate > Double(range.upperBound) {
            throw CoordFormatError.formatError("Value out of range")
        }
        if invert {
            coordinate = -coordinate
        }
        return coordinate
    }
    // swiftlint:enable cyclomatic_complexity

}

// Coordinate (degree/minutes/seconds) conversions

extension Double {
    // assuming the value is some number of degrees return the fractional
    // part as the number of minutes, truncating the whole number of degrees.
    // dd.ddddd => mm.ddddd
    var minutes: Self {
        return abs((self * 3600).truncatingRemainder(dividingBy: 3600) / 60)
    }

    // assuming the value is some number of degrees return the fractional
    // part as the number of seconds, truncating the whole number of degrees
    // and minutes.  dd.ddddd => ss.ddddd
    var seconds: Self {
        return abs(
            (self * 3600)
                .truncatingRemainder(dividingBy: 3600)
                .truncatingRemainder(dividingBy: 60))
    }
}
