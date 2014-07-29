//
//  WebViewController.swift
//  GeoTag
//
//  Created by Marco S Hyman on 7/28/14.
//  Copyright (c) 2014 Marco S Hyman. All rights reserved.
//

import Cocoa
import WebKit

class WebViewController: NSViewController {

    @IBOutlet var webView: WebView!
    @IBOutlet var mapTypeControl: NSSegmentedControl!

    let mapTypeKey = "MapType"
    let mapRegionKey = "MapRegion"

    // MARK: startup

    // Alas, 10.10 and later
    override func viewDidLoad() {
        super.viewDidLoad()
        // this would be a good place to initialize an undo manager
    }

    // object initialization
    override func awakeFromNib() {
        // Ask webKit to load the map.html file from our resources directory.
        let mapPath = NSBundle.mainBundle().pathForResource("map",
                                                            ofType: "html")
        let mapURL = NSURL(fileURLWithPath: mapPath, isDirectory: false)
        let map = NSURLRequest(URL: mapURL)
        webView.mainFrame.loadRequest(map)
     }

    // MARKL Map control actions

    // select the desired map type
    @IBAction func changeMapType(sender: NSSegmentedControl) {
        switch sender.selectedSegment {
        case 0:
            webView.windowScriptObject.callWebScriptMethod("setMapTypeRoadmap",
                                                           withArguments: nil)
        case 1:
            webView.windowScriptObject.callWebScriptMethod("setMapTypeHybrid",
                                                           withArguments: nil)
        case 2:
            webView.windowScriptObject.callWebScriptMethod("setMapTypeSatellite",
                                                           withArguments: nil)
        case let type:
            println("Unknown segment item \(type), sender \(sender)")
        }
    }

    // save the current map type and displayed region
//    @IBAction func saveMapSetting(AnyObject) {
//        let defaults = NSUserDefaults.standardUserDefaults()
//        var mapTypeAsInt = 0
//        switch mapView.mapType {
//        case .Standard:
//            mapTypeAsInt = 0
//        case .Satellite:
//            mapTypeAsInt = 1
//        case .Hybrid:
//            mapTypeAsInt = 2
//        case let type:
//            println("Unknown map type \(type)")
//        }
//        defaults.setInteger(mapTypeAsInt, forKey: mapTypeKey)
//        let currentRegion = mapView.region
//        // save the settings here ;;;
//    }

//    func centerMapAtLatitude(latitude: Double, longitude: Double) {
//        let center = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
//        mapView.setCenterCoordinate(center, animated: true)
//    }

//+    [[webView windowScriptObject] callWebScriptMethod: @"addMarkerToMapAt"
//+                    withArguments: args];
}
