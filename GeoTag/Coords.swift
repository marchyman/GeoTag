//
//  Coord.swift
//  GeoTag
//
//  Created by Marco S Hyman on 4/27/19.
//

import Foundation
import CoreLocation

// A shorter name for a type I'll often use
typealias Coords = CLLocationCoordinate2D

/// extend CLLocationCoordinate2D to conform to Equatable

extension CLLocationCoordinate2D: Equatable {
    static public func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude
    }
}
