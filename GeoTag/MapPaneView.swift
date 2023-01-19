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

    @EnvironmentObject var vm: ViewModel
    @State private var searchString = ""
    @State private var reCenter = false

    var body: some View {
        VStack {
            MapStyleView()
                .padding(.top)
            ZStack(alignment: .topTrailing) {
                MapView(mapType: mapTypes[mapTypeIndex],
                        center: Coords(latitude: mapLatitude,
                                       longitude: mapLongitude),
                        altitude: mapAltitude,
                        reCenter: $reCenter)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(5)
                GeometryReader {geometry in
                    HStack {
                        Spacer()
                        MapSearchView(text: $searchString)
                            .frame(width: geometry.size.width * 0.80)
                            .onChange(of: searchString) { searchMap(for: $0) }
                    }
                }
                .padding()
            }
        }
    }

    // The work of searching the map is done here as this view is parent
    // to both the map view and the map search view and can best handle
    // needed communications between the two.

    func searchMap(for searchString: String) {
        if !searchString.isEmpty {
            // build a "local" search request where the local area is the entire globe
            let request = MKLocalSearch.Request()
            request.naturalLanguageQuery = searchString
            let span = MKCoordinateSpan(latitudeDelta: 90.0,
                                        longitudeDelta: 180.0)
            request.region = MKCoordinateRegion(center: vm.mapCenter,
                                                span: span)
            let searcher = MKLocalSearch(request: request)
            Task {
                searcher.start {  response, error in
                    if error == nil,
                       let location = response?.mapItems[0].placemark.location {
                        if vm.selection.isEmpty {
                            // nothing selected, re center the map
                            vm.mapCenter = location.coordinate
                            reCenter = true
                        } else {
                            // update all selected items
                            vm.undoManager.beginUndoGrouping()
                            for id in vm.selection {
                                vm.update(id: id, location: location.coordinate)
                            }
                            vm.undoManager.endUndoGrouping()
                            vm.undoManager.setActionName("set location (search)")
                        }
                    }
                }
            }
        }
    }
}

struct MapPaneView_Previews: PreviewProvider {
    static var previews: some View {
        MapPaneView()
    }
}
