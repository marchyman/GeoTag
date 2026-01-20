//
// Copyright 2025 Marco S Hyman
// https://www.snafu.org/
//

import XCTest

final class GeoTagUI07Layout: XCTestCase {
    private var app: XCUIApplication!
    private var testImageFolder = ""

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
        app.launchEnvironment["UITESTS"] = "1"
        app.launch()
        let window = app.windows["main"]
        XCTAssert(window.waitForExistence(timeout: 3))

        // remove the "no backups sheet" sheet if it is present.
        let sheet = window.sheets.element
        if sheet.exists {
            sheet.buttons.firstMatch.click()
        }

        // grab needed test location from the environment
        if let imagePath = ProcessInfo.processInfo.environment["ImagePath"] {
            testImageFolder = imagePath
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

        // make sure disabled files are hidden
        let hideDisabledFiles = app.menuItems["Hide Disabled Files"]
        if hideDisabledFiles.exists {
            hideDisabledFiles.click()
        }
    }

    @MainActor
    func openTestFile(folder: Bool = false) {
        app.typeKey("o", modifierFlags: [.command])
        app.typeKey("g", modifierFlags: [.shift, .command])
        app.typeText(testImageFolder)
        if !folder {
            app.typeText("/TestPictures/IMG_7158.CR2")
        }
        app.typeKey(.enter, modifierFlags: [])
        app.typeKey(.enter, modifierFlags: [])
    }

    @MainActor
    func changeCoordFormat(_ fmt: Int) {
        let format: [String] = [
            "dd.dddddd",
            "dd° mm.mmmmmm'",
            "dd° mm' ss.ss\""
        ]
        XCTAssert(fmt >= 0 && fmt <= 2)
        app.typeKey(",", modifierFlags: .command)
        let settings = app.windows["GeoTag Settings"]
        XCTAssert(settings.waitForExistence(timeout: 2))
        settings.radioButtons[format[fmt]].click()
        settings.buttons["Close"].click()
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

    // Repeat earlier tests, this time using the alternate layout

    @MainActor
    func testMapClick() {
        localSetup()
        let alternateLayout = app.menuItems["Alternate Layout"]
        if alternateLayout.exists {
            alternateLayout.click()
        }
        openTestFile()
        let row = app.outlineRows.firstMatch
        XCTAssert(row.staticTexts["IMG_7158.CR2*"]
            .waitForExistence(timeout: 2))
        row.staticTexts["IMG_7158.CR2*"].click()

        // click on the map, verify location and pin
        let map = app.maps.firstMatch
        map.click()
        XCTAssert(row.staticTexts.element(boundBy: 2)
            .waitForExistence(timeout: 1))
        XCTAssert(row.staticTexts.element(boundBy: 3).exists)
        XCTAssert(map.images["Pin"].exists)

        // Ask to quit.  Verify confirmation presented.  Cancel Quit
        app.typeKey("q", modifierFlags: [.command])
        XCTAssert(app.sheets.firstMatch.waitForExistence(timeout: 1))
        XCTAssert(app.sheets.firstMatch.buttons["Cancel"].exists)
        app.sheets.firstMatch.buttons["Cancel"].click()

        // delete the location.
        app.typeKey(.delete, modifierFlags: [])
        XCTAssert(!row.staticTexts.element(boundBy: 2)
            .waitForExistence(timeout: 1))
        XCTAssert(!row.staticTexts.element(boundBy: 3).exists)
        XCTAssert(!map.images["Pin"].exists)
    }

    @MainActor
    func testTableMenu() {
        localSetup()
        let alternateLayout = app.menuItems["Alternate Layout"]
        if alternateLayout.exists {
            alternateLayout.click()
        }
        openTestFile(folder: true)
        XCTAssert(app.windows.sheets.element.waitForExistence(timeout: 2))
        app.sheets.buttons.firstMatch.click()

        // Check context menu when right clicking on table
        let table = app.outlines["alternateTable"]
        table.swipeUp()
        table.rightClick()

        let menu = app.windows.firstMatch
            .groups.firstMatch
            .splitGroups.firstMatch
            .groups.firstMatch
            .menus.firstMatch
        XCTAssert(menu.waitForExistence(timeout: 1))
        XCTAssert(menu.menuItems["Edit…"].exists)
        XCTAssert(menu.menuItems["Cut"].exists)
        XCTAssert(menu.menuItems["Copy"].exists)
        XCTAssert(menu.menuItems["Paste"].exists)
        XCTAssert(menu.menuItems["Delete"].exists)
        XCTAssert(menu.menuItems["Show In Finder"].exists)
        XCTAssert(menu.menuItems["Locn From Track"].exists)
        XCTAssert(menu.menuItems["Clear Image List"].exists)
        table.click()

        // assign locations and test the various coordinate formats

        changeCoordFormat(0)
        app.typeKey("a", modifierFlags: [.command])
        table.rightClick()
        menu.menuItems["Locn From Track"].click()
        var row = app.outlineRows.firstMatch
        if !row.staticTexts["IMG_7158.CR2*"].exists {
            row = app.outlineRows.element(boundBy: 1)
        }
        XCTAssert(row.staticTexts[" 38.521077"].waitForExistence(timeout: 1))
        XCTAssert(row.staticTexts["-123.200344"].exists)

        changeCoordFormat(1)
        XCTAssert(row.staticTexts["38° 31.264616' N"].waitForExistence(timeout: 1))
        XCTAssert(row.staticTexts["123° 12.020668' W"].exists)

        changeCoordFormat(2)
        XCTAssert(row.staticTexts["38° 31' 15.88\" N"].waitForExistence(timeout: 1))
        XCTAssert(row.staticTexts["123° 12' 1.24\" W"].exists)

        // copy the coordinates and paste them into another row
        table.swipeDown()
        row.staticTexts.element(boundBy: 0).rightClick()
        menu.menuItems["Copy"].click()
        let newRow = app.outlineRows.element(boundBy: 4)
        newRow.staticTexts.element(boundBy: 0).click()
        newRow.staticTexts.element(boundBy: 0).rightClick()
        menu.menuItems["Paste"].click()
        XCTAssert(newRow.staticTexts["38° 31' 15.88\" N"].exists)
        XCTAssert(newRow.staticTexts["123° 12' 1.24\" W"].exists)

        // open the inspector for newRow
        newRow.staticTexts.element(boundBy: 0).rightClick()
        menu.menuItems["Edit…"].click()
        let inspector = app
            .windows.firstMatch
            .groups.firstMatch
            .splitGroups.firstMatch
            .groups.element(boundBy: 1)
        XCTAssert(inspector.waitForExistence(timeout: 1))
        XCTAssert(inspector.staticTexts["Date and Time"].exists)
        XCTAssert(inspector.staticTexts["Location"].exists)
        let lat = inspector.textFields.firstMatch
        lat.click()
        lat.typeKey("a", modifierFlags: [.command])
        lat.typeText("38.5")
        lat.typeKey(.return, modifierFlags: [])
        app.buttons["Toggle Inspector"].firstMatch.click()
        XCTAssert(newRow.staticTexts["38° 30' 0.00\" N"].exists)
    }
}
