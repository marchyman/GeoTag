//
//  ImageLongitudeColumnView.swift
//  GeoTag
//
//  Created by Marco S Hyman on 12/17/22.
//

import SwiftUI

struct ImageLongitudeColumnView: View {
    @AppStorage(AppSettings.coordFormatKey) var coordFormat: AppSettings.CoordFormat = .deg
    @EnvironmentObject var vm: AppState
    let id: ImageModel.ID

    var body: some View {
        Text(longitudeToString())
            .foregroundColor(vm[id].isValid ? .primary : .gray)
    }

    func longitudeToString() -> String {
        if let location = vm[id].location {
            switch coordFormat {
            case .deg:
                return String(format: "% 2.6f", location.longitude)
            case .degMin:
                return location.dm.longitude
            case .degMinSec:
                return location.dms.longitude
            }
        }
        return ""
    }
}
