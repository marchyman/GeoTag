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
    @AppStorage(Self.showOtherPinsKey) var showOtherPins = false

    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var cameraDistance: Double = 0
    @State private var mapRect: MKMapRect?
    @State private var camera: MapCamera?
    @State private var mapStyleName: MapStyleName = .standard
    @State private var mainPin: Coords?
    @State private var otherPins: [OtherPin] = []

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
                if showOtherPins {
                    ForEach(otherPins) { pin in
                        Annotation("other pin",
                                   coordinate: pin.location,
                                   anchor: .bottom ) {
                            Image(.otherPin)
                        }
                        .annotationTitles(.hidden)
                    }
                }
                // ForEach(masData.tracks) { track in
                //     MapPolyline(coordinates: track.coords)
                //         .stroke(
                //             masData.trackColor,
                //             lineWidth: masData.trackWidth)
                // }
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
                if let id = store.mostSelected {
                    if let loc = mapProxy.convert(position.location, from: .local) {
                        store.send(.locationChanged(loc),
                                   description: "map click") {
                            // remember the current selection
                            let selected = store.selection
                            Task {
                                let address =
                                await ReverseLocationFinder.reverseGeocode(store: store,
                                                                           id: id)
                                if let address {
                                    store.send(.addressChanged(selected, address)) {
                                        store.discardUndo()
                                    }
                                }
                            }
                        }
                    }
                }
            })
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
            .onChange(of: mainPin) { recenter(to: mainPin) }
            .onAppear {
                let center = CLLocationCoordinate2D(
                    latitude: initialMapLatitude,
                    longitude: initialMapLongitude)
                cameraDistance = initialMapDistance
                setCameraPosition(to: center)
                mapStyleName = .init(rawValue: savedMapStyle) ?? .standard
            }
            .task(id: store.mostSelected) {
                if let id = store.mostSelected {
                    mainPin = store[id].metadata.location
                    otherPins = store.selection.compactMap {
                        OtherPin(store[$0].metadata.location)
                    }
                    .filter { $0.location != nil && $0.location != mainPin }
                } else {
                    mainPin = nil
                    otherPins.removeAll()
                }
            }
        }
    }
}

// Map positioning helper functions

extension MapView {

    struct OtherPin: Identifiable {
        let id = UUID()
        let location: Coords

        init?(_ location: Coords?) {
            guard let location else { return nil }
            self.location = location
        }
    }

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
}

// Map View related default keys

extension MapView {
    static let initialMapLatitudeKey = "InitialMapLatitude"
    static let initialMapLongitudeKey = "InitialMapLongitude"
    static let initialMapDistanceKey = "InitialMapDistance"
    static let savedMapStyleKey = "SavedMapStyle"
    static let showOtherPinsKey = "ShowOtherPins"
}
