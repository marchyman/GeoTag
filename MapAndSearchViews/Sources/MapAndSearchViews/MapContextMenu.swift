import MapKit
import SwiftUI

struct MapContextMenu: View {
    let masData: MapAndSearchData
    let camera: MapCamera?
    @Binding var mapStyleName: MapStyleName

    var body: some View {
        Group {
            MapStylePicker(mapStyleName: $mapStyleName)
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
