//
//  ImageTableColumnNames.swift
//  GeoTag
//
//  Created by Marco S Hyman on 7/7/23.
//

import SwiftUI

/// Computed properties to convert elements of an imageModel into values for use with
/// ImageTableView, espeically with regard to sorting and display.
///
extension ImageModel {
    var name: String {
        fileURL.lastPathComponent + (sidecarExists ? "*" : "")
    }

    var timeStamp: String {
        dateTimeCreated ?? ""
    }

    var latitude: Double {
        location?.latitude ?? 0.0
    }

    var longitude: Double {
        location?.longitude ?? 0.0
    }

    var timestampTextColor: Color {
        if isValid {
            if dateTimeCreated == originalDateTimeCreated {
                return .primary
            }
            return .changed
        }
        return .secondary
    }

    var locationTextColor: Color {
        if isValid {
            if location == originalLocation {
                return .primary
            }
            return .changed
        }
        return .secondary
    }

    var elevationAsString: String {
        var value = "Elevation: "
        if let elevation {
            value += String(format: "% 4.2f", elevation)
            value += " meters"
        } else {
            value += "Unknown"
        }
        return value
    }

}
