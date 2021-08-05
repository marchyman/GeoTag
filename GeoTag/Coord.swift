//
//  Coord.swift
//  GeoTag
//
//  Created by Marco S Hyman on 4/27/19.
//  Copyright 2019, 2020 Marco S Hyman
//
// Permission is hereby granted, free of charge, to any person obtaining a copy of
// this software and associated documentation files (the "Software"), to deal in the
// Software without restriction, including without limitation the rights to use,
// copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the
// Software, and to permit persons to whom the Software is furnished to do so,
// subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
// FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
// COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN
// AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
// WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//


import Foundation
import MapKit

/// A shorter name for a type I'll often use
typealias Coord = CLLocationCoordinate2D

/// extend string to validate and return a latitude./longitude as a double

extension String {
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

    func validateLocation(range: ClosedRange<UInt>,
                        reference: [String]) -> Double? {
        var coordinate: Double? = nil
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

        guard (1...maxParts).contains(subStrings.count) else { return nil }

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
                        return nil
                    }
                } else if !(0..<60).contains(Int(val)) {
                    return nil
                }
                dms[index] = val
            } else {
                return nil
            }
            index += 1
        }
        coordinate = dms[0] + (dms[1]/60) + (dms[2]/60/60)
        if invert {
            coordinate = -coordinate!
        }
        return coordinate
    }


}

/// extend floating point to return convert the fractional part as
/// minutes or seconds. The absolute value of the result is returned

extension FloatingPoint {
    var minutes:  Self {
        return abs((self*3600).truncatingRemainder(dividingBy: 3600) / 60)
    }

    var seconds:  Self {
        return abs((self*3600)
                    .truncatingRemainder(dividingBy: 3600)
                    .truncatingRemainder(dividingBy: 60))
    }
}

/// extend CLLocationCoordinate2D to return latitude and longitude in either
/// degrees and minutes or degrees, minutes, and seconds.

extension CLLocationCoordinate2D {
	// degrees and minutes
    var dm: (latitude: String, longitude: String) {
        return (String(format:"%d° %.6f' %@",
                       Int(abs(latitude)),
                       latitude.minutes,
                       latitude >= 0 ? "N" : "S"),
                String(format:"%d° %.6f' %@",
                       Int(abs(longitude)),
                       longitude.minutes,
                       longitude >= 0 ? "E" : "W"))
    }

	// degrees, minutes, and seconds
    var dms: (latitude: String, longitude: String) {
        return (String(format:"%d° %d' %.2f\" %@",
                       Int(abs(latitude)),
                       Int(latitude.minutes),
                       latitude.seconds,
                       latitude >= 0 ? "N" : "S"),
                String(format:"%d° %d' %.2f\" %@",
                       Int(abs(longitude)),
                       Int(longitude.minutes),
                       longitude.seconds,
                       longitude >= 0 ? "E" : "W"))
    }
}

// extend CLLocationCoordinate2D to conform to Equatable

extension CLLocationCoordinate2D: Equatable {
    static public func ==(lhs: Self, rhs: Self) -> Bool {
        return lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude
    }
}
