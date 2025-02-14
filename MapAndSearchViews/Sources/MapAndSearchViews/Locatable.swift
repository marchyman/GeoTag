//
// Copyright 2024 Marco S Hyman
// See LICENSE file for info
// https://www.snafu.org/
//

// The locations of pins are passsed as objects or values that conform
// to this protocol

import CoreLocation

public protocol Locatable {
    var location: CLLocationCoordinate2D? { get }
}
