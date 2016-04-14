//
//  Interpolate.swift
//  GeoTag
//
//  Created by Marco S Hyman on 5/19/15.
//  Copyright (c) 2015 Marco S Hyman, CC-BY-NC
//

import Foundation

// constants used in this file
private let π = M_PI
private let d2r = π / 180   // degrees to radians adjustment
private let r2d = 180 / π   // radians to degrees adjustments
private let R = 6372800.0	// approx average radius of the earth in meters

private func degreesToRadians(degrees: Double) -> Double {
    return degrees * d2r
}

private func radiansToDegrees(radians: Double) -> Double {
    return radians * r2d
}

/// return distance in meters and bearing between two lat/lon pairs
/// - Parameter lat1: latitude of starting point
/// - Parameter lon1: longitude of starting point
/// - Parameter lat2: latitude of ending point
/// - Parameter lon2: longitude of ending point
/// - Returns: tuple containg distance and bearing from starting point to ending point
///
/// distance and bearing calculated using the haversine formula

public func distanceAndBearing(lat1: Double, lon1: Double,
                               lat2: Double, lon2: Double) -> (Double, Double) {
    let lat1R = degreesToRadians(degrees: lat1)
    let lon1R = degreesToRadians(degrees: lon1)
    let lat2R = degreesToRadians(degrees: lat2)
    let lon2R = degreesToRadians(degrees: lon2)
    let deltaLat = lat2R - lat1R
    let deltaLon = lon2R - lon1R
    let a = sin(deltaLat/2) * sin(deltaLat/2) + 
            sin(deltaLon/2) * sin(deltaLon/2) * cos(lat1R) * cos(lat2R)
    let distance = 2 * asin(sqrt(a)) * R

    let b = atan2(sin(deltaLon) * cos(lat2R),
                  cos(lat1R) * sin(lat2R) - sin(lat1R) * cos(lat2R) * cos(deltaLon))
    let bearing = (radiansToDegrees(radians: b) + 360.0) % 360.0
    return (distance, bearing)
}

/// return lat/lon of a destination point point a given distance and bearing
/// from a starting point
/// - Parameter lat: latitude of starting point
/// - Parameter lon: longitude of starting point
/// - Parameter distance: distance to destination point
/// - Parameter bearing: bearing to destination point
/// - Returns: tuple containing the latitude and longitude of the destination

public func destFromStart(lat: Double, lon: Double,
                          distance: Double, bearing: Double) -> (Double, Double) {
    let latR = degreesToRadians(degrees: lat)
    let lonR = degreesToRadians(degrees: lon)
    let angularDist = distance / R
    let bearingR = degreesToRadians(degrees: bearing)

    let lat2R = asin(sin(latR) * cos(angularDist) +
                     cos(latR) * sin(angularDist) * cos(bearingR))
    let lon2R = lonR +
                atan2(sin(bearingR) * sin(angularDist) * cos(latR),
                      cos(angularDist) - sin(latR) * sin(lat2R))
    return (radiansToDegrees(radians: lat2R), radiansToDegrees(radians: lon2R))
}

