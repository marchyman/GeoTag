//
//  GeoTagUI02SettingsTests.swift
//  GeoTagUITests
//
//  Created by Marco S Hyman on 3/28/24.
//

import XCTest

final class GeoTagUI02SettingsTests: XCTestCase {

    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the
        // invocation of each test method in the class.
        try super.tearDownWithError()
        app = nil
    }

    @MainActor
    func localSetup() {
        app = XCUIApplication()

        app.launch()

        // remove the "no backups sheet" sheet if it is present.
        let sheet = app.windows.sheets.element
        if sheet.exists {
            sheet.buttons.firstMatch.click()
        }
    }

    @MainActor
    func takeScreenshot(name: String) {
        let screenshot = app.windows.firstMatch.screenshot()

        let attachment =
        XCTAttachment(uniformTypeIdentifier: "public.png",
                      name: "\(name).png",
                      payload: screenshot.pngRepresentation,
                      userInfo: nil)
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    @MainActor
    func test0SettingsOpened() throws {
        localSetup()
        app.menuItems["Settings…"].click()
        XCTAssertTrue(app.windows["GeoTag Settings"].waitForExistence(timeout: 2))

        XCTAssertTrue(app.staticTexts["Disable Image Backups:"].exists)
        XCTAssertTrue(app.checkBoxes["Disable image backups"].exists)
        if let value = app.checkBoxes["Disable image backups"].value as? Int? {
            if value == 1 {
                app.checkBoxes["Disable image backups"].click()
                sleep(1)
            }
        }
        takeScreenshot(name: "Settings")

        XCTAssertTrue(app.staticTexts["Create Sidecar (XMP) files:"].exists)
        XCTAssertTrue(app.checkBoxes["Create Sidecar (XMP) files"].exists)

        XCTAssertTrue(app.staticTexts["Choose a coordinate format:"].exists)
        XCTAssertTrue(app.radioButtons["dd.dddddd"].exists)
        XCTAssertTrue(app.radioButtons["dd° mm.mmmmmm'"].exists)
        XCTAssertTrue(app.radioButtons["dd° mm' ss.ss\""].exists)

        XCTAssertTrue(app.staticTexts["GPS Track Color:"].exists)
        XCTAssertTrue(app.colorWells.firstMatch.exists)

        XCTAssertTrue(app.staticTexts["GPS Track width:"].exists)
        XCTAssertTrue(app.textFields.element(boundBy: 0).exists)

        XCTAssertTrue(app.staticTexts["Disable paired jpegs:"].exists)
        XCTAssertTrue(app.checkBoxes["Disable paired jpegs"].exists)

        XCTAssertTrue(app.staticTexts["Set File Modification Times:"].exists)
        XCTAssertTrue(app.checkBoxes["Set File Modification Time"].exists)

        XCTAssertTrue(app.staticTexts["Update GPS Date/Time:"].exists)
        XCTAssertTrue(app.checkBoxes["Update GPS Date/Time"].exists)

        XCTAssertTrue(app.staticTexts["Tag updated files:"].exists)
        XCTAssertTrue(app.checkBoxes["Tag updated files"].exists)
        if let value = app.checkBoxes["Tag updated files"].value as? Int? {
            if value == 0 {
                app.checkBoxes["Tag updated files"].click()
            }
        }
        XCTAssertTrue(app.textFields.element(boundBy: 1).exists)

        XCTAssertTrue(app.buttons["Close"].exists)
        app.buttons["Close"].click()
    }

    // swiftlint: disable cyclomatic_complexity
    @MainActor
    func test1ChangeSettings() {
        localSetup()
        app.typeKey(",", modifierFlags: .command)
        XCTAssertTrue(app.windows["GeoTag Settings"].waitForExistence(timeout: 2))
        let settings = app.windows["GeoTag Settings"]

        // There is no XCTest access to the SwiftUI wrapped NSPathControl.
        // It will have to be tested by hand.  Ditto GPS Track Color.
        // Put everything else in a known state

        if let value = settings.checkBoxes["Disable image backups"].value as? Int {
            if value == 1 {
                settings.checkBoxes["Disable image backups"].click()
            }
        }

        if let value = settings.checkBoxes["Create Sidecar (XMP) files"].value as? Int {
            if value == 0 {
                settings.checkBoxes["Create Sidecar (XMP) files"].click()
            }
        }

        settings.radioButtons["dd° mm' ss.ss\""].click()

        // set GPS Track Width
        let textField0 = settings
            .descendants(matching: .textField)
            .element(boundBy: 0)
        textField0.doubleClick()
        textField0.typeKey(.delete, modifierFlags: [])
        textField0.typeText("3")

        if let value = settings.checkBoxes["Disable paired jpegs"].value as? Int {
            if value == 0 {
                settings.checkBoxes["Disable paired jpegs"].click()
            }
        }

        if let value = settings.checkBoxes["Set File Modification Time"].value as? Int {
            if value == 0 {
                settings.checkBoxes["Set File Modification Time"].click()
            }
        }

        if let value = settings.checkBoxes["Update GPS Date/Time"].value as? Int {
            if value == 0 {
                settings.checkBoxes["Update GPS Date/Time"].click()
            }
        }

        if let value = settings.checkBoxes["Tag updated files"].value as? Int {
            if value == 0 {
                settings.checkBoxes["Tag updated files"].click()
            }
        }
        let textField1 = settings
            .descendants(matching: .textField)
            .element(boundBy: 1)
        textField1.doubleClick()
        textField1.typeKey(.delete, modifierFlags: [])
        textField1.typeText("TestTag")

        settings.buttons["Close"].click()
        // swiftlint: enable cyclomatic_complexity
    }

    @MainActor
    func test2ValidateSettings() {
        localSetup()
        app.typeKey(",", modifierFlags: .command)
        XCTAssertTrue(app.windows["GeoTag Settings"].waitForExistence(timeout: 2))
        let settings = app.windows["GeoTag Settings"]

        // There is no XCTest access to the SwiftUI wrapped NSPathControl.
        // It will have to be tested by hand.  Ditto GPS Track Color.
        // Put everything else in a known state

        let dib = settings.checkBoxes["Disable image backups"].value as? Int
        XCTAssertNotNil(dib)
        XCTAssertTrue(dib == 0)

        let csf = settings.checkBoxes["Create Sidecar (XMP) files"].value as? Int
        XCTAssertNotNil(csf)
        XCTAssertTrue(csf == 1)

        let coord = settings.radioButtons["dd° mm' ss.ss\""].value as? Int
        XCTAssertNotNil(coord)
        XCTAssertTrue(coord == 1)

        let dpg = settings.checkBoxes["Disable paired jpegs"].value as? Int
        XCTAssertNotNil(dpg)
        XCTAssertTrue(dpg == 1)

        let sfmt = settings.checkBoxes["Set File Modification Time"].value as? Int
        XCTAssertNotNil(sfmt)
        XCTAssertTrue(sfmt == 1)

        let ugdt = settings.checkBoxes["Update GPS Date/Time"].value as? Int
        XCTAssertNotNil(ugdt)
        XCTAssertTrue(ugdt == 1)

        let tuf = settings.checkBoxes["Tag updated files"].value as? Int
        XCTAssertNotNil(tuf)
        XCTAssertTrue(tuf == 1)

        settings.buttons["Close"].click()
    }

    @MainActor
    func test3NormalSettings() {
        localSetup()
        app.typeKey(",", modifierFlags: .command)
        XCTAssertTrue(app.windows["GeoTag Settings"].waitForExistence(timeout: 2))
        let settings = app.windows["GeoTag Settings"]

        // the last test left most settings enabled.  Turn off a
        // couple of them.

        settings.checkBoxes["Create Sidecar (XMP) files"].click()
        settings.checkBoxes["Tag updated files"].click()
    }
}
