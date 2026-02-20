import MapKit
import SwiftUI

struct MapView: View {
    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var cameraDistance: Double = 0
    @State private var mapRect: MKMapRect?
    @State private var camera: MapCamera?
    @State private var mapStyleName: MapStyleName = .standard

    @AppStorage(Self.initialMapLatitudeKey) var initialMapLatitude = 37.7244
    @AppStorage(Self.initialMapLongitudeKey) var initialMapLongitude = -122.4381
    @AppStorage(Self.initialMapDistanceKey) var initialMapDistance = 50_000.0
    @AppStorage(Self.savedMapStyleKey) var savedMapStyle = MapStyleName.standard.rawValue

    var body: some View {
        MapReader { mapProxy in
            Map(position: $cameraPosition) {
                //
            }
            //.mapStyle(mapStyleName.mapStyle)
            .mapControls {
                MapCompass()
                MapPitchToggle()
                MapScaleView()
                MapZoomStepper()
            }
            // .simultaneousGesture(SpatialTapGesture().onEnded { position in
            //     mapFocus.wrappedValue = nil  // get rid of any search views
            //     if let loc = mapProxy.convert(position.location, from: .local) {
            //         updatePins(loc)
            //     }
            // })
            // // needed for macOS 16 and earlier
            // .gesture(zoomOut)
            // .onTapGesture(count: 2) { position in
            //     if let coords = mapProxy.convert(position, from: .local) {
            //         zoom(around: coords)
            //     }
            // }
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
                cameraPosition =
                    .camera(
                        .init(
                            centerCoordinate: center,
                            distance: cameraDistance))
                mapStyleName = .init(rawValue: savedMapStyle) ?? .standard
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
