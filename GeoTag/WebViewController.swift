//
//  WebViewController.swift
//  GeoTag
//
//  Created by Marco S Hyman on 7/28/14.
//  Copyright (c) 2014, 2015 Marco S Hyman, CC-BY-NC
//

import Foundation
import WebKit

final class WebViewController: NSViewController {
    // MARK: Properties

    // current map state (default to SF Peninsula :)
    var mapLatitude = 37.512994
    var mapLongitude = -122.33963
    var mapZoom = 10
    var mapType = 0

    // pass selection state to the javescript code
    var itemSelected = false

    // keys to save map state in user defaults
    let mapLatitudeKey = "MapLatitudeKey"
    let mapLongitudeKey = "MapLongitudeKey"
    let mapZoomKey = "MapZoomKey"
    let mapTypeKey = "MapTypeKey"

    // marker location
    var markerLatitude = 0.0
    var markerLongitude = 0.0

    // outlets
    @IBOutlet var webView: WebView!
    @IBOutlet var mapTypeControl: NSSegmentedControl!

    var clickDelegate: WebViewControllerDelegate?

    // MARK: Class methods

    /// limit property access from javascript to the map state variables

    class override func isKeyExcludedFromWebScript(keyPtr: UnsafePointer<Int8>) -> Bool {
        if let key = NSString(CString: keyPtr, encoding: NSUTF8StringEncoding) {
            switch key {
            case "mapLatitude", "mapLongitude", "mapZoom", "mapType",
                "itemSelected", "markerLatitude", "markerLongitude":
                return false
            default:
                return true
            }
        }
        return true
    }

    /// allow javascript to report position changes.  All other methods are
    /// off limits.

    class override func isSelectorExcludedFromWebScript(sel: Selector) -> Bool {
        if sel == "reportPosition" {
            return false
        }
        return true
    }

    // MARK: startup

    /// object initialization

    override func awakeFromNib() {
        // Ask webKit to load the map.html file from our resources directory.
        let mapPath = NSBundle.mainBundle().pathForResource("map",
                                                            ofType: "html")
        let mapURL = NSURL(fileURLWithPath: mapPath!, isDirectory: false)
        let map = NSURLRequest(URL: mapURL)
        webView.mainFrame.loadRequest(map)
    }

    /// obtain info needed to draw initial map from user defaults

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
        if longitude != 0.0 {
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

    // MARK: Map control targets

    /// select the desired map type

    @IBAction func changeMapType(sender: NSSegmentedControl) {
        setMap("TypeId", values: [sender.selectedSegment])
    }

    /// save the current map type and displayed region in user defaults

    @IBAction func saveMapSetting(AnyObject) {
        let defaults = NSUserDefaults.standardUserDefaults()
        defaults.setDouble(mapLatitude, forKey: mapLatitudeKey)
        defaults.setDouble(mapLongitude, forKey: mapLongitudeKey)
        defaults.setInteger(mapZoom, forKey: mapZoomKey)
        defaults.setInteger(mapType, forKey: mapTypeKey)
    }

    // MARK: pin drop/clear interface

    /// drop the pin at the given latitude and longitude

    func pinMapAtLatitude(latitude: Double, longitude: Double) {
         setMap("Pin", values: [latitude, longitude])
    }

    /// hide the pin

    func removeMapPin() {
        setMap("PinHidden", values: nil)
    }

    // MARK: Javascript interface

    /// Called when a marker is placed on the map or its position changed.
    /// The delegate processes the position change.

    func reportPosition() {
        clickDelegate?.webViewMouseClicked(markerLatitude,
                                           longitude: markerLongitude)
    }

    /// Call the javascript setMap function
    /// - Parameter values: An array of arguments to pass to javascript

    func setMap(function: String, values: [AnyObject]!) {
        webView.windowScriptObject.callWebScriptMethod("setMap" + function,
                                                       withArguments: values)
    }
}

// MARK: WebViewController Delegate Protocol

/// The delegate handles the non map details of changing locations

protocol WebViewControllerDelegate: NSObjectProtocol {
    func webViewMouseClicked(latitude: Double, longitude: Double)
}
