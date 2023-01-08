//
//  ImageModelStringRep.swift
//  GeoTag
//
//  Created by Marco S Hyman on 1/7/23.
//

import Foundation

// The representation of location and optionally elevation as a string.
// This value is used for copy and paste.
// Format: "latitude | longitude | elevation"

extension ImageModel {
    var stringRepresentation: String {
        var stringRep = ""
        if let location {
            stringRep = "\(location.latitude) | \(location.longitude)"
            if let elevation {
                stringRep += " | \(elevation)"
            }
        }
        return stringRep
    }

    // decode the above string representation into a tuple containing
    // coordinates and optional elevation.

    static func decodeStringRep(value: String) -> (Coords, Double?)? {
        let components = value.components(separatedBy: "|")
        if components.count == 2 || components.count == 3 {
            var coords: Coords

            if let latitude = components[0].validateLocation(range: 0...90,
                                                             reference: ["N", "S"]),
               let longitude = components[1].validateLocation(range: 0...180,
                                                              reference: ["E", "W"]) {
                coords = Coords(latitude: latitude, longitude: longitude)
                if components.count == 3 {
                    let eleVal = components[2].trimmingCharacters(in: .whitespaces)
                    if let elevation = Double(eleVal) {
                        return (coords, elevation)
                    }
                } else {
                    return (coords, nil)
                }
            }
        }
        return nil
    }

}
