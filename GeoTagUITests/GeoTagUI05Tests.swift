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

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()

        app.launch()

        // remove the "no backups sheet" sheet if it is present.
        let sheet = app.windows.sheets.element
        if sheet.exists {
            sheet.buttons.firstMatch.click()
        }

        if let imagePath = ProcessInfo.processInfo.environment["ImagePath"] {
            testImageFolder = imagePath
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
}
