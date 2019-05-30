//
//  Coord.swift
//  GeoTag
//
//  Created by Marco S Hyman on 4/27/19.
//  Copyright 2019 Marco S Hyman
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
