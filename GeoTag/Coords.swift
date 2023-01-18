//
//  Coord.swift
//  GeoTag
//
//  Created by Marco S Hyman on 4/27/19.
//


import Foundation
import MapKit

// A shorter name for a type I'll often use
typealias Coords = CLLocationCoordinate2D

// valid references for latitudes and longitudes
let latRef = ["N", "S"]
let lonRef = ["E", "W"]

// extend string to validate and return a latitude./longitude as a double

extension String {

    // Types of error

    enum CoordFormatError: Error {
        case formatError(String)
    }

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

    func validateCoord(range: ClosedRange<UInt>, reference: [String]) throws -> Double {
        var invert = false
        let maxParts = 3            // maximum numeric parts to a coordinate
        let delims = [ "°", "'", "\""]
        var subStrings = self.split(separator: " ")

        // See if the last part of the input string matches one of the
        // given reference values.
        if let ref = subStrings.last?.uppercased() {
            for c in reference {
                if c.uppercased() == ref {
                    if  ref == "S" || ref == "W" {
                        invert = true
                    }
                    subStrings.removeLast()
                    break
                }
            }
        }

        // There sould be from 1...maxParts substrings to process
        guard (1...maxParts).contains(subStrings.count) else {
            throw CoordFormatError.formatError("Too many substrings")
        }

        var dms = [0.0, 0.0, 0.0]   // degrees, minutes, seconds
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
                    if !range.contains(Int(val).magnitude) {
                        throw CoordFormatError.formatError("Value out of range")
                    }
                } else if !(0..<60).contains(Int(val)) {
                    throw CoordFormatError.formatError("Value out of range")
                }
                dms[index] = val
            } else {
                throw CoordFormatError.formatError("Value out of range")
            }
            index += 1
        }
        var coordinate = dms[0] + (dms[1]/60) + (dms[2]/60/60)
        if invert {
            coordinate = -coordinate
        }
        return coordinate
    }
}

/// extend Double to handle coordinates

extension Double {
    var minutes:  Self {
        return abs((self*3600).truncatingRemainder(dividingBy: 3600) / 60)
    }

    var seconds:  Self {
        return abs((self*3600)
                    .truncatingRemainder(dividingBy: 3600)
                    .truncatingRemainder(dividingBy: 60))
    }

    func dm(_ ref: [String]) -> String {
        String(format: "%d° %.6f' %@",
               Int(abs(self)),
               self.minutes,
               self >= 0 ? ref[0] : ref[1])
    }

    func dms(_ ref: [String]) -> String {
        String(format: "%d° %d' %.2f\" %@",
               Int(abs(self)),
               Int(self.minutes),
               self.seconds,
               self >= 0 ? ref[0] : ref[1])
    }
}

/// extend CLLocationCoordinate2D to conform to Equatable

extension CLLocationCoordinate2D: Equatable {
    static public func ==(lhs: Self, rhs: Self) -> Bool {
        return lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude
    }
}
