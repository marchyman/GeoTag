import Coords
import MapKit
import SwiftUI
import UDF

struct MapView: View {
    @Environment(Store<GeoTagState, GeoTagEvent>.self) var store

    @AppStorage(Self.initialMapLatitudeKey) var initialMapLatitude = 37.7244
    @AppStorage(Self.initialMapLongitudeKey) var initialMapLongitude = -122.4381
    @AppStorage(Self.initialMapDistanceKey) var initialMapDistance = 50_000.0
    @AppStorage(Self.savedMapStyleKey) var savedMapStyle = MapStyleName.standard.rawValue

    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var cameraDistance: Double = 0
    @State private var mapRect: MKMapRect?
    @State private var camera: MapCamera?
    @State private var mapStyleName: MapStyleName = .standard
    @State private var mainPin: Coords?
    @State private var allPins: [Coords] = []

    var body: some View {
        MapReader { mapProxy in
            Map(position: $cameraPosition) {
                if let mainPin {
                    Annotation("main pin",
                               coordinate: mainPin,
                               anchor: .bottom) {
                        Image(.pin)
                    }
                    .annotationTitles(.hidden)
                }
                //
            }
            .mapStyle(mapStyleName.mapStyle())
            .mapControls {
                MapCompass()
                MapPitchToggle()
                MapScaleView()
                MapZoomStepper()
            }
            .simultaneousGesture(SpatialTapGesture().onEnded { position in
                // mapFocus.wrappedValue = nil  // get rid of any search views
                if let loc = mapProxy.convert(position.location, from: .local) {
                    // TODO
                    // updatePins(loc)
                    print("loc changed to \(loc)")
                }
            })
            .onTapGesture(count: 2) { position in
                if let coords = mapProxy.convert(position, from: .local) {
                    zoom(around: coords)
                }
            }
            .onMapCameraChange(frequency: .onEnd) { context in
                camera = context.camera
                if let distance = camera?.distance {
                    cameraDistance = distance
                }
                mapRect = context.rect
            }
            .onChange(of: mapStyleName) {
                savedMapStyle = mapStyleName.rawValue
            }
            // .onChange(of: masData.searchResult) {
            //     if let searchResult = masData.searchResult {
            //         if !allPins.isEmpty {
            //             // zoom in to better show pin when necessary
            //             if masData.cameraDistance > zoomDistance {
            //                 masData.cameraDistance = zoomDistance
            //             }
            //             updatePins(searchResult.coordinate.coord2D)
            //         } else {
            //             masData.setCameraPosition(to: searchResult.coordinate.coord2D)
            //         }
            //         masData.searchText = ""
            //     }
            // }
            // .onChange(of: mainPin?.location) {
            //     masData.recenterMap(coords: mainPin?.location)
            // }
            .onAppear {
                let center = CLLocationCoordinate2D(
                    latitude: initialMapLatitude,
                    longitude: initialMapLongitude)
                cameraDistance = initialMapDistance
                setCameraPosition(to: center)
                mapStyleName = .init(rawValue: savedMapStyle) ?? .standard
            }
            .task(id: store.mostSelected) {
                print("mostSelected changed")
                if let id = store.mostSelected {
                    mainPin = store[id].metadata.location
                    allPins = store.selection.compactMap {
                        store[$0].metadata.location
                    }
                    recenter(to: mainPin)
                } else {
                    mainPin = nil
                    allPins.removeAll()
                }
            }
        }
    }
}

// Map positioning helper functions

extension MapView {
    // Set the camera position
    func setCameraPosition(to coords: Coords) {
        cameraPosition = .camera(.init(centerCoordinate: coords,
                                       distance: cameraDistance))
    }

    // recenter map if the given coords are not in view
    func recenter(to coords: Coords?) {
        if let coords, let rect = mapRect {
            if !rect.contains(MKMapPoint(coords)) {
                setCameraPosition(to: coords)
            }
        }
    }

    // Zoom in or out by a factor of two
    private func zoom(around coords: CLLocationCoordinate2D, out: Bool = false) {
        if let camera {
            let distance =
                out
                ? camera.distance * 2
                : camera.distance / 2
            withAnimation(.easeInOut) {
                cameraPosition =
                    .camera(.init(centerCoordinate: coords,
                                  distance: distance))
            }
        }
    }
}

// Map View related default keys

extension MapView {
    static let initialMapLatitudeKey = "InitialMapLatitude"
    static let initialMapLongitudeKey = "InitialMapLongitude"
    static let initialMapDistanceKey = "InitialMapDistance"
    static let savedMapStyleKey = "SavedMapStyle"
}
