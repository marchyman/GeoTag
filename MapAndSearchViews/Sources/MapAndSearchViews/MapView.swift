//
// Copyright 2024 Marco S Hyman
// See LICENSE file for info
// https://www.snafu.org/
//

import MapKit
import SwiftUI

struct MapView: View {
    @Bindable var masData: MapAndSearchData
    var mapFocus: FocusState<MapAndSearchView.MapFocus?>.Binding
    let mainPin: Locatable?
    let allPins: [Locatable]
    let updatePins: (CLLocationCoordinate2D) -> Void

    let zoomDistance = 1000.0

    @State private var camera: MapCamera?
    @State private var mapStyleName: MapStyleName = .standard

    var body: some View {
        MapReader { mapProxy in
            Map(position: $masData.cameraPosition) {
                if let coords = mainPin?.location {
                    Annotation(
                        "main pin",
                        coordinate: coords,
                        anchor: .bottom
                    ) {
                        Image(.pin)
                    }
                    .annotationTitles(.hidden)
                }
                ForEach(
                    masData.otherPins(
                        mainPin: mainPin,
                        allPins: allPins)
                ) { pin in
                    Annotation(
                        "other pin",
                        coordinate: pin.location,
                        anchor: .bottom
                    ) {
                        Image(.otherPin)
                    }
                    .annotationTitles(.hidden)
                }
                ForEach(masData.tracks) { track in
                    MapPolyline(coordinates: track.coords)
                        .stroke(
                            masData.trackColor,
                            lineWidth: masData.trackWidth)
                }
            }
            .mapStyle(mapStyleName.mapStyle())
            .mapControls {
                MapCompass()
                MapPitchToggle()
                MapScaleView()
                MapZoomStepper()
            }
            .contextMenu {
                MapContextMenu(
                    masData: masData,
                    camera: camera,
                    mapStyleName: $mapStyleName)
            }
            .simultaneousGesture(SpatialTapGesture().onEnded { position in
                mapFocus.wrappedValue = nil  // get rid of any search views
                if let loc = mapProxy.convert(position.location, from: .local) {
                    updatePins(loc)
                }
            })
            .onMapCameraChange(frequency: .onEnd) { context in
                camera = context.camera
                if let distance = camera?.distance {
                    masData.cameraDistance = distance
                }
                masData.mapRect = context.rect
            }
            .onChange(of: mapStyleName) {
                masData.savedMapStyle = mapStyleName.rawValue
            }
            .onChange(of: masData.searchResult) {
                if let searchResult = masData.searchResult {
                    if !allPins.isEmpty {
                        // zoom in to better show pin when necessary
                        if masData.cameraDistance > zoomDistance {
                            masData.cameraDistance = zoomDistance
                        }
                        updatePins(searchResult.coordinate.coord2D)
                    } else {
                        masData.setCameraPosition(to: searchResult.coordinate.coord2D)
                    }
                    masData.searchText = ""
                }
            }
            .onChange(of: mainPin?.location) {
                masData.recenterMap(coords: mainPin?.location)
            }
            .onAppear {
                let center = CLLocationCoordinate2D(
                    latitude: masData.initialMapLatitude,
                    longitude: masData.initialMapLongitude)
                masData.cameraDistance = masData.initialMapDistance
                masData.cameraPosition =
                    .camera(
                        .init(
                            centerCoordinate: center,
                            distance: masData.cameraDistance))
                mapStyleName = .init(rawValue: masData.savedMapStyle) ?? .standard
            }
        }
    }
}
