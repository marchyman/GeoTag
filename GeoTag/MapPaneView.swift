//
//  MapPaneView.swift
//  GeoTag
//
//  Created by Marco S Hyman on 12/19/22.
//

import SwiftUI
import MapKit

struct MapPaneView: View {
    @AppStorage(AppSettings.mapTypeIndexKey) private var mapTypeIndex = 0
    @AppStorage(AppSettings.mapLatitudeKey) private var mapLatitude = 37.7244
    @AppStorage(AppSettings.mapLongitudeKey) private var mapLongitude = -122.4381
    @AppStorage(AppSettings.mapAltitudeKey) private var mapAltitude = 50000.0

    @State private var searchString = ""

    var body: some View {
        VStack {
            MapStyleView()
                .padding(.top)
            ZStack(alignment: .topTrailing) {
                MapView(mapType: mapTypes[mapTypeIndex],
                        center: CLLocationCoordinate2D(latitude: mapLatitude,
                                                       longitude: mapLongitude),
                        altitude: mapAltitude)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(5)
                GeometryReader {geometry in
                    MapSearchView(text: $searchString)
                        .frame(width: geometry.size.width * 0.80)
                }
                .padding()
            }
        }
    }
}

struct MapPaneView_Previews: PreviewProvider {
    static var previews: some View {
        MapPaneView()
    }
}
