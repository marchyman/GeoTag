//
//  GeoTagUITests.swift
//  GeoTagUITests
//
//  Created by Marco S Hyman on 8/6/18.
//  Copyright © 2018, 2021 Marco S Hyman. All rights reserved.
//

import XCTest

/// The first GeoTag User Interface test class.
/// This class is expected to run before any other class.  It starts GeoTag
/// with a flag in the environment that tells GeoTag to wipe out a needed
/// user preference.  This verifies that GeoTag will load the preference window
/// to obtain the needed data.  The test configures GeoTag defaults for the
/// remainder of the test classes which assume the appropriate set-up.

class A_GeoTagUITests: XCTestCase {

    let trashFile = NSTemporaryDirectory()

    override func setUp() {
        // Put setup code here. This method is called before the invocation of
        // each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // UI tests must launch the application that they test. Doing this in
        // setup will make sure it happens for each test method.
        // UITESTS causes defaults to be cleared upon startup.
        let app = XCUIApplication()
        app.launchEnvironment = ["UITESTS":"1"]
        app.launch()

        // Now set up user defaults for testing.  The app should have opened
        // the preferences window.

        let window = app.windows["GeoTag Preferences"]
        XCTAssertTrue(window.exists)
        let path = window.descendants(matching: .other).element
        XCTAssertTrue(path.exists)
        path.click()

        // can't get the open selection window... type blind into the app

		app.typeKey("g", modifierFlags: [.shift, .command])
		app.typeText(trashFile)
        app.typeKey(.enter, modifierFlags: [])
        app.typeKey(.enter, modifierFlags: [])

        // close the preferences window

        let close = window.buttons[XCUIIdentifierCloseWindow]
        XCTAssertTrue(close.exists)
        close.click()
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testStartup() {
        let app = XCUIApplication()
        let window = app.windows["GeoTag"]
        XCTAssertTrue(window.exists)
        XCTAssertTrue(window.children(matching: .splitGroup).element.exists)
        XCTAssertEqual(window.children(matching: .button).count, 3)
        XCTAssertTrue(window.children(matching: .staticText).element.exists)

        // re-open the preferences window
        window.typeKey(",", modifierFlags: .command)
        let preferences = app.windows["GeoTag Preferences"]
        XCTAssertTrue(preferences.exists)
        
        // check the latitude/longitude display formats
        let buttons = preferences.descendants(matching: .radioButton)
        print(buttons.debugDescription)
        XCTAssertEqual(buttons.count, 3)
        let deg = buttons.matching(identifier: "deg").element
        XCTAssertEqual(deg.value as! Int, 1)
        let degMin = buttons.matching(identifier: "degMin").element
        XCTAssertEqual(degMin.value as! Int, 0)
        let degMinSec = buttons.matching(identifier: "degMinSec").element
        XCTAssertEqual(degMinSec.value as! Int, 0)
        degMinSec.click()
        XCTAssertEqual(deg.value as! Int, 0)
        XCTAssertEqual(degMin.value as! Int, 0)
        XCTAssertEqual(degMinSec.value as! Int, 1)
        deg.click()
        XCTAssertEqual(deg.value as! Int, 1)
        XCTAssertEqual(degMinSec.value as! Int, 0)

        // check the update sidecar file checkbox
        let checkBoxes = preferences.descendants(matching: .checkBox)
        let sidecar = checkBoxes.matching(identifier: "sidecar").element
        XCTAssertEqual(sidecar.value as! Int, 0)
        sidecar.click()
        XCTAssertEqual(sidecar.value as! Int, 1)
        
        // check the GPS date/time checkbox
        let datetime = checkBoxes.matching(identifier: "datetime").element
        XCTAssertEqual(datetime.value as! Int, 0)
        datetime.click()
        XCTAssertEqual(datetime.value as! Int, 1)

        let close = preferences.buttons[XCUIIdentifierCloseWindow]
        XCTAssertTrue(close.exists)
        close.click()
    }

}
