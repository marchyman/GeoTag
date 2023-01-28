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
    @ObservedObject var mvm = MapViewModel.shared

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
        if mvm.reCenter {
            DispatchQueue.main.async {
                view.setCenter(mvm.currentMapCenter, animated: false)
                mvm.reCenter = false
            }
        }
    }

    // Change the look of the map

    func setMapConfiguration(_ view: ClickMapView) {
        switch mvm.mapConfiguration {
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
        if mvm.mainPin == nil {
            return
        }

        // Add a new annotation for mainPin.  Testing shows that this replaces
        // any existing annotation for the pin.
        view.addAnnotation(mvm.mainPin!)
        print("Pin at \(mvm.mainPin!.coordinate)")

        // make sure pin is in view
        if !view.visibleMapRect.contains(MKMapPoint(mvm.mainPin!.coordinate)) {
            // I don't know of a better way?
            DispatchQueue.main.async {
                view.setCenter(mvm.mainPin!.coordinate, animated: false)
            }
        }
    }

    // other pin changes

    func otherPinChanges(for view: ClickMapView) {
        let oldAnnotations: [MKAnnotation]

        if mvm.onlyMostSelected || mvm.otherPins.isEmpty {
            // remove all annotation save any that match the main pin
            oldAnnotations = view.annotations.filter {
                $0.coordinate != mvm.mainPin?.coordinate
            }
        } else {
            // ignore other pins on top of the main pin
            view.addAnnotations(mvm.otherPins.filter {
                $0.coordinate != mvm.mainPin?.coordinate
            })

            // now remove any annotations for items no longer selected
            var known = Set(mvm.otherPins)

            // if the most selected item has a location add its pin
            // to the set of known pins
            if mvm.mainPin != nil {
                known.insert(mvm.mainPin!)
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
        @ObservedObject var mvm = MapViewModel.shared
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
            mvm.currentMapCenter = mapView.camera.centerCoordinate
            mvm.currentMapAltitude = mapView.camera.altitude
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
            if mvm.mapLines.contains(polyline) {
                let renderer = MKPolylineRenderer(polyline: polyline)
                renderer.strokeColor = NSColor(mvm.trackColor)
                renderer.lineWidth = CGFloat(mvm.trackWidth)
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
