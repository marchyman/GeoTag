//
//  MapView.swift
//
//  Created by Marco S Hyman on 6/24/19.
//

import SwiftUI
import MapKit

// MKMapView exposed to SwiftUI
//
// swiftui MapView does not yet do everthing needed by GeoTag.
// Stick with this version for now.

struct MapView: NSViewRepresentable {
    @Environment(AppState.self) var state
    var mvm = MapViewModel.shared

    @AppStorage(AppSettings.mapConfigurationKey)  var mapConfiguration = 0

    let center: CLLocationCoordinate2D
    let altitude: Double

    func makeCoordinator() -> MapView.Coordinator {
        Coordinator(state: state)
    }

    func makeNSView(context: Context) -> ClickMapView {
        let view = ClickMapView(frame: .zero)
        view.state = state
        view.delegate = context.coordinator
        view.camera = MKMapCamera(lookingAtCenter: center,
                                  fromEyeCoordinate: center,
                                  eyeAltitude: altitude)
        view.showsCompass = true
        return view
    }

    func updateNSView(_ view: ClickMapView, context: Context) {
        let interval = state.markStart("updateMapView")
        defer { state.markEnd("updateMapView", interval: interval) }
        setMapConfiguration(view)
        pins(for: state.tvm.mostSelected, and: state.tvm.selected, on: view)
        trackChanges(for: view)

        // re-center the map
        if mvm.reCenter {
            DispatchQueue.main.async {
                mvm.reCenter = false
                view.setCenter(mvm.currentMapCenter, animated: false)
            }
        }
    }

    // Change the look of the map

    func setMapConfiguration(_ view: ClickMapView) {
        switch mapConfiguration {
        case 0:
            view.preferredConfiguration = MKStandardMapConfiguration()
        case 1:
            view.preferredConfiguration = MKHybridMapConfiguration()
        case 2:
            view.preferredConfiguration = MKImageryMapConfiguration()
        default:
            break
        }
    }

    // Make pin annotations and place them on the map, removing any
    // existing pin annotations.
    func pins(for image: ImageModel?,
              and images: [ImageModel],
              on view: ClickMapView) {
        // delete existing pin annotations on the map view
        let annotations = view.annotations
        if !annotations.isEmpty {
            view.removeAnnotations(annotations)
        }

        // Update main pin (if one exists) location.
        if let image,
           let location = image.location {
            // always update pin as the view, Pin vs OtherPin, may have changed
            // example: deselecting the image associated with mainPin may
            // cause a pin currently displayed as an OtherPin to be selected
            // as the main pin.
            if mvm.mainPin == nil {
                mvm.mainPin = MKPointAnnotation()
            }
            mvm.mainPin?.title = "Pin"
            mvm.mainPin?.coordinate = location
            view.addAnnotation(mvm.mainPin!)
            if !view.visibleMapRect.contains(MKMapPoint(mvm.mainPin!.coordinate)) {
                // I don't know of a better way?
                DispatchQueue.main.async {
                    view.setCenter(mvm.mainPin!.coordinate, animated: false)
                }
            }
        } else {
            mvm.mainPin = nil
        }

        if !mvm.onlyMostSelected {
            // Make pins for other selected items but only if their coordinates
            // are different from mainPin
            var pins = [MKPointAnnotation]()
            for other in images.filter({ $0 != state.tvm.mostSelected
                && $0.location != nil
                && $0.location != image?.location}) {
                let pin = MKPointAnnotation()
                pin.title = "OtherPin"
                pin.coordinate = other.location!
                pins.append(pin)
            }

            // add annotations for "OtherPin"s when enabled
            view.addAnnotations(pins)
        }
    }

    // draw tracks on the map when needed

    func trackChanges(for view: ClickMapView) {
        if mvm.refreshTracks {
            let overlays = view.overlays
            if !overlays.isEmpty {
                view.removeOverlays(overlays)
            }
            view.addOverlays(mvm.mapLines)
            if let span = mvm.mapSpan {
                // I still don't know of a better way?
                DispatchQueue.main.async {
                    view.setRegion(MKCoordinateRegion(center: mvm.currentMapCenter,
                                                      span: span),
                                   animated: false)
                    mvm.refreshTracks = false
                }
            }
        }
    }
}

// coordinator/delegate

extension MapView {

    // Coordinator class conforming to MKMapViewDelegate

    class Coordinator: NSObject, MKMapViewDelegate {
        var mvm = MapViewModel.shared
        var state: AppState

        init(state: AppState) {
            self.state = state
        }

        // view for annnotation.

        func mapView(_ mapView: MKMapView,
                     viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            if annotation is MKUserLocation {
                return nil
            }
            let id = annotation.title?.flatMap { $0 } ?? "unknown"
            var view = mapView.dequeueReusableAnnotationView(withIdentifier: id)
            if view == nil {
                view = PinAnnotationView(annotation: annotation,
                                         reuseIdentifier: id)
            }
            return view
        }

        // track mapView center coordinate

        @MainActor
        func mapViewDidChangeVisibleRegion(_ mapView: MKMapView) {
            mvm.currentMapCenter = mapView.camera.centerCoordinate
            mvm.currentMapAltitude = mapView.camera.altitude
        }

        // update the location of a dragged pin

        @MainActor
        func mapView(_ mapView: MKMapView,
                     annotationView view: MKAnnotationView,
                     didChange newState: MKAnnotationView.DragState,
                     fromOldState oldState: MKAnnotationView.DragState) {
            if let image = state.tvm.mostSelected {
                switch newState {
                case .starting:
                    view.image = NSImage(named: "DragPin")
                case .ending:
                    view.image = NSImage(named: "Pin")
                    state.update(image, location: view.annotation!.coordinate)
                    state.undoManager.setActionName("set location (drag)")
                default:
                    break
                }
            }
        }

        // draw lines on the map

        @MainActor
        func mapView(_ mapview: MKMapView,
                     rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            @AppStorage(AppSettings.trackColorKey) var trackColor: Color = .blue
            @AppStorage(AppSettings.trackWidthKey) var trackWidth: Double = 0.0

            // swiftlint:disable force_cast
            let polyline = overlay as! MKPolyline
            // swiftlint:enable force_cast
            if mvm.mapLines.contains(polyline) {
                let renderer = MKPolylineRenderer(polyline: polyline)
                renderer.strokeColor = NSColor(trackColor)
                renderer.lineWidth = CGFloat(trackWidth)
                return renderer
            }
            return MKOverlayRenderer(overlay: overlay)
        }
    }
}

#if DEBUG
struct MapView_Previews: PreviewProvider {
    static var previews: some View {
        MapView(center: CLLocationCoordinate2D(latitude: 37.7244,
                                               longitude: -122.4381),
                altitude: 50000.0)
            .environment(AppState())
    }
}
#endif
