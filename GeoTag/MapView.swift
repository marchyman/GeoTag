//
//  MapView.swift
//
//  Created by Marco S Hyman on 6/24/19.
//  Copyright © 2019,2021 Marco S Hyman. All rights reserved.
//
// Permission is hereby granted, free of charge, to any person obtaining a
// copy of this software and associated documentation files (the "Software"),
// to deal in the Software without restriction, including without limitation
// the rights to use, copy, modify, merge, publish, distribute, sublicense,
// and/or sell copies of the Software, and to permit persons to whom the
// Software is furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
// THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
// FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
// DEALINGS IN THE SOFTWARE.
//

import SwiftUI
import MapKit


// MKMapView exposed to SwiftUI
//
// swiftui MapView does not yet do everthing needed by GeoTag.
// Stick with this version for now.
//
struct MapView: NSViewRepresentable {
    static var view: MKMapView!
    let mapType: MKMapType
    let center: CLLocationCoordinate2D
    let altitude: Double
    @EnvironmentObject var vm: AppState

    func makeCoordinator() -> MapView.Coordinator {
        Coordinator(vm: vm)
    }

    func makeNSView(context: Context) -> ClickMapView {
        let view = ClickMapView(frame: .zero)
        MapView.view = view
        view.viewModel = vm
        view.delegate = context.coordinator
        view.camera = MKMapCamera(lookingAtCenter: center,
                                 fromEyeCoordinate: center,
                                 eyeAltitude: altitude)
        view.showsCompass = true
        return view
    }

    func updateNSView(_ view: ClickMapView, context: Context) {
        view.mapType = mapType
        if vm.pinEnabled, let pin = vm.pin {
            view.addAnnotation(pin)
        }
        if !vm.pinEnabled && vm.pin != nil {
            view.removeAnnotation(vm.pin!)
        }
        if vm.refreshTracks {
            let overlays = view.overlays
            if !overlays.isEmpty {
                view.removeOverlays(overlays)
            }
            view.addOverlays(vm.mapLines)
            if let center = vm.mapCenter, let span = vm.mapSpan {
                view.setRegion(MKCoordinateRegion(center: center,
                                                  span: span),
                               animated: false)
            }
        }
    }
}

extension MapView {

    /// Coordinator class conforming to MKMapViewDelegate
    ///
    class Coordinator: NSObject, MKMapViewDelegate {
        @AppStorage(AppSettings.trackColorKey) var trackColor: Color = .blue
        @AppStorage(AppSettings.trackWidthKey) var trackWidth: Double = 0.0
        let vm: AppState

        init(vm: AppState) {
            self.vm = vm
        }

        /// return a pinAnnotationView for a red pin
        ///
        func mapView(_ mapView: MKMapView,
                     viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            let identifier = "pinAnnotation"
            var annotationView =
                mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKPinAnnotationView
            if annotationView != nil {
                annotationView!.annotation = annotation
            } else {
                annotationView = MKPinAnnotationView(annotation: annotation,
                                                        reuseIdentifier: identifier)
                if let av = annotationView {
                    av.isEnabled = true
                    av.pinTintColor = .red
                    av.canShowCallout = false
                    av.isDraggable = true
                } else {
                    fatalError("Can't create MKPinAnnotationView")
                }
            }
            return annotationView
        }

        /// update the location of a dragged pin
        ///
        @MainActor
        func mapView(_ mapView: MKMapView,
                     annotationView view: MKAnnotationView,
                     didChange newState: MKAnnotationView.DragState,
                     fromOldState oldState: MKAnnotationView.DragState) {
            if let id = vm.mostSelected,
               (newState == .ending) {
                vm.update(id: id, location: view.annotation!.coordinate)
            }
        }

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
        MapView(mapType: .standard,
               center: CLLocationCoordinate2D(latitude: 37.7244,
                                            longitude: -122.4381),
               altitude: 50000.0)
            .environmentObject(AppState())
    }
}
#endif
