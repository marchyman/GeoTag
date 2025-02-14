//
// Copyright 2024 Marco S Hyman
// See LICENSE file for info
// https://www.snafu.org/
//

import MapKit
import SwiftUI

struct MapContextMenu: View {
    @Bindable var masData: MapAndSearchData
    let camera: MapCamera?
    @Binding var mapStyleName: MapStyleName

    var body: some View {
        Group {
            MapStylePicker(mapStyleName: $mapStyleName)

            Picker("Pin view options…", selection: $masData.showOtherPins) {
                Text("Show pins for all selected items").tag(true)
                Text("Show pin for most selected item").tag(false)
            }
            .pickerStyle(.menu)

            Divider()

            Button("Save map location") {
                if let camera {
                    masData.initialMapLatitude = camera.centerCoordinate.latitude
                    masData.initialMapLongitude = camera.centerCoordinate.longitude
                    masData.initialMapDistance = camera.distance
                }
            }
            .padding()
            .disabled(camera == nil)
        }
    }
}
