//
//  Settings.swift
//  GeoTag
//
//  Created by Marco S Hyman on 12/17/22.
//

import Foundation
import SwiftUI

struct AppSettings {
    static let coordFormatKey = "CoordFormatKey"

    enum CoordFormat: Int {
            case deg
            case degMin
            case degMinSec
        }

    // select a text color the opposite of the color scheme when a color
    // must be specified
    static func textColor(_ colorScheme: ColorScheme) -> Color {
        let color: Color
        switch colorScheme {
        case .light:
            color = .black
        case .dark:
            color = .white
        @unknown default:
            fatalError("Unknown ColorScheme")
        }
        return color
    }

}

