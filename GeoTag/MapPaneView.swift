//
//  MapPaneView.swift
//  GeoTag
//
//  Created by Marco S Hyman on 12/19/22.
//

import SwiftUI
import MapKit

struct MapPaneView: View {
    @EnvironmentObject var vm: ViewModel
    @ObservedObject var mapViewModel = MapViewModel.shared

    var body: some View {
        VStack {
            MapStyleView()
                .padding(.top)
            ZStack(alignment: .topTrailing) {
                MapView(center: Coords(latitude: mapViewModel.initialMapLatitude,
                                       longitude: mapViewModel.initialMapLongitude),
                        altitude: mapViewModel.initialMapAltitude)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(5)
                GeometryReader {geometry in
                    HStack {
                        Spacer()
                        MapSearchView(text: $mapViewModel.searchString)
                            .frame(width: geometry.size.width * 0.80)
                            .onChange(of: mapViewModel.searchString) {
                                searchMap(for: $0)
                            }
                    }
                }
                .padding()
            }
        }
        .onChange(of: vm.mostSelected) { mainPinChange(id: $0) }
        .onChange(of: mapViewModel.locationUpdated) { _ in
            mainPinChange(id: vm.mostSelected)
        }
        .onChange(of: vm.selection) { otherPinsChange(selection: $0) }
    }


    func mainPinChange(id: ImageModel.ID?) {
        if let id,
           let location = vm[id].location {
            if location != mapViewModel.mainPin?.coordinate {
                if mapViewModel.mainPin == nil {
                    mapViewModel.mainPin = MKPointAnnotation()
                }
                mapViewModel.mainPin?.coordinate = location
            }
        } else {
            mapViewModel.mainPin = nil
        }
    }

    // create pins for other selected items that have a location

    func otherPinsChange(selection: Set<ImageModel.ID>) {
        var pins = [MKPointAnnotation]()
        for id in selection.filter({ $0 != vm.mostSelected
                                     && vm[$0].location != nil }) {
            let pin = MKPointAnnotation()
            pin.title = "other"
            pin.coordinate = vm[id].location!
            pins.append(pin)
        }
        mapViewModel.otherPins = pins
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
                searcher.start {  response, error in
                    if error == nil,
                       let location = response?.mapItems[0].placemark.location {
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
