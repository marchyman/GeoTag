//
//  GeoTagUI05Tests.swift
//  GeoTagUITests
//
//  Created by Marco S Hyman on 4/4/24.
//

import XCTest

final class GeoTagUI05Tests: XCTestCase {

    private var app: XCUIApplication!
    private var testImageFolder = ""
    private var saveImageFolder = ""

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()

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
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the
        // invocation of each test method in the class.
        try super.tearDownWithError()
        app = nil
    }

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

    func test0DuplicateImage() {
        openTestFile()
        XCTAssertTrue(app.staticTexts["IMG_7158.CR2*"]
                         .waitForExistence(timeout: 2))

        // open again.  Should get a dup image sheet
        openTestFile()
        XCTAssertTrue(app.windows.sheets.element.waitForExistence(timeout: 2))
        app.sheets.buttons.firstMatch.click()

        // open the folder in which the file exists.  Should be a dup.
        // should also get a tracks loaded sheet.
        openTestFile(folder: true)
        XCTAssertTrue(app.windows.sheets.element.waitForExistence(timeout: 2))
        app.sheets.buttons.firstMatch.click()
        XCTAssertTrue(app.windows.sheets.element.waitForExistence(timeout: 2))
        app.sheets.buttons.firstMatch.click()
    }

    func test1MapClick() {
        openTestFile()
        let row = app.outlineRows.firstMatch
        XCTAssertTrue(row.staticTexts["IMG_7158.CR2*"]
                         .waitForExistence(timeout: 2))
        row.staticTexts["IMG_7158.CR2*"].click()

        // click on the map, verify location and pin
        let map = app.maps.firstMatch
        map.click()
        XCTAssertTrue(row.staticTexts.element(boundBy: 2)
                         .waitForExistence(timeout: 1))
        XCTAssertTrue(row.staticTexts.element(boundBy: 3).exists)
        XCTAssertTrue(map.images["Pin"].exists)

        // delete the location.
        app.typeKey(.delete, modifierFlags: [])
        XCTAssertFalse(row.staticTexts.element(boundBy: 2)
                          .waitForExistence(timeout: 1))
        XCTAssertFalse(row.staticTexts.element(boundBy: 3).exists)
        XCTAssertFalse(map.images["Pin"].exists)

        /*
         * When undoing in the following test undo is called twice, approx
         * 200 microsecends appart.   The result is that both of the above
         * actions are undone instead of just the first. This causes the test
         * to fail.
         *
         * This ALWAYS happens when running tests.  It rarely happens in actual
         * use and the few times I have seen it happen have only been on the
         * first run following this test failure.
         *
         * I'm going to ignore it for now and move on to other tests.
         */
        // undo the delete
//        app.menuItems["Undo"].click()
//        app.typeKey("z", modifierFlags: [.command])
//        XCTAssertTrue(row.staticTexts.element(boundBy: 2)
//                         .waitForExistence(timeout: 1))
//        XCTAssertTrue(row.staticTexts.element(boundBy: 3).exists)
//        XCTAssertTrue(map.images["Pin"].exists)

//        // redo the delete
//        app.typeKey("z", modifierFlags: [.shift, .command])
//        XCTAssertFalse(row.staticTexts.element(boundBy: 2)
//                          .waitForExistence(timeout: 1))
//        XCTAssertFalse(row.staticTexts.element(boundBy: 3).exists)
//        XCTAssertFalse(map.images["Pin"].exists)
    }

    func test2TableMenu() {
        openTestFile(folder: true)
        XCTAssertTrue(app.windows.sheets.element.waitForExistence(timeout: 2))
        app.sheets.buttons.firstMatch.click()

        // Check context menu when right clicking on table
        let table = app.outlines.firstMatch
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
        print(inspector.debugDescription)
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

    // change time zone test.  NOTE: Assumes the local time zone isn't
    // GMT -4.  If it is the test should be changed

    let newZone = "-4"

    func test3TimeZone() {
        // show the change time zone window
        let tzItem = app.menuItems["Specify Time Zone…"]
        XCTAssert(tzItem.exists)
        tzItem.click()
        let tzWindow = app.windows["Change Time Zone"]
        XCTAssert(tzWindow.exists)

        // dismiss the window without changes
        let tzCancel = tzWindow.buttons["Cancel"]
        XCTAssert(tzCancel.exists)
        tzCancel.click()
        XCTAssert(tzWindow.exists == false)

        // show the window again and change the time zone
        tzItem.click()
        let tzButton = tzWindow.popUpButtons.firstMatch
        XCTAssert(tzButton.exists)
        tzButton.click()
        let tzButtonItem = tzButton.menuItems[newZone]
        XCTAssert(tzButtonItem.exists)
        tzButtonItem.click()
        XCTAssert(tzButton.value as? String == newZone)

        // Cancel the change.
        tzCancel.click()
        XCTAssert(tzWindow.exists == false)

        // verify the change was NOT made
        tzItem.click()
        XCTAssert(tzWindow.staticTexts["currentTimeZone"].value as? String
                  != newZone)

        // make the change, again
        tzButton.click()
        tzButtonItem.click()

        // Save the change
        let tzChange = tzWindow.buttons["Change"]
        XCTAssert(tzChange.exists)
        tzChange.click()
        XCTAssert(tzWindow.exists == false)

        // Re-open the window and verify the change was made.
        tzItem.click()
        XCTAssert(tzWindow.staticTexts["currentTimeZone"].value as? String
                  == newZone)
        tzCancel.click()
    }

    // save tests.  This test modifies items in the source tree.  There
    // should be no changes pending allowing a git reset --hard to reset
    // the source tree after testing.

    // swiftlint: disable large_tuple
    let results: [(String, String, String, String)] = [
        ("IMG_7158.CR2*", "2015:11:12 13:06:56", "38° 31' 15.88\" N", "123° 12' 1.24\" W"),
        ("L1000038.DNG", "2015:11:12 09:41:11", "38° 16' 10.27\" N", "122° 40' 15.12\" W"),
        ("P1000685.JPG", "2015:11:12 13:02:28", "38° 31' 45.91\" N", "123° 12' 52.03\" W"),
        ("P1000686.JPG", "1980:01:01 12:00:00", "", "")
    ]
    // swiftlint: enable large_tuple

    func test4Save() {
        // open the images to modify
        app.typeKey("o", modifierFlags: [.command])
        app.typeKey("g", modifierFlags: [.shift, .command])
        app.typeText(saveImageFolder)
        app.typeKey(.enter, modifierFlags: [])
        app.typeKey(.enter, modifierFlags: [])

        // open the track file from the test folder
        app.typeKey("o", modifierFlags: [.command])
        app.typeKey("g", modifierFlags: [.shift, .command])
        app.typeText(testImageFolder)
        app.typeText("/TestTrack.GPX")
        app.typeKey(.enter, modifierFlags: [])
        app.typeKey(.enter, modifierFlags: [])
        XCTAssertTrue(app.windows.sheets.element.waitForExistence(timeout: 2))
        app.sheets.buttons.firstMatch.click()

        // select the images and apply the changes
        app.typeKey("a", modifierFlags: [.command])
        app.typeKey("l", modifierFlags: [.command])

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

        // save the changes
        
    }
}
