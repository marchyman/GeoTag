//
//  MapViewController.swift
//  GeoTag
//
//  Created by Marco S Hyman on 7/17/14.
//  Copyright (c) 2014, 2016 Marco S Hyman. All rights reserved.
//

import Cocoa
import MapKit

@objc
class MapViewController: NSViewController {
    var clickDelegate: MapViewDelegate?

    @IBOutlet var mapView: MapView!
    @IBOutlet var mapTypeControl: NSSegmentedControl!

    // user defaults keys for map configuration
    let mapTypeKey = "MapType"
    let cameraCenterLatitudeKey = "CameraCenterLatitudeKey"
    let cameraCenterLongitudeKey = "CameraCenterLongitudeKey"
    let cameraAltitudeKey = "CameraAltitudeKey"

    // program mapping between MKMapType and segment control selected segment
    let mapTypeStandard = 0
    let mapTypeHybrid = 1
    let mapTypeSatellite = 2

    // Only one point on the map at a time (for now, anyway)
    // This is the point
    var mapPin: MKPointAnnotation?

    /// startup

    // 10.10 and later
    @available(OSX 10.10, *)
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    // final initialization for the mapView
    override func awakeFromNib() {
        let defaults = UserDefaults.standard
        mapTypeControl.selectedSegment = defaults.integer(forKey: mapTypeKey)
        changeMapType(mapTypeControl)
        // set up map from save info
        var center: CLLocationCoordinate2D
        var altitude = defaults.double(forKey: cameraAltitudeKey)
        if (altitude > 0) {
            let latitude = defaults.double(forKey: cameraCenterLatitudeKey)
            let longitude = defaults.double(forKey: cameraCenterLongitudeKey)
            center = CLLocationCoordinate2D(latitude: latitude,
                                            longitude: longitude)
        } else {
            // hard coded default location (SF peninsula)
            altitude = 50000.0
            center = CLLocationCoordinate2D(latitude: 37.7244,
                                            longitude: -122.4381)
        }
        mapView.camera = MKMapCamera(lookingAtCenter: center,
                                     fromEyeCoordinate: center,
                                     eyeAltitude: altitude)
    }

    /// Map control actions

    // select the desired map type
    @IBAction func changeMapType(_ sender: NSSegmentedControl) {
        switch sender.selectedSegment {
        case mapTypeStandard:
            mapView.mapType = .standard
        case mapTypeHybrid:
            mapView.mapType = .hybrid
        case mapTypeSatellite:
            mapView.mapType = .satellite
        case let type:
            print("Unknown segment item \(type), sender \(sender)")
        }
    }

    // save the current map type and displayed region
    @IBAction func saveMapSetting(_: AnyObject) {
        let defaults = UserDefaults.standard
        var mapTypeAsInt = 0
        switch mapView.mapType {
        case .standard:
            mapTypeAsInt = mapTypeStandard
        case .hybrid:
            mapTypeAsInt = mapTypeHybrid
        case .satellite:
            mapTypeAsInt = mapTypeSatellite
        case let type:
            print("Unknown map type \(type)")
        }
        defaults.set(mapTypeAsInt, forKey: mapTypeKey)

        // save the current region as its component parts
        defaults.set(mapView.camera.centerCoordinate.latitude,
                     forKey: cameraCenterLatitudeKey)
        defaults.set(mapView.camera.centerCoordinate.longitude,
                     forKey: cameraCenterLongitudeKey)
        defaults.set(mapView.camera.altitude,
                     forKey: cameraAltitudeKey)
    }

    // center the map as the given latitude/longitude and drop
    // a pin at that location
    func pinMapAt(latitude: Double, longitude: Double) {
        let location = CLLocationCoordinate2D(latitude: latitude,
                                              longitude: longitude)
        let point = MKMapPointForCoordinate(location);
        if !MKMapRectContainsPoint(mapView.visibleMapRect, point) {
            mapView.setCenter(location, animated: false)
        }
        // if a pin exists, move it.  Otherwise create a new pin
        if let pin = mapPin {
            pin.coordinate = location;
        } else {
            mapPin = MKPointAnnotation()
            if let pin = mapPin {
                pin.coordinate = location;
                mapView.addAnnotation(pin)
            }
        }
    }

    // remove the pin from the map
    func removeMapPin() {
        if let pin = mapPin {
            mapView.removeAnnotation(pin)
            mapPin = nil
        }
    }


}


// Mark: MKMapView Delegate functions

extension MapViewController: MKMapViewDelegate {
    // return a pinAnnotationView for a red pin
    func mapView(_ mapView: MKMapView,
                 viewFor annotation: MKAnnotation) -> MKAnnotationView? {

        let identifier = "pinAnnotation"
        var annotationView: MKPinAnnotationView!
        annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKPinAnnotationView
        if (annotationView != nil) {
            // is this correct?
            annotationView.annotation = annotation
        } else {
            annotationView = MKPinAnnotationView(annotation: annotation,
                                                 reuseIdentifier: identifier)
        }
        annotationView.pinColor = .red;
        annotationView.animatesDrop = false
        annotationView.canShowCallout = false
        annotationView.isDraggable = true
        return annotationView
    }

    // A pin is being dragged.
    func mapView(_ mapView: MKMapView,
                 annotationView: MKAnnotationView,
                 didChange newState: MKAnnotationViewDragState,
                 fromOldState oldState: MKAnnotationViewDragState) {
        if newState == .ending {
            clickDelegate?.mouseClicked(mapView: nil,
                                               location: annotationView.annotation!.coordinate)
         }
    }
}
