//
//  MapContextMenu.swift
//  SMap
//
//  Created by Marco S Hyman on 3/11/24.
//

import MapKit
import SwiftUI

struct MapContextMenu: View {
    @AppStorage("AppSettings.initialMapLatitudeKey")
        var initialMapLatitude = 37.7244
    @AppStorage("AppSettings.initialMapLongitudeKey")
        var initialMapLongitude = -122.4381
    @AppStorage("AppSettings.initialMapDistanceKey")
        var initialMapDistance = 50000.0

    @Binding var camera: MapCamera?
    @Binding var mapStyleName: MapStyleName

    var body: some View {
        Group {
            MapStylePicker(mapStyleName: $mapStyleName)
            Button("Save map location") {
                if let camera {
                    initialMapLatitude = camera.centerCoordinate.latitude
                    initialMapLongitude = camera.centerCoordinate.longitude
                    initialMapDistance = camera.distance
                }
            }
            .padding()
            .disabled(camera == nil)
        }
    }
}
