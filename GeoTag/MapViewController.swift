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
    let mapRegionKey = "MapRegion"

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
        let currentRegion = mapView.region
        // save the settings here ;;;
    }

    func centerMapAtLatitude(latitude: Double, longitude: Double) {
        let center = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        mapView.setCenterCoordinate(center, animated: true)
    }

}
