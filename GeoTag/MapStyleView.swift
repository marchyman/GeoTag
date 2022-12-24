//
//  MapStyleView.swift
//  GeoTag
//
//  Created by Marco S Hyman on 12/19/22.
//

import SwiftUI
import MapKit

let mapTypes = [MKMapType.standard, MKMapType.satellite, MKMapType.hybrid]

/// Extension to map an MKMapType to a String
extension MKMapType {
    var name: String {
        switch self {
        case .standard:
            return "Map"
        case .hybrid:
            return "Hybrid"
        case .satellite:
            return "Satellite"
        default:
            return "Other"
        }
    }
}

struct MapStyleView: View {
    @AppStorage(AppSettings.mapTypeIndexKey) private var mapTypeIndex = 0
    @AppStorage(AppSettings.mapLatitudeKey) private var mapLatitude = 37.7244
    @AppStorage(AppSettings.mapLongitudeKey) private var mapLongitude = -122.4381
    @AppStorage(AppSettings.mapAltitudeKey) private var mapAltitude = 50000.0

    @State private var showPopover = false

    var body: some View {
        HStack {
            Picker("Map Type", selection: $mapTypeIndex) {
                ForEach(0 ..< mapTypes.count, id: \.self) { index in
                    Text(mapTypes[index].name).tag(index)
                }
            }
            .labelsHidden()
            .pickerStyle(.segmented)
            .background(RoundedRectangle(cornerRadius: 5)
                .fill(Color(white: 0.7)))
            .padding(.leading)
            .frame(maxWidth: 250)

            Spacer()

            Button("Save map location") {
                guard let view = MapView.view else {
                    // put up some type of alert here
                    return
                }
                mapLatitude = view.camera.centerCoordinate.latitude
                mapLongitude = view.camera.centerCoordinate.longitude
                mapAltitude = view.camera.altitude
                showPopover.toggle()
            }
            .padding(.trailing)
            .help("Save the current map coordinates, and zoom level.")
            .popover(isPresented: $showPopover) {
                SaveLocationPopoverView()
                    .padding()
            }
        }
    }
}

struct SaveLocationPopoverView: View {
    @Environment(\.dismiss) var dismiss
    let timer = Timer.publish(every: 2, on: .main, in: .common).autoconnect()

    var body: some View {
        Text("Current Map Location Saved")
            .onReceive(timer) { _ in
                dismiss()
            }
    }
}


struct MapStyleView_Previews: PreviewProvider {
    static var previews: some View {
        MapStyleView()
    }
}
