//
//  GeoTagUI06Save.swift
//  GeoTagUITests
//
//  Created by Marco S Hyman on 4/18/24.
//

import XCTest

final class GeoTagUI06Save: XCTestCase {

    private var app: XCUIApplication!
    private var testImageFolder = ""
    private var saveImageFolder = ""
    private var saveBackupFolder = ""

    override func setUp() {
        continueAfterFailure = false
        app = XCUIApplication()
        // force the first save to fail
        app.launchEnvironment = ["BACKUP": NSTemporaryDirectory()]
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

    override func tearDown() {
        // Put teardown code here. This method is called after the
        // invocation of each test method in the class.
        super.tearDown()
        app = nil
    }

    // save tests.  This test modifies items in the source tree.  There
    // should be no changes pending allowing a git reset --hard to reset
    // the source tree after testing.

    // swiftlint: disable large_tuple
    let results: [(String, String, String, String)] = [
        ("IMG_7158.CR2*", "2015:11:12 13:06:56", "38° 31' 15.88\" N", "123° 12' 1.24\" W"),
        ("L1000038.DNG", "2015:11:12 09:41:11", "38° 16' 10.27\" N", "122° 40' 15.12\" W"),
        ("P1000685.JPG", "2015:11:12 13:02:28", "38° 31' 45.91\" N", "123° 12' 52.03\" W"),
        ("P1000686.JPG", "1980:02:01 12:00:00", "", "")
    ]
    // swiftlint: enable large_tuple

    func test0Save() {
        openImages()
        openTrack()
        applyTrackLocations()
        adjustImageTime()
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
    func openImages() {
        app.typeKey("o", modifierFlags: [.command])
        app.typeKey("g", modifierFlags: [.shift, .command])
        app.typeText(saveImageFolder)
        app.typeKey(.enter, modifierFlags: [])
        app.typeKey(.enter, modifierFlags: [])
        XCTAssert(app.outlines.firstMatch.waitForExistence(timeout: 1))
    }

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

    func applyTrackLocations() {
        // select the images and apply the changes
        app.typeKey("a", modifierFlags: [.command])
        app.typeKey("l", modifierFlags: [.command])
    }

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

    func verifyResults() {
        for ix in 0 ..< results.count {
            XCTAssert(app.outlineRows.element(boundBy: ix)
                .staticTexts[results[ix].0].exists)
            XCTAssert(app.outlineRows.element(boundBy: ix)
                .staticTexts[results[ix].1].exists)
            if ix == results.count - 1 {
                break
            }
            XCTAssert(app.outlineRows.element(boundBy: ix)
                .staticTexts[results[ix].2].exists)
            XCTAssert(app.outlineRows.element(boundBy: ix)
                .staticTexts[results[ix].3].exists)
        }
    }

    func saveWithBadBackupFolder() {
        app.typeKey("s", modifierFlags: [.command])
        XCTAssert(app.sheets.firstMatch.waitForExistence(timeout: 1))
        XCTAssert(app.sheets.firstMatch.buttons["Dismiss"].exists)
        app.sheets.firstMatch.buttons["Dismiss"].click()
    }

    func setBackupFolder() {
        app.typeKey(",", modifierFlags: [.command])
        let settings = app.windows.firstMatch
        settings.staticTexts["backupPath"].click()
        settings.menuItems["Choose…"].click()
        app.typeKey("g", modifierFlags: [.shift, .command])
        app.typeText(saveBackupFolder)
        app.typeKey(.enter, modifierFlags: [])
        app.typeKey(.enter, modifierFlags: [])
        settings.buttons["Close"].click()
    }
}
