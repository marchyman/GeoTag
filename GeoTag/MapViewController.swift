//
//  MapViewController.swift
//  GeoTag
//
//  Created by Marco S Hyman on 7/17/14.
//  Copyright (c) 2014, 2016 Marco S Hyman. All rights reserved.
//

import Cocoa
import MapKit

@objc(MapViewController)
class MapViewController: NSViewController {
    var clickDelegate: MapViewDelegate?

    @IBOutlet var mapView: MapView!
    @IBOutlet var mapTypeControl: NSSegmentedControl!

    // user defaults keys for map configuration
    let mapTypeKey = "MapType"
    let cameraCenterLatitudeKey = "CameraCenterLatitudeKey"
    let cameraCenterLongitudeKey = "CameraCenterLongitudeKey"
    let cameraAltitudeKey = "CameraAltitudeKey"

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
        let defaults = NSUserDefaults.standardUserDefaults()
        mapTypeControl.selectedSegment = defaults.integerForKey(mapTypeKey)
        changeMapType(mapTypeControl)
        // set up map from save info
        var center: CLLocationCoordinate2D
        var altitude = defaults.doubleForKey(cameraAltitudeKey)
        if (altitude > 0) {
            let latitude = defaults.doubleForKey(cameraCenterLatitudeKey)
            let longitude = defaults.doubleForKey(cameraCenterLongitudeKey)
            center = CLLocationCoordinate2D(latitude: latitude,
                                            longitude: longitude)
        } else {
            // hard coded default location (SF peninsula)
            altitude = 50000.0
            center = CLLocationCoordinate2D(latitude: 37.7244,
                                            longitude: -122.4381)
        }
        mapView.camera = MKMapCamera(lookingAtCenterCoordinate: center,
                                     fromEyeCoordinate: center,
                                     eyeAltitude: altitude)
    }

    /// Map control actions

    // select the desired map type
    @IBAction func changeMapType(sender: NSSegmentedControl) {
        switch sender.selectedSegment {
        case 0:
            mapView.mapType = .Standard
        case 1:
            mapView.mapType = .Hybrid
        case 2:
            mapView.mapType = .Satellite
        case let type:
            print("Unknown segment item \(type), sender \(sender)")
        }
    }

    // save the current map type and displayed region
    @IBAction func saveMapSetting(_: AnyObject) {
        let defaults = NSUserDefaults.standardUserDefaults()
        var mapTypeAsInt = 0
        switch mapView.mapType {
        case .Standard:
            mapTypeAsInt = 0
        case .Hybrid:
            mapTypeAsInt = 1
        case .Satellite:
            mapTypeAsInt = 2
        case let type:
            print("Unknown map type \(type)")
        }
        defaults.setInteger(mapTypeAsInt, forKey: mapTypeKey)

        // save the current region as its component parts
//        let currentRegion = mapView.region
        defaults.setDouble(mapView.camera.centerCoordinate.latitude,
            forKey: cameraCenterLatitudeKey)
        defaults.setDouble(mapView.camera.centerCoordinate.longitude,
            forKey: cameraCenterLongitudeKey)
        defaults.setDouble(mapView.camera.altitude,
            forKey: cameraAltitudeKey)
    }

    // center the map as the given latitude/longitude and drop
    // a pin at that location
    func pinMapAtLatitude(latitude: Double, longitude: Double) {
        let location = CLLocationCoordinate2D(latitude: latitude,
                                              longitude: longitude)
        let point = MKMapPointForCoordinate(location);
        if !MKMapRectContainsPoint(mapView.visibleMapRect, point) {
            mapView.setCenterCoordinate(location, animated: false)
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
    func mapView(mapView: MKMapView,
                 viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {

        let identifier = "pinAnnotation"
        var annotationView: MKPinAnnotationView!
        annotationView = mapView.dequeueReusableAnnotationViewWithIdentifier(identifier) as? MKPinAnnotationView
        if (annotationView != nil) {
            // is this correct?
            annotationView.annotation = annotation
        } else {
            annotationView = MKPinAnnotationView(annotation: annotation,
                                                 reuseIdentifier: identifier)
        }
        annotationView.pinColor = .Red;
        annotationView.animatesDrop = false
        annotationView.canShowCallout = false
        annotationView.draggable = true
        return annotationView
    }

    // A pin is being dragged.
    func mapView(mapView: MKMapView,
                 annotationView: MKAnnotationView,
                 didChangeDragState newState: MKAnnotationViewDragState,
                 fromOldState oldState: MKAnnotationViewDragState) {
        if newState == .Ending {
            clickDelegate?.mapViewMouseClicked(nil,
                                               location: annotationView.annotation!.coordinate)
         }
    }
}
