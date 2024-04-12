//
//  MapView.swift
//  SMap
//
//  Created by Marco S Hyman on 3/10/24.
//

import MapKit
import SwiftUI

struct MapView: View {
    @Environment(AppState.self) var state
    var mapFocus: FocusState<MapWrapperView.MapFocus?>.Binding
    @Binding var searchState: SearchState

    let location = LocationModel.shared

    @AppStorage(AppSettings.initialMapLatitudeKey)
        var initialMapLatitude = 37.7244
    @AppStorage(AppSettings.initialMapLongitudeKey)
        var initialMapLongitude = -122.4381
    @AppStorage(AppSettings.initialMapDistanceKey)
        var initialMapDistance = 50000.0
    @AppStorage(AppSettings.mapStyleKey)
        var savedMapStyle = MapStyleName.standard.rawValue
    @AppStorage(AppSettings.trackColorKey) var trackColor: Color = .blue
    @AppStorage(AppSettings.trackWidthKey) var trackWidth: Double = 0.0

    @State private var camera: MapCamera?
    @State private var mapStyleName: MapStyleName = .standard

    var body: some View {
        @Bindable var location = location
        MapReader { mapProxy in
            Map(position: $location.cameraPosition) {
                if let coords = state.tvm.mostSelected?.location {
                    Annotation("main pin",
                               coordinate: coords,
                               anchor: .bottom) {
                        Image(.pin)
                    }
                    .annotationTitles(.hidden)
                }
                ForEach(location.otherPins(tvm: state.tvm)) { image in
                    Annotation("other pin",
                               coordinate: image.location!,
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
            .mapStyle(translateLocal(mapStyleName))
            .mapControls {
                MapCompass()
                MapPitchToggle()
                MapScaleView()
                MapZoomStepper()
            }
            .contextMenu {
                MapContextMenu(camera: $camera,
                               mapStyleName: $mapStyleName)
            }
            .onMapCameraChange(frequency: .onEnd) { context in
                camera = context.camera
                if let distance = camera?.distance {
                    location.cameraDistance = distance
                }
                location.mapRect = context.rect
            }
            .onAppear {
                let center = Coords(latitude: initialMapLatitude,
                                    longitude: initialMapLongitude)
                location.cameraDistance = initialMapDistance
                location.cameraPosition =
                    .camera(.init(centerCoordinate: center,
                                  distance: location.cameraDistance))
                mapStyleName = .init(rawValue: savedMapStyle) ?? .standard
            }
            .onChange(of: mapStyleName) {
                savedMapStyle = mapStyleName.rawValue
            }
            .onChange(of: searchState.searchResult) {
                if let searchResult = searchState.searchResult {
                    location.setCameraPosition(to: searchResult.coordinate.coord2D)
                    searchState.searchText = ""
                }
            }
            .onChange(of: state.tvm.mostSelected) {
                location.recenterMap(locn: state.tvm.mostSelected?.location)
            }
            .gesture(zoomOut)
            .onTapGesture(count: 2) { position in
                if let coords = mapProxy.convert(position, from: .local) {
                    zoom(around: coords)
                }
            }
            .onTapGesture { position in
                mapFocus.wrappedValue = nil  // get rid of any search views

                if let image = state.tvm.mostSelected {
                    if let coords = mapProxy.convert(position,
                                                     from: .local) {
                        state.update(image, location: coords)
                    }
                }
            }
        }
    }

    // zoom out around center on double click with option key
    var zoomOut: some Gesture {
        TapGesture(count: 2).modifiers(.option).onEnded {
            if let camera {
                zoom(around: camera.centerCoordinate, out: true)
            }
        }
    }

    private func zoom(around coords: Coords, out: Bool = false) {
        if let camera {
            let distance = out ? camera.distance * 2
                               : camera.distance / 2
            withAnimation(.easeInOut) {
                location.cameraPosition =
                    .camera(.init(centerCoordinate: coords,
                                  distance: distance))
            }
        }
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
    @State var searchState: SearchState = .init()
    @FocusState var mapFocus: MapWrapperView.MapFocus?
    return MapView(mapFocus: $mapFocus,
                   searchState: $searchState)
                .frame(width: 512, height: 512)
}
