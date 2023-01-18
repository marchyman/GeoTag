//
//  CoordFormatter.swift
//  GeoTag
//
//  Created by Marco S Hyman on 1/16/23.
//

import SwiftUI

// Latitude format

struct LatitudeStyle: ParseableFormatStyle {

    var parseStrategy: LatitudeStrategy = .init()

    func format(_ value: Double?) -> String {
        @AppStorage(AppSettings.coordFormatKey) var coordFormat: AppSettings.CoordFormat = .deg

        return coordToString(for: value, format: coordFormat, ref: latRef)
    }
}

struct LatitudeStrategy: ParseStrategy {
    func parse(_ value: String) throws -> Double? {
        // if the latitude isn't valid return an out-of-range value
        return try value.validateCoord(range: 0...90, reference: latRef)
    }
}

extension FormatStyle where Self == LatitudeStyle {
    static func latitude() -> LatitudeStyle {
        return LatitudeStyle()
    }
}

// Longitude format

struct LongitudeStyle: ParseableFormatStyle {

    var parseStrategy: LongitudeStrategy = .init()

    func format(_ value: Double?) -> String {
        @AppStorage(AppSettings.coordFormatKey) var coordFormat: AppSettings.CoordFormat = .deg

        return coordToString(for: value, format: coordFormat, ref: lonRef)
    }
}

struct LongitudeStrategy: ParseStrategy {
    func parse(_ value: String) throws -> Double? {
        // if the longitude isnt valid return an oyut-of-range value
        return try value.validateCoord(range: 0...180, reference: lonRef)
    }
}

extension FormatStyle where Self == LongitudeStyle {
    static func longitude() -> LongitudeStyle {
        return LongitudeStyle()
    }
}

func coordToString(for coord: Double?,
                   format: AppSettings.CoordFormat,
                   ref: [String]) -> String {
    if let coord {
        switch format {
        case .deg:
            return String(format: "% 2.6f", coord)
        case .degMin:
            return coord.dm(ref)
        case .degMinSec:
            return coord.dms(ref)
        }
    }
    return ""
}
