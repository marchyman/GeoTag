// Names of the map styles supported by this package

import MapKit
import SwiftUI

enum MapStyleName: String, CaseIterable, Identifiable {
    case standard = "Standard"
    case imagery = "Imagery"
    case hybrid = "Hybrid"
    case standardTraffic = "Standard with traffic"
    case hybridTraffic = "Hybrid with traffic"

    var id: MapStyleName { self }

    func mapStyle() -> MapStyle {
        switch self {
        case .standard:
            return .standard(elevation: .realistic)
        case .imagery:
            return .imagery
        case .hybrid:
            return .hybrid
        case .standardTraffic:
            return .standard(showsTraffic: true)
        case .hybridTraffic:
            return .hybrid(showsTraffic: true)
        }
    }
}

// A picker view used to select a map style

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
