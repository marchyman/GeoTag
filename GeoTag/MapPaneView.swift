//
//  MapPaneView.swift
//  GeoTag
//
//  Created by Marco S Hyman on 12/19/22.
//

import SwiftUI
import MapKit

struct MapPaneView: View {
    @Environment(AppViewModel.self) var vm
    @Bindable var mapViewModel = MapViewModel.shared

    @AppStorage(AppSettings.initialMapAltitudeKey)  var initialMapAltitude = 50000.0
    @AppStorage(AppSettings.initialMapLatitudeKey)  var initialMapLatitude = 37.7244
    @AppStorage(AppSettings.initialMapLongitudeKey)  var initialMapLongitude = -122.4381

    var body: some View {
        VStack {
            MapStyleView()
                .padding(.top)
            ZStack(alignment: .topTrailing) {
                MapView(center: Coords(latitude: initialMapLatitude,
                                       longitude: initialMapLongitude),
                        altitude: initialMapAltitude)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(5)
                GeometryReader {geometry in
                    HStack {
                        Spacer()
                        MapSearchView(text: $mapViewModel.searchString)
                            .frame(width: geometry.size.width * 0.80)
                            .onChange(of: mapViewModel.searchString) {
                                searchMap(for: mapViewModel.searchString)
                            }
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
            request.region = MKCoordinateRegion(center: mapViewModel.currentMapCenter,
                                                span: span)
            let searcher = MKLocalSearch(request: request)
            Task {
                if let response = try? await searcher.start() {
                    if let location = response.mapItems[0].placemark.location {
                        if vm.selection.isEmpty {
                            // nothing selected, re center the map
                            mapViewModel.currentMapCenter = location.coordinate
                            mapViewModel.reCenter = true
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

// I don't think this is correct, but it does get rid of the warning
// here: if let response = try? await searcher.start() { ... }

extension MKLocalSearch.Response: @unchecked Sendable {}
