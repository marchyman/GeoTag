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
    @AppStorage(AppSettings.mapConfigurationKey) var mapConfiguration = 0

    let center: CLLocationCoordinate2D
    let altitude: Double
    @Binding var reCenter: Bool
    @Binding var mainPin: MKPointAnnotation?
    @Binding var otherPins: [MKPointAnnotation]

    @EnvironmentObject var vm: ViewModel

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
        if !vm.onlyMostSelected {
            otherPinChanges(for: view)
        }
        trackChanges(for: view)

        // re-center the map
        if reCenter {
            DispatchQueue.main.async {
                view.setCenter(vm.mapCenter, animated: false)
                reCenter = false
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

    // map pin changes for the most selected item

    func mainPinChanges(for view: ClickMapView) {
        // remove all annotations if there is no pin to place
        if mainPin == nil {
            let annotations = view.annotations
            if !annotations.isEmpty {
                view.removeAnnotations(annotations)
            }
            return
        }

        // Add a new annotation for mainPin.  Testing shows that this replaces
        // any existing annotation for the pin.
        view.addAnnotation(mainPin!)

        // make sure pin is in view
        if !view.visibleMapRect.contains(MKMapPoint(mainPin!.coordinate)) {
            // I don't know of a better way?
            DispatchQueue.main.async {
                view.setCenter(mainPin!.coordinate, animated: false)
            }
        }
    }

    // other pin changes

    func otherPinChanges(for view: ClickMapView) {
        let oldAnnotations: [MKAnnotation]

        if otherPins.isEmpty {
            // remove all annotation save any that match the main pin
            oldAnnotations = view.annotations.filter {
                $0.coordinate != mainPin?.coordinate
            }
        } else {
            // ignore other pins on top of the main pin
            view.addAnnotations(otherPins.filter {
                $0.coordinate != mainPin?.coordinate
            })
            // now remove any annotations for items no longer selected
            var known = Set(otherPins)
            known.insert(mainPin!)
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
        if vm.refreshTracks {
            let overlays = view.overlays
            if !overlays.isEmpty {
                view.removeOverlays(overlays)
            }
            view.addOverlays(vm.mapLines)
            if let span = vm.mapSpan {
                // I still don't know of a better way?
                DispatchQueue.main.async {
                    view.setRegion(MKCoordinateRegion(center: vm.mapCenter,
                                                      span: span),
                                   animated: false)
                    vm.refreshTracks = false
                }
            }
        }
    }
}

extension MapView {

    // Coordinator class conforming to MKMapViewDelegate

    class Coordinator: NSObject, MKMapViewDelegate {
        @AppStorage(AppSettings.trackColorKey) var trackColor: Color = .blue
        @AppStorage(AppSettings.trackWidthKey) var trackWidth: Double = 0.0
        let vm: ViewModel

        init(vm: ViewModel) {
            self.vm = vm
        }

        // view for annnotation.  I tried registering the pin view in
        // makeNSVeiw but it didn't pass in the annotation so I couldn't
        // tell which image type to assign.

        func mapView(_ mapView: MKMapView,
                     viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            if (annotation is MKUserLocation) {
                return nil
            }
            let identifier = annotation.title == nil ? "main" : "other"
            var view = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)

            if view == nil {
                view = PinAnnotationView(annotation: annotation,
                                         reuseIdentifier: identifier)
            }
            return view
        }


        // track mapView center coordinate

        @MainActor
        func mapViewDidChangeVisibleRegion(_ mapView: MKMapView) {
            vm.mapCenter = mapView.camera.centerCoordinate
            vm.mapAltitude = mapView.camera.altitude
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
            if vm.mapLines.contains(polyline) {
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
struct MapView_Previews : PreviewProvider {
    @State static var mainPin: MKPointAnnotation?
    @State static var otherPins = [MKPointAnnotation]()

    static var previews: some View {
        MapView(center: CLLocationCoordinate2D(latitude: 37.7244,
                                               longitude: -122.4381),
                altitude: 50000.0,
                reCenter: .constant(false),
                mainPin: $mainPin,
                otherPins: $otherPins)
            .environmentObject(ViewModel())
    }
}
#endif
