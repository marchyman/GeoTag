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
    @EnvironmentObject var vm: AppViewModel
    @ObservedObject var mapViewModel = MapViewModel.shared

    let center: CLLocationCoordinate2D
    let altitude: Double

    func makeCoordinator() -> MapView.Coordinator {
        Coordinator(vm: vm)
    }

    func makeNSView(context: Context) -> ClickMapView {
        let view = ClickMapView(frame: .zero)
        view.viewModel = vm
        view.delegate = context.coordinator
        view.camera = MKMapCamera(lookingAtCenter: center,
                                 fromEyeCoordinate: center,
                                 eyeAltitude: altitude)
        view.showsCompass = true
        return view
    }

    func updateNSView(_ view: ClickMapView, context: Context) {
        setMapConfiguration(view)
        mainPinChanges(for: view)
        otherPinChanges(for: view)
        trackChanges(for: view)

        // re-center the map
        if mapViewModel.reCenter {
            DispatchQueue.main.async {
                view.setCenter(mapViewModel.currentMapCenter, animated: false)
                mapViewModel.reCenter = false
            }
        }
    }

    // Change the look of the map

    func setMapConfiguration(_ view: ClickMapView) {
        switch mapViewModel.mapConfiguration {
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

    // map pin changes for the most selected item

    func mainPinChanges(for view: ClickMapView) {
        // Nothing to do if there is no main pin. This is OK as any exising
        // pin view will be removed when processing other pin changes.
        if mapViewModel.mainPin == nil {
            return
        }

        // Add a new annotation for mainPin.  Testing shows that this replaces
        // any existing annotation for the pin.
        view.addAnnotation(mapViewModel.mainPin!)

        // make sure pin is in view
        if !view.visibleMapRect.contains(MKMapPoint(mapViewModel.mainPin!.coordinate)) {
            // I don't know of a better way?
            DispatchQueue.main.async {
                view.setCenter(mapViewModel.mainPin!.coordinate, animated: false)
            }
        }
    }

    // other pin changes

    func otherPinChanges(for view: ClickMapView) {
        let oldAnnotations: [MKAnnotation]

        if mapViewModel.onlyMostSelected || mapViewModel.otherPins.isEmpty {
            // remove all annotation save any that match the main pin
            oldAnnotations = view.annotations.filter {
                $0.coordinate != mapViewModel.mainPin?.coordinate
            }
        } else {
            // ignore other pins on top of the main pin
            view.addAnnotations(mapViewModel.otherPins.filter {
                $0.coordinate != mapViewModel.mainPin?.coordinate
            })

            // now remove any annotations for items no longer selected
            var known = Set(mapViewModel.otherPins)

            // if the most selected item has a location add its pin
            // to the set of known pins
            if mapViewModel.mainPin != nil {
                known.insert(mapViewModel.mainPin!)
            }

            oldAnnotations = view.annotations.filter {
                known.insert($0 as! MKPointAnnotation).inserted
            }
        }
        if !oldAnnotations.isEmpty {
            view.removeAnnotations(oldAnnotations)
        }
   }

    // draw tracks on the map when needed

    func trackChanges(for view: ClickMapView) {
        if mapViewModel.refreshTracks {
            let overlays = view.overlays
            if !overlays.isEmpty {
                view.removeOverlays(overlays)
            }
            view.addOverlays(mapViewModel.mapLines)
            if let span = mapViewModel.mapSpan {
                // I still don't know of a better way?
                DispatchQueue.main.async {
                    view.setRegion(MKCoordinateRegion(center: mapViewModel.currentMapCenter,
                                                      span: span),
                                   animated: false)
                    mapViewModel.refreshTracks = false
                }
            }
        }
    }
}

// coordinator/delegate

extension MapView {

    // Coordinator class conforming to MKMapViewDelegate

    class Coordinator: NSObject, MKMapViewDelegate {
        @ObservedObject var mapViewModel = MapViewModel.shared
        @ObservedObject var vm: AppViewModel

        init(vm: AppViewModel) {
            self.vm = vm
        }

        // view for annnotation.

        func mapView(_ mapView: MKMapView,
                     viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            if (annotation is MKUserLocation) {
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
            mapViewModel.currentMapCenter = mapView.camera.centerCoordinate
            mapViewModel.currentMapAltitude = mapView.camera.altitude
        }

        // update the location of a dragged pin

        @MainActor
        func mapView(_ mapView: MKMapView,
                     annotationView view: MKAnnotationView,
                     didChange newState: MKAnnotationView.DragState,
                     fromOldState oldState: MKAnnotationView.DragState) {
            if let id = vm.mostSelected {
                switch newState {
                case .starting:
                    view.image = NSImage(named: "DragPin")
                    break
                case .ending:
                    view.image = NSImage(named: "Pin")
                    vm.update(id: id, location: view.annotation!.coordinate)
                    vm.undoManager.setActionName("set location (drag)")
                default:
                    break
                }
            }
        }

        // draw lines on the map
        
        @MainActor
        func mapView(_ mapview: MKMapView,
                     rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            let polyline = overlay as! MKPolyline
            if mapViewModel.mapLines.contains(polyline) {
                let renderer = MKPolylineRenderer(polyline: polyline)
                renderer.strokeColor = NSColor(mapViewModel.trackColor)
                renderer.lineWidth = CGFloat(mapViewModel.trackWidth)
                return renderer
            }
            return MKOverlayRenderer(overlay: overlay)
        }
    }
}

#if DEBUG
struct MapView_Previews : PreviewProvider {
    static var previews: some View {
        MapView(center: CLLocationCoordinate2D(latitude: 37.7244,
                                               longitude: -122.4381),
                altitude: 50000.0)
            .environmentObject(AppViewModel())
    }
}
#endif
