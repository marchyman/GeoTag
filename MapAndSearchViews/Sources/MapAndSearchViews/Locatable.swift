// The locations of pins are passsed as objects or values that conform
// to this protocol

import CoreLocation

public protocol Locatable {
    var location: CLLocationCoordinate2D? { get }
}
