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

    // startup

    override func viewDidLoad() {       // 10.10 and later
        super.viewDidLoad()
    }

    func displayMapAtLatitude(latitude: Double, longitude: Double) {
        var region = mapView.region
        region.center = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        mapView.setRegion(region, animated: true)
    }
}
