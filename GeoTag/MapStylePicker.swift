//
//  MapStylePicker.swift
//  SMap
//
//  Created by Marco S Hyman on 3/11/24.
//

import MapKit
import SwiftUI

struct MapStylePicker: View {
    @Binding var mapStyleName: MapStyleName

    var body: some View {
        Picker("Map Style...", selection: $mapStyleName) {
            ForEach(MapStyleName.allCases) { style in
                Text(style.rawValue).tag(style)
            }
        }
        .pickerStyle(.menu)
    }
}

enum MapStyleName: String, CaseIterable, Identifiable {
    case standard = "Standard"
    case imagery = "Imagery"
    case hybrid = "Hybrid"
    case standardTraffic = "Standard with traffic"
    case hybridTraffic = "Hybrid with traffic"

    var id: MapStyleName { self }
}
