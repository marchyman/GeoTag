//
//  ImageModelStringRep.swift
//  GeoTag
//
//  Created by Marco S Hyman on 1/7/23.
//

import Foundation

// The representation of location and optionally elevation as a string.
// This value is used for copy and paste.
// Format: "latitude, longitude, elevation"
// latitude and longitude are formatted per GeoTag settings

extension ImageModel {
    var stringRepresentation: String {
        var stringRep = ""
        if location != nil {
            stringRep = "\(formattedLatitude), \(formattedLongitude)"
            if let elevation {
                stringRep += ", \(elevation)"
            }
        }
        return stringRep
    }

    // decode the above string representation into a tuple containing
    // coordinates and optional elevation.

    static func decodeStringRep(value: String) -> (Coords, Double?)? {
        // accept "| " as a separator for backwards compatibility
        let separator = /[,|]\s+/
        let components = value.split(separator: separator)
        if components.count == 2 || components.count == 3 {
            var coords: Coords

            if let latitude = try? String(components[0])
                    .validateCoord(range: 0...90, reference: Coords.latRef),
               let longitude = try? String(components[1])
                    .validateCoord(range: 0...180, reference: Coords.lonRef) {
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
