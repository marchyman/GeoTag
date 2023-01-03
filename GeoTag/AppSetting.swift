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
    static let mapTypeIndexKey = "MapTypeIndexKey"
    static let mapLatitudeKey = "MapLatitudeKey"
    static let mapLongitudeKey = "MapLongitudeKey"
    static let mapAltitudeKey = "MapAltitudeKey"
    static let dividerPositionKey = "DividerPositionKey"
    static let trackColorKey = "TrackColorKey"
    static let trackWidthKey = "TrackWidthKey"


    enum CoordFormat: Int {
        case deg
        case degMin
        case degMinSec
    }

}

