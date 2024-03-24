//
//  MapView.swift
//  SMap
//
//  Created by Marco S Hyman on 3/10/24.
//

import MapKit
import SwiftUI

struct MapView: View {
    let location = LocationModel.shared

    @AppStorage(AppSettings.initialMapDistanceKey)
        var initialMapDistance = 50000.0
    @AppStorage(AppSettings.mapStyleKey)
        var savedMapStyle = MapStyleName.standard.rawValue
    @AppStorage(AppSettings.trackColorKey) var trackColor: Color = .blue
    @AppStorage(AppSettings.trackWidthKey) var trackWidth: Double = 0.0

    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var camera: MapCamera?
    @State private var mapStyleName: MapStyleName = .standard
    @State var searchState: SearchState = .init()

    enum MapFocus: Hashable {
        case map, search, searchList
    }

    @FocusState var mapFocus: MapFocus?

    var body: some View {
        ZStack {
            GeometryReader { geometry in
                MapReader { mapProxy in
                    Map(position: $cameraPosition) {
                        if let pin = location.mainPin {
                            Annotation("main pin",
                                       coordinate: pin.coord2D,
                                       anchor: .bottom) {
                                Image(.pin)
                            }
                                       .annotationTitles(.hidden)
                        }
                        ForEach(location.visablePins) { pin in
                            Annotation("other pin",
                                       coordinate: pin.coord2D,
                                       anchor: .bottom) {
                                Image(.otherPin)
                            }
                                       .annotationTitles(.hidden)
                        }
                        ForEach(location.tracks) { track in
                            MapPolyline(coordinates: track.track)
                                .stroke(trackColor, lineWidth: trackWidth)
                        }
                    }
                    .focusable()
                    .focusEffectDisabled()
                    .focused($mapFocus, equals: .map)
                    .mapStyle(translateLocal(mapStyleName))
                    .mapControls {
                        MapCompass()
                        MapPitchToggle()
                    }
                    .contextMenu {
                        MapContextMenu(camera: $camera,
                                       mapStyleName: $mapStyleName)
                    }
                    .onMapCameraChange(frequency: .onEnd) { context in
                        camera = context.camera
                        location.mapRect = context.rect
                        location.trackSpan = nil
                    }
                    .onAppear {
                        cameraPosition =
                            .camera(.init(centerCoordinate: location.center.coord2D,
                                          distance: initialMapDistance))
                        mapStyleName = .init(rawValue: savedMapStyle) ?? .standard
                    }
                    .onChange(of: mapStyleName) {
                        savedMapStyle = mapStyleName.rawValue
                    }
                    .onChange(of: searchState.searchResult) {
                        if let searchResult = searchState.searchResult {
                            showSearch(result: searchResult)
                            searchState.searchText = ""
                        }
                    }
                    .onTapGesture(coordinateSpace: .named("map")) { position in
                        // when using local coordinate space the conversion from
                        // coordinate space to location is off by an amount that
                        // varies with window/pane size.

                        // when using a named coordinate space the Y coordinate
                        // is calculated from the wrong axis. Therefore the
                        // MapReader is wraped in a GeometryReader so I can
                        // subtract the given positions Y coord from the height
                        // of the frame to get an accurate conversion. I hope.
                        // I'm writing this before actually testing if that
                        // works. Update: it worked.
                        if location.mainPin != nil {
                            let convertedPosition =
                                CGPoint(x: position.x,
                                        y: geometry.size.height - position.y)
                            if let coords = mapProxy.convert(convertedPosition,
                                                             from: .named("map")) {
                                location.center = .init(coords)
                                location.mainPin = .init(coords)
                            }
                        }
                    }
                }
                .coordinateSpace(.named("map"))
            }

            // Using map overlay and/or safeAreaInset caused run time errors
            // instead of tracking those down I'll use a ZStack

            SearchBarView(mapFocus: $mapFocus, searchState: searchState)
                .padding(30)
                .frame(width: 400)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)

            if mapFocus == .search || mapFocus == .searchList {
                GeometryReader { geometry in
                    SearchView(mapFocus: $mapFocus,
                               searchState: searchState,
                               cameraPosition: cameraPosition)
                    .frame(width: 400)
                    .frame(maxWidth: .infinity,
                           maxHeight: geometry.size.height - 70,
                           alignment: .topLeading)
                }
            }
        }
    }

    // Change the camera position to the given place

    private func showSearch(result: SearchPlace) {
        location.center = result.coordinate
        location.mainPin = location.center
        cameraPosition =
            .camera(.init(centerCoordinate: .init(result.coordinate),
                          distance: camera?.distance ?? initialMapDistance))
    }

    private func translateLocal(_ mapStyleName: MapStyleName) -> MapStyle {
        switch mapStyleName {
        case .standard:
            return .standard(elevation: .realistic)
        case .imagery:
            return .imagery
        case .hybrid:
            return .hybrid
        case .standardTraffic:
            return .standard(showsTraffic: true)
        case .hybridTraffic:
            return .hybrid(showsTraffic: true)
        }
    }
}

#Preview {
    MapView()
}
