//
//  Settings.swift
//  GeoTag
//
//  Created by Marco S Hyman on 12/17/22.
//

import Foundation
import SwiftUI

struct SettingsInfo {
    static let coordFormatKey = "CoordFormatKey"

    enum CoordFormat: Int {
            case deg
            case degMin
            case degMinSec
        }

    @AppStorage(SettingsInfo.coordFormatKey) var coordFormat: SettingsInfo.CoordFormat = .deg

}

