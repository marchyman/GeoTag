//
//  ImageLatitudeColumnView.swift
//  GeoTag
//
//  Created by Marco S Hyman on 12/17/22.
//

import SwiftUI

struct ImageLatitudeColumnView: View {
    @AppStorage(AppSettings.coordFormatKey) var coordFormat: AppSettings.CoordFormat = .deg
    @EnvironmentObject var vm: AppState
    let id: ImageModel.ID

    var body: some View {
        Text(latitudeToString())
            .foregroundColor(vm[id].isValid ? .primary : .gray)
    }

    func latitudeToString() -> String {
        if let location = vm[id].location {
            switch coordFormat {
            case .deg:
                return String(format: "% 2.6f", location.latitude)
            case .degMin:
                return location.dm.latitude
            case .degMinSec:
                return location.dms.latitude
            }
        }
        return ""
    }
}
