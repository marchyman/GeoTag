//
//  MapStyleView.swift
//  GeoTag
//
//  Created by Marco S Hyman on 12/19/22.
//

import SwiftUI
import MapKit

struct MapStyleView: View {
    @ObservedObject var mapViewModel = MapViewModel.shared
    @State private var showPopover = false

    var body: some View {
        HStack {
            Picker("Map Type", selection: $mapViewModel.mapConfiguration) {
                Text("Standard").tag(0)
                Text("Hybrid").tag(1)
                Text("Satellite").tag(2)
            }
            .labelsHidden()
            .pickerStyle(.segmented)
            .background(RoundedRectangle(cornerRadius: 5).fill(Color(white: 0.7)))
            .padding(.leading)
            .frame(maxWidth: 250)

            Spacer()

            Button("Save map location") {
                mapViewModel.initialMapLatitude = mapViewModel.currentMapCenter.latitude
                mapViewModel.initialMapLongitude = mapViewModel.currentMapCenter.longitude
                mapViewModel.initialMapAltitude = mapViewModel.currentMapAltitude
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
