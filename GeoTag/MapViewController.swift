//
//  MapViewController.swift
//  GeoTag
//
//  Created by Marco S Hyman on 7/17/14.
//  Copyright (c) 2014 Marco S Hyman. All rights reserved.
//

import Cocoa
import MapKit

/// Subclass MKMapView to hook into mouse up events to extract the
/// location of single click events.  I couldn't do this in an extension
/// without breaking three finger drags on a touch pad.

class MapView: MKMapView {
    override func mouseUp(theEvent: NSEvent!) {
        super.mouseUp(theEvent)
        if theEvent.clickCount == 1 {
            let point = convertPoint(theEvent.locationInWindow, fromView: nil)
            let location = convertPoint(point, toCoordinateFromView: self)
            println("Click at \(location.latitude), \(location.longitude)")
            // single click
        }
    }
}

@objc(MapViewController)
class MapViewController: NSViewController, MKMapViewDelegate {
    @IBOutlet var mapView: MapView
    @IBOutlet var mapTypeControl: NSSegmentedControl

    // user defaults keys for map configuration
    let mapTypeKey = "MapType"
    let cameraCenterLatitudeKey = "CameraCenterLatitudeKey"
    let cameraCenterLongitudeKey = "CameraCenterLongitudeKey"
    let cameraAltitudeKey = "CameraAltitudeKey"

    // Only one point on the map at a time (for now, anyway)
    // This is the point
    var mapPoint: MKPointAnnotation?

    /// startup

    override func viewDidLoad() {       // 10.10 and later
        super.viewDidLoad()
    }

    /// Map set-up
    func mapSetup() {
        let defaults = NSUserDefaults.standardUserDefaults()
        mapTypeControl.selectedSegment = defaults.integerForKey(mapTypeKey)
        changeMapType(mapTypeControl)
        // set up map from save info
        var center: CLLocationCoordinate2D
        var altitude = defaults.doubleForKey(cameraAltitudeKey)
        if (altitude > 0) {
            let latitude = defaults.doubleForKey(cameraCenterLatitudeKey)
            let longitude = defaults.doubleForKey(cameraCenterLongitudeKey)
            center = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        } else {
            // hard coded default location (SF peninsula)
            altitude = 50000.0
            center = CLLocationCoordinate2D(latitude: 37.7244, longitude: -122.4381)
        }
        mapView.camera = MKMapCamera(lookingAtCenterCoordinate: center, fromEyeCoordinate: center, eyeAltitude: altitude)
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
            println("Unknown segment item \(type), sender \(sender)")
        }
    }

    // save the current map type and displayed region
    @IBAction func saveMapSetting(AnyObject) {
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
            println("Unknown map type \(type)")
        }
        defaults.setInteger(mapTypeAsInt, forKey: mapTypeKey)

        // save the current region as its component parts
        let currentRegion = mapView.region
        defaults.setDouble(mapView.camera.centerCoordinate.latitude,
            forKey: cameraCenterLatitudeKey)
        defaults.setDouble(mapView.camera.centerCoordinate.longitude,
            forKey: cameraCenterLongitudeKey)
        defaults.setDouble(mapView.camera.altitude,
            forKey: cameraAltitudeKey)
    }

    // center the map as the given latitude/longitude and drop
    // a pin at that location
    func centerMapAtLatitude(latitude: Double, longitude: Double) {
        let center = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        mapView.setCenterCoordinate(center, animated: false)
        removeMapPoint()
        mapPoint = MKPointAnnotation()
        if let point = mapPoint {
            point.coordinate = center;
            mapView.addAnnotation(point)
        }
    }

    func removeMapPoint() {
        if mapPoint {
            mapView.removeAnnotation(mapPoint)
            mapPoint = nil
        }

    }
}
