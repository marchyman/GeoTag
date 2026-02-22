import MapKit
import SwiftUI

struct MapContextMenu: View {
    let camera: MapCamera?
    @Binding var mapStyleName: MapStyleName

    @AppStorage(MapView.initialMapLatitudeKey) var initialMapLatitude = 37.7244
    @AppStorage(MapView.initialMapLongitudeKey) var initialMapLongitude = -122.4381
    @AppStorage(MapView.initialMapDistanceKey) var initialMapDistance = 50_000.0

    var body: some View {
        Group {
            MapStylePicker(mapStyleName: $mapStyleName)

            PinOptionView()

            Divider()

            Button {
                if let camera {
                    initialMapLatitude = camera.centerCoordinate.latitude
                    initialMapLongitude = camera.centerCoordinate.longitude
                    initialMapDistance = camera.distance
                }
            } label: {
                Label("Save map location", systemImage: "location")
            }
            .padding()
            .disabled(camera == nil)
        }
    }
}
