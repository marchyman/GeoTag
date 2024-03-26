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
                ForEach(otherPins()) { image in
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
                    setCameraPosition(to: searchResult.coordinate.coord2D)
                    searchState.searchText = ""
                }
            }
            .onChange(of: state.tvm.mostSelected) {
                if let location = state.tvm.mostSelected?.location {
                    setCameraPosition(to: location)
                }
            }
            .onTapGesture(count: 2) { position in
                // would like to zoom out if double click with option key.
                if let coords = mapProxy.convert(position,
                                                 from: .local),
                   let camera {
                    withAnimation(.easeInOut) {
                        location.cameraPosition =
                            .camera(.init(centerCoordinate: coords,
                                          distance: camera.distance / 2))
                    }
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

    // return an array of images with coordinates for selected pins that do
    // not match the mostSelected pin if enabled.

    private func otherPins() -> [ImageModel] {
        if location.showOtherPins && !state.tvm.selected.isEmpty {
            let images = state.tvm.selected.filter { $0.location != nil }
            let mainImage = state.tvm.mostSelected ?? ImageModel()
            return images.filter { $0.location != mainImage.location }
        }
        return []
    }

    // Change the camera position to the given place

    private func setCameraPosition(to coords: Coords) {
        location.cameraPosition =
            .camera(.init(centerCoordinate: coords,
                          distance: location.cameraDistance))
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
