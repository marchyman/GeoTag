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
        let _ = print("mainPin location \(String(describing: mainPin?.location))")
        MapReader { mapProxy in
            Map(position: $masData.cameraPosition) {
                if let coords = mainPin?.location {
                    Annotation("main pin",
                                coordinate: coords,
                                anchor: .bottom) {
                        Image(.pin)
                    }
                   .annotationTitles(.hidden)
                }
                ForEach(masData.otherPins(mainPin: mainPin,
                                          allPins: allPins)) { pin in
                    Annotation("other pin",
                               coordinate: pin.location,
                               anchor: .bottom) {
                        Image(.otherPin)
                    }
                   .annotationTitles(.hidden)
                }
                ForEach(masData.tracks) { track in
                    MapPolyline(coordinates: track.coords)
                        .stroke(masData.trackColor,
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
                MapContextMenu(masData: masData,
                               camera: camera,
                               mapStyleName: $mapStyleName)
            }
            .gesture(zoomOut)
            .onTapGesture(count: 2) { position in
                if let coords = mapProxy.convert(position, from: .local) {
                    zoom(around: coords)
                }
            }
            .onTapGesture { position in
                mapFocus.wrappedValue = nil  // get rid of any search views
                if let loc = mapProxy.convert(position, from: .local) {
                    updatePins(loc)
                }
            }
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
                    .camera(.init(centerCoordinate: center,
                                  distance: masData.cameraDistance))
                mapStyleName = .init(rawValue: masData.savedMapStyle) ?? .standard
            }
        }
    }
}

// Zoom

extension MapView {

    // Zoom in or out by a factor of two
    private func zoom(around coords: CLLocationCoordinate2D, out: Bool = false) {
        if let camera {
            let distance = out ? camera.distance * 2
                               : camera.distance / 2
            withAnimation(.easeInOut) {
                masData.cameraPosition =
                    .camera(.init(centerCoordinate: coords,
                                  distance: distance))
            }
        }
    }

    // option-double click gesture zooms out
    var zoomOut: some Gesture {
        TapGesture(count: 2).modifiers(.option).onEnded {
            if let camera {
                zoom(around: camera.centerCoordinate, out: true)
            }
        }
    }
}
