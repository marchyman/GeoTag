//
//  GeoTagTests.swift
//  GeoTagTests
//
//  Created by Marco S Hyman on 5/23/19.
//  Copyright © 2019 Marco S Hyman. All rights reserved.
//

import XCTest
@testable import GeoTag

class GeoTagTests: XCTestCase {

    let trashFile = NSTemporaryDirectory()

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        var bookmark: Data? = nil
        let url = URL(fileURLWithPath: trashFile, isDirectory: true)
        do {
            try bookmark = url.bookmarkData(options: .withSecurityScope)
        } catch let error as NSError {
            XCTFail("Cannot create security bookmark for image backup folder\n\nReason: \(error)")
        }
        let defaults = UserDefaults.standard
        defaults.set(bookmark, forKey: Preferences.saveBookmarkKey)
        Preferences.checkDirectory = true
        XCTAssertNotNil(Preferences.saveFolder())
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testAppDelegateSetup() {
        let app = NSApplication.shared
        if let ad = app.delegate as? AppDelegate {
            XCTAssertFalse(ad.modified)
            XCTAssertNotNil(ad.window)
            XCTAssertNotNil(ad.tableViewController)
            XCTAssertNotNil(ad.mapViewController)
            XCTAssertNotNil(ad.progressIndicator)
        } else {
            XCTFail("App Delegate not set")
        }
    }

    func testPreferencesSetup() {
        let app = NSApplication.shared
        if let ad = app.delegate as? AppDelegate {
            ad.openPreferences(self)
            if let prefs = preferencesViewController {
                XCTAssertNotNil(prefs.coordFormatDeg)
                XCTAssertNotNil(prefs.coordFormatDegMin)
                XCTAssertNotNil(prefs.coordFormatDegMinSec)
                XCTAssertNotNil(prefs.dtGPSButton)
                XCTAssertNotNil(prefs.sidecarButton)
            } else {
                XCTFail("preferencesViewController not set")
            }
        } else {
            XCTFail("App Delegate not set")
        }
    }

    func testCoords() {
        let coords = Coord(latitude: 45.50, longitude: -90.667)
        
        // minute and second conversion checks
        XCTAssert(coords.latitude.minutes == 30.0)
        XCTAssert(coords.latitude.seconds == 0.0)
        print(Int(coords.longitude.minutes), coords.longitude.seconds)
        XCTAssert(Int(coords.longitude.minutes) == 40)
        let secRange = 1.20..<1.200001
        XCTAssert(secRange.contains(coords.longitude.seconds))
        
        // latitude and longitude as deg mm.mmm ref
        XCTAssert(coords.dm.latitude == "45° 30.000000' N")
        XCTAssert(coords.dm.longitude == "90° 40.020000' W")

        // latitude and longitude as deg mm ss.ss ref
        XCTAssert(coords.dms.latitude == "45° 30' 0.00\" N")
        XCTAssert(coords.dms.longitude == "90° 40' 1.20\" W")
    }

    func testGpx() {
        let bundle = Bundle(for: type(of: self))
        let gpxUrl = bundle.url(forResource: "TestTrack", withExtension: "GPX")
        XCTAssertNotNil(gpxUrl)
        if let gpx = Gpx(contentsOf: gpxUrl!) {
            XCTAssert(gpx.parse(), "GPX file parsing failed")
            XCTAssert(gpx.tracks.count == 1)
            XCTAssert(gpx.tracks[0].segments.count == 1)
            let points = gpx.tracks[0].segments[0].points
            XCTAssert(points.count == 3813)
            if let point = points.first {
                XCTAssert(point.lat == 37.51501662656665)
                XCTAssert(point.lon == -122.33970330096781)
                XCTAssert(point.time == "2015-11-12T16:08:43Z")
            } else {
                XCTFail("Cannot access first point")
            }
            XCTAssert(points.last == gpx.lastPoint)
            if let point = points.last {
                XCTAssert(point.lat == 37.51502777449787)
                XCTAssert(point.lon == -122.3395486548543)
                XCTAssert(point.time == "2015-11-13T00:33:23Z")
            } else {
                XCTFail("Cannot access last point")
            }
        } else {
            XCTFail("Cannot create instance of Gpx")
        }
    }
//    func testPerformanceExample() {
//        // This is an example of a performance test case.
//        self.measure {
//            // Put the code you want to measure the time of here.
//        }
//    }

}
