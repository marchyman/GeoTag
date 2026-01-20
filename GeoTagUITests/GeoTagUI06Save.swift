//
// Copyright 2024 Marco S Hyman
// See LICENSE file for info
// https://www.snafu.org/
//

import XCTest

final class GeoTagUI06Save: XCTestCase {

    private var app: XCUIApplication!
    private var testImageFolder = ""
    private var saveImageFolder = ""
    private var saveBackupFolder = ""

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
    func localSetup() {
        app = XCUIApplication()
        // force the first save to fail
        app.launchEnvironment["BACKUP"] = NSTemporaryDirectory()
        app.launch()

        // remove the "no backups sheet" sheet if it is present.
        let sheet = app.windows.sheets.element
        if sheet.exists {
            sheet.buttons.firstMatch.click()
        }

        // grab needed test location from the environment
        if let imagePath = ProcessInfo.processInfo.environment["ImagePath"] {
            testImageFolder = imagePath
        }
        if let savePath = ProcessInfo.processInfo.environment["SavePath"] {
            saveImageFolder = savePath
        }
        if let backupPath = ProcessInfo.processInfo.environment["BackupPath"] {
            saveBackupFolder = backupPath
        }
    }

    // save tests.  This test modifies items in the source tree.  There
    // should be no changes pending allowing a git reset --hard to reset
    // the source tree after testing. If using jj the command
    // `jj restore SaveData` will restore the modified files.

    // swiftlint: disable large_tuple
    let results: [(String, String, String, String)] = [
        ("IMG_7158.CR2*", "2015:11:12 13:06:56", "38° 31' 15.88\" N", "123° 12' 1.24\" W"),
        ("L1000038.DNG", "2015:11:12 09:41:11", "38° 16' 10.27\" N", "122° 40' 15.12\" W"),
        ("P1000685.JPG", "2015:11:12 13:02:28", "38° 31' 45.91\" N", "123° 12' 52.03\" W"),
        ("P1000686.JPG", "1980:02:01 12:00:00", "", ""),
        ("Screenshot.png", "", "38° 30' 0.00\" N", "123° 27' 21.60\" W")
    ]
    // swiftlint: enable large_tuple

    @MainActor
    func testSave() {
        localSetup()
        openImages()
        openTrack()
        applyTrackLocations()
        adjustImageTime()
        adjustImageLocation()
        verifyResults()
        saveWithBadBackupFolder()
        setBackupFolder()
        app.typeKey("s", modifierFlags: [.command]) // save images
        app.menuItems["Clear Image List"].click()
        openImages()
        verifyResults()
        app.typeKey("q", modifierFlags: [.command]) // quit
    }

    // helper functions for test 4
    @MainActor
    func openImages() {
        app.typeKey("o", modifierFlags: [.command])
        app.typeKey("g", modifierFlags: [.shift, .command])
        app.typeText(saveImageFolder)
        app.typeKey(.enter, modifierFlags: [])
        app.typeKey(.enter, modifierFlags: [])
        XCTAssert(app.outlines.firstMatch.waitForExistence(timeout: 1))
        // Hide non-image files if necessary
        if app.menuItems["Hide Disabled Files"].exists {
            app.typeKey("d", modifierFlags: [.command])
        }
    }

    @MainActor
    func openTrack() {
        // open the track file from the test folder
        app.typeKey("o", modifierFlags: [.command])
        app.typeKey("g", modifierFlags: [.shift, .command])
        app.typeText(testImageFolder)
        app.typeText("/TestTrack.GPX")
        app.typeKey(.enter, modifierFlags: [])
        app.typeKey(.enter, modifierFlags: [])
        XCTAssertTrue(app.windows.sheets.element.waitForExistence(timeout: 2))
        app.sheets.buttons.firstMatch.click()
    }

    @MainActor
    func applyTrackLocations() {
        // select the images and apply the changes
        app.typeKey("a", modifierFlags: [.command])
        app.typeKey("l", modifierFlags: [.command])
    }

    @MainActor
    func adjustImageTime() {
        // modify the time of one of the images.
        let row = app.outlineRows.element(boundBy: 3)
        XCTAssert(row.staticTexts["1980:01:01 12:00:00"].exists)
        row.staticTexts.firstMatch.click()
        row.staticTexts.firstMatch.rightClick()
        let menu = app.windows.firstMatch
            .groups.firstMatch
            .splitGroups.firstMatch
            .groups.firstMatch
            .menus.firstMatch
        menu.menuItems["Edit…"].click()
        let inspector = app
            .windows.firstMatch
            .groups.firstMatch
            .splitGroups.firstMatch
            .groups.element(boundBy: 1)
        XCTAssert(inspector.waitForExistence(timeout: 1))
        let datePicker = inspector.datePickers["newDatePicker"]
        XCTAssert(datePicker.exists)
        datePicker.incrementArrows.firstMatch.click()
        app.buttons["Toggle Inspector"].firstMatch.click()
    }

    @MainActor
    func adjustImageLocation() {
        // modify the location of the PNG file
        let row = app.outlineRows.element(boundBy: 4)
        row.staticTexts.firstMatch.click()
        row.staticTexts.firstMatch.rightClick()
        let menu = app.windows.firstMatch
            .groups.firstMatch
            .splitGroups.firstMatch
            .groups.firstMatch
            .menus.firstMatch
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
        let lon = inspector.textFields.element(boundBy: 1)
        lon.click()
        lon.typeKey("a", modifierFlags: [.command])
        lon.typeText("-123.456")
        lon.typeKey(.return, modifierFlags: [])
        app.buttons["Toggle Inspector"].firstMatch.click()
    }

    @MainActor
    func verifyResults() {
        for ix in 0 ..< results.count {
            // all elements have a name
            XCTAssert(app.outlineRows.element(boundBy: ix)
                .staticTexts[results[ix].0].exists)
            // skip elements without a time
            if results[ix].1 != "" {
                XCTAssert(app.outlineRows.element(boundBy: ix)
                    .staticTexts[results[ix].1].exists)
            }
            // skip elements without a latitude
            if results[ix].2 != "" {
                XCTAssert(app.outlineRows.element(boundBy: ix)
                    .staticTexts[results[ix].2].exists)
            }
            // skip elements without a longitude
            if results[ix].3 != "" {
                XCTAssert(app.outlineRows.element(boundBy: ix)
                    .staticTexts[results[ix].3].exists)
            }
        }
    }

    @MainActor
    func saveWithBadBackupFolder() {
        app.typeKey("s", modifierFlags: [.command])
        XCTAssert(app.sheets.firstMatch.waitForExistence(timeout: 1))
        XCTAssert(app.sheets.firstMatch.buttons["Dismiss"].exists)
        app.sheets.firstMatch.buttons["Dismiss"].click()
    }

    @MainActor
    func setBackupFolder() {
        app.typeKey(",", modifierFlags: [.command])
        let settings = app.windows.firstMatch
        settings.staticTexts["backupPath"].click()
        settings.menuItems["Choose…"].click()
        app.typeKey("g", modifierFlags: [.shift, .command])
        app.typeText(saveBackupFolder)
        app.typeKey(.enter, modifierFlags: [])
        app.typeKey(.enter, modifierFlags: [])
        // It may take a second for the alert to show
        sleep(1)
        if app.sheets.firstMatch.exists {
            // get rid of Delete Old Backup alert
            app.sheets.firstMatch.buttons["Delete"].click()
        } else {
            settings.buttons["Close"].click()
        }
    }
}
