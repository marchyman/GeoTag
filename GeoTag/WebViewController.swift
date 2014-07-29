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
    // current map state
    var mapLatitude = 37.512994
    var mapLongitude = -122.33963
    var mapZoom = 10
    var mapType = 0

    // keys to save map state in user defaults
    let mapLatitudeKey = "MapLatitudeKey"
    let mapLongitudeKey = "MapLongitudeKey"
    let mapZoomKey = "MapZoomKey"
    let mapTypeKey = "MapTypeKey"

    @IBOutlet var webView: WebView!
    @IBOutlet var mapTypeControl: NSSegmentedControl!

    // MARK: Class methods

    class override func isKeyExcludedFromWebScript(property: ConstUnsafePointer<Int8>) -> Bool {
        // TODO: Limit access to the map state variables
        return false
    }

    // MARK: startup

    // Alas, 10.10 and later
    override func viewDidLoad() {
        super.viewDidLoad()
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

    override func webView(webView: WebView,
                          didClearWindowObject wso: WebScriptObject,
                          forFrame frame: WebFrame) {
        // Initialize map state
        let defaults = NSUserDefaults.standardUserDefaults()
        let latitude = defaults.doubleForKey(mapLatitudeKey)
        if latitude != 0.0 {
            mapLatitude = latitude
        }
        let longitude = defaults.doubleForKey(mapLongitudeKey)
        if longitude != 0 {
            mapLongitude = longitude
        }
        let zoom = defaults.integerForKey(mapZoomKey)
        if zoom != 0 {
            mapZoom = zoom
        }
        mapType = defaults.integerForKey(mapTypeKey)
        mapTypeControl.selectedSegment = mapType

        wso.setValue(self, forKey: "controller")
    }

    // MARK: Map control actions

    // select the desired map type
    @IBAction func changeMapType(sender: NSSegmentedControl) {
        setMap("TypeId", values: [sender.selectedSegment])
    }

    // save the current map type and displayed region
    @IBAction func saveMapSetting(AnyObject) {
        let defaults = NSUserDefaults.standardUserDefaults()
        defaults.setDouble(mapLatitude, forKey: mapLatitudeKey)
        defaults.setDouble(mapLongitude, forKey: mapLongitudeKey)
        defaults.setInteger(mapZoom, forKey: mapZoomKey)
        defaults.setInteger(mapType, forKey: mapTypeKey)
    }

    // MARK: Javascript interface

    func setMap(function: String, values: [AnyObject]!) {
        webView.windowScriptObject.callWebScriptMethod("setMap" + function,
                                                       withArguments: values)
    }


//    func centerMapAtLatitude(latitude: Double, longitude: Double) {
//        let center = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
//        mapView.setCenterCoordinate(center, animated: true)
//    }
}
