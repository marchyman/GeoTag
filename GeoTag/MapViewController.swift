//
//  MapViewController.swift
//  GeoTag
//
//  Created by Marco S Hyman on 7/17/14.
//  Copyright (c) 2014 Marco S Hyman. All rights reserved.
//

import Cocoa
import MapKit

@objc(MapViewController)
class MapViewController: NSViewController, MKMapViewDelegate {
    @IBOutlet var mapView: MKMapView
    @IBOutlet var mapTypeControl: NSSegmentedControl

    let mapTypeKey = "MapType"
    let mapRegionCenterLatitudeKey = "MapRegionCenterLatitude"
    let mapRegionCenterLongitudeKey = "MapRegionCenterLongitude"
    let mapRegionSpanLatitudeDeltaKey = "MapRegionSpanLatitudeDelta"
    let mapRegionSpanLongitudeDeltaKey = "MapRegionSpanLongitudeDelta"

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
        let latitude = defaults.doubleForKey(mapRegionCenterLatitudeKey)
        let longitude = defaults.doubleForKey(mapRegionCenterLongitudeKey)
        let center = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        let latitudeDelta = defaults.doubleForKey(mapRegionSpanLatitudeDeltaKey)
        let longitudeDelta = defaults.doubleForKey(mapRegionSpanLongitudeDeltaKey)
        // if either latitude or longitude delta is 0 don't bother
        if latitudeDelta == 0 || longitudeDelta == 0 {
            return
        }
        let span = MKCoordinateSpanMake(latitudeDelta, longitudeDelta)
        let region = MKCoordinateRegionMake(center, span)
        mapView.region = region
    }

    /// Map control actions

    // select the desired map type
    @IBAction func changeMapType(sender: NSSegmentedControl) {
        switch sender.selectedSegment {
        case 0:
            mapView.mapType = .Standard
        case 1:
            mapView.mapType = .Satellite
        case 2:
            mapView.mapType = .Hybrid
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
        case .Satellite:
            mapTypeAsInt = 1
        case .Hybrid:
            mapTypeAsInt = 2
        case let type:
            println("Unknown map type \(type)")
        }
        defaults.setInteger(mapTypeAsInt, forKey: mapTypeKey)

        // save the current region as its component parts
        let currentRegion = mapView.region
        defaults.setDouble(currentRegion.center.latitude,
            forKey: mapRegionCenterLatitudeKey)
        defaults.setDouble(currentRegion.center.longitude,
            forKey: mapRegionCenterLongitudeKey)
        defaults.setDouble(currentRegion.span.latitudeDelta,
            forKey: mapRegionSpanLatitudeDeltaKey)
        defaults.setDouble(currentRegion.span.longitudeDelta, forKey:
            mapRegionSpanLongitudeDeltaKey)
    }

    // center the map as the given latitude/longitude and drop
    // a pin at that location
    func centerMapAtLatitude(latitude: Double, longitude: Double) {
        let center = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        mapView.setCenterCoordinate(center, animated: true)
        // ;;; drop a pin here
    }

}
