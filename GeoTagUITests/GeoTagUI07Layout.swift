//
// Copyright 2025 Marco S Hyman
// https://www.snafu.org/
//

import XCTest

final class GeoTagUI07Layout: XCTestCase {
    private var app: XCUIApplication!

    override func setUp() {
        continueAfterFailure = false

    }

    override func tearDown() {
        // Put teardown code here. This method is called after the
        // invocation of each test method in the class.
        super.tearDown()
        app = nil
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
    func localSetup() {
        app = XCUIApplication()
        app.launchEnvironment = ["UITESTS": "1"]
        app.launch()

        // remove the "no backups sheet" sheet if it is present.
        let sheet = app.windows.sheets.element
        if sheet.exists {
            sheet.buttons.firstMatch.click()
        }

        // verify the view is using the normal layout
        let alternateLayout = app.menuItems["Alternate Layout"]
        if !alternateLayout.exists {
            let normalLayout = app.menuItems["Normal Layout"]
            if normalLayout.exists {
                normalLayout.click()
                XCTAssert(app.menuItems["Alternate Layout"].waitForExistence(timeout: 2))
            }
        }
    }

    @MainActor
    func testAlternateLayout() {
        localSetup()
        XCTAssert(app.outlines["normalTable"].exists)
        XCTAssert(app.images["normalImage"].exists)
        XCTAssert(app.maps["normalMap"].exists)
        let alternateLayout = app.menuItems["Alternate Layout"]
        XCTAssert(alternateLayout.exists)
        alternateLayout.click()
        XCTAssert(app.menuItems["Normal Layout"].waitForExistence(timeout: 2))
        takeScreenshot(name: "AlternateLayout")
        XCTAssert(app.outlines["alternateTable"].exists)
        XCTAssert(app.images["alternateImage"].exists)
        XCTAssert(app.maps["alternateMap"].exists)
    }
}
