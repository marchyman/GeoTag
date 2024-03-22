//
//  LocationModel.swift
//  SMap
//
//  Created by Marco S Hyman on 3/21/24.
//

import MapKit
import SwiftUI

@Observable
final class LocationModel {
    // map center
    var center: Coordinate
    var mainPin: Coordinate?
    var otherPins: [Coordinate] = []

    init(latitude: Double, longitude: Double) {
        self.center = Coordinate(latitude: latitude, longitude: longitude)
    }
}

// MARK: Coordinate
// a codable struct to hold the same data as a CLLocationCoordiante2D

struct Coordinate: Codable, Hashable, Identifiable {
    var latitude: Double
    var longitude: Double
    var id = UUID()
    var coord2D: CLLocationCoordinate2D {
        .init(self)
    }
}

// conversions between Coordinate and CLLocationCoordinate2d

extension CLLocationCoordinate2D {
    init(_ coordinate: Coordinate) {
        self = .init(latitude: coordinate.latitude,
                     longitude: coordinate.longitude)
    }
}

extension Coordinate {
    init(_ coordinate: CLLocationCoordinate2D) {
        self = .init(latitude: coordinate.latitude,
                     longitude: coordinate.longitude)
    }
}
