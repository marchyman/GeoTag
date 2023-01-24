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

    @EnvironmentObject var vm: ViewModel
    @State private var mapPin = MKPointAnnotation()

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
        view.register(PinAnnotationView.self,
                      forAnnotationViewWithReuseIdentifier: MKMapViewDefaultAnnotationViewReuseIdentifier)
        return view
    }

    func updateNSView(_ view: ClickMapView, context: Context) {
        setMapConfiguration(view)

        // handle mostSelected changes
        if vm.mostSelected == nil {
            view.removeAnnotation(mapPin)
            mapPin.coordinate = Coords()
        } else {
            if let location = vm[vm.mostSelected!].location {
                if location != mapPin.coordinate {
                    // location changed
                    view.removeAnnotation(mapPin)
                    mapPin.coordinate = location
                    view.addAnnotation(mapPin)
                    // make sure pin is in view
                    if !view.visibleMapRect.contains(MKMapPoint(mapPin.coordinate)) {
                        // I don't know of a better way?
                        DispatchQueue.main.async {
                            view.setCenter(mapPin.coordinate, animated: false)
                        }
                    }
                }
            } else {
                view.removeAnnotation(mapPin)
                mapPin.coordinate = Coords()
            }
        }

        // handle track changes
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

        // re-center the map
        if reCenter {
            DispatchQueue.main.async {
                view.setCenter(vm.mapCenter, animated: false)
                reCenter = false
            }
        }
    }

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
            if let id = vm.mostSelected,
               (newState == .ending) {
                vm.update(id: id, location: view.annotation!.coordinate)
                vm.undoManager.setActionName("set location (drag)")
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
    static var previews: some View {
        MapView(center: CLLocationCoordinate2D(latitude: 37.7244,
                                               longitude: -122.4381),
                altitude: 50000.0,
                reCenter: .constant(false))
            .environmentObject(ViewModel())
    }
}
#endif
