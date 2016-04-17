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

    // MARK: startup

    /// object initialization

    override func awakeFromNib() {
        // Ask webKit to load the map.html file from our resources directory.
        guard let mapPath = NSBundle.main()
            .pathForResource("map", ofType: "html")
            else { fatalError("can't find map.html resource") }
        let mapURL = NSURL(fileURLWithPath: mapPath, isDirectory: false)
        let map = NSURLRequest(url: mapURL)
        webView.mainFrame.load(map)
    }

    /// obtain info needed to draw initial map from user defaults
    /// make self the "controller" for the web script object

    @objc(webView:didClearWindowObject:forFrame:)
    func webView(webView: WebView,
                 didClearWindowObject wso: WebScriptObject,
                 forFrame frame: WebFrame) {
        // Initialize map state
        let defaults = NSUserDefaults.standard()
        let latitude = defaults.double(forKey: mapLatitudeKey)
        if latitude != 0.0 {
            mapLatitude = latitude
        }
        let longitude = defaults.double(forKey: mapLongitudeKey)
        if longitude != 0.0 {
            mapLongitude = longitude
        }
        let zoom = defaults.integer(forKey: mapZoomKey)
        if zoom != 0 {
            mapZoom = zoom
        }
        mapType = defaults.integer(forKey: mapTypeKey)
        mapTypeControl.selectedSegment = mapType

        wso.setValue(self, forKey: "controller")
    }

    // MARK: Map control targets

    /// select the desired map type

    @IBAction func changeMapType(_ sender: NSSegmentedControl) {
        setMap("TypeId", values: [sender.selectedSegment])
    }

    /// save the current map type and displayed region in user defaults

    @IBAction func saveMapSetting(_: AnyObject) {
        let defaults = NSUserDefaults.standard()
        defaults.set(mapLatitude, forKey: mapLatitudeKey)
        defaults.set(mapLongitude, forKey: mapLongitudeKey)
        defaults.set(mapZoom, forKey: mapZoomKey)
        defaults.set(mapType, forKey: mapTypeKey)
    }

    // MARK: pin drop/clear interface

    /// drop the pin at the given latitude and longitude

    func dropMapPin(latitude: Double, longitude: Double) {
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
        clickDelegate?.webViewMouseClicked(latitude: markerLatitude,
                                           longitude: markerLongitude)
    }

    /// Call the javascript setMap function
    /// - Parameter values: An array of arguments to pass to javascript

    func setMap(_ function: String, values: [AnyObject]!) {
        webView.windowScriptObject.callWebScriptMethod("setMap" + function,
                                                       withArguments: values)
    }
}

// MARK: WebScripting access control

extension WebViewController {

    /// limit property access from javascript to the map state variables
    /// Override of function defined on NSObject

    @objc(isKeyExcludedFromWebScript:)
    override class func isKeyExcluded(fromWebScript name: UnsafePointer<Int8>!) -> Bool {
        guard name != nil else { return true }
        if let key = NSString(cString: name, encoding: NSUTF8StringEncoding) {
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
    /// Override of function defined on NSObject

    @objc(isSelectorExcludedFromWebScript:)
    override class func isSelectorExcluded(fromWebScript selector: Selector!) -> Bool {
        guard selector != nil else { return true }
        if selector == #selector(reportPosition) {
            return false
        }
        return true
    }
}

// MARK: WebViewController Delegate Protocol

/// The delegate handles the non map details of changing locations

protocol WebViewControllerDelegate: NSObjectProtocol {
    func webViewMouseClicked(latitude: Double, longitude: Double)
}
