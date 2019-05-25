//
//  OpenTests.swift
//  GeoTagUITests
//
//  Created by Marco S Hyman on 8/7/18.
//  Copyright © 2018 Marco S Hyman. All rights reserved.
//

import XCTest

/// tests pertaining to the table view portion of the app window.

class C_TableTests: XCTestCase {

    // The name of the folder containing test images
    // will grab name from bundle at setup
    var testFolder = ""

    // number of test files in the image folder (not counting xmp files)
    let fileCount = 15

    // the name of the GPX test file
    // will grab name from bundle at setup
    var testGPX = ""

    // the name of specific files used in the tests
    let cr2Image = "IMG_7158.CR2"
    let cr2ImageStar = "IMG_7158.CR2*"   // * indicates presence of a sidecar file
    let cr2Lat = " 38.521077"
    let cr2Lon = "-123.200344"
    let jpgImage = "P1000686.JPG"
    let fooFile = "image.foo"

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // get paths to test data
        let bundle = Bundle(for: type(of: self))
        if let url = bundle.url(forResource: "TestPictures", withExtension: nil) {
            testFolder = url.path
        } else {
            XCTFail("Cannot find test pictures folder")
        }
        if let url = bundle.url(forResource: "TestTrack", withExtension: "GPX") {
            testGPX = url.path
        } else {
            XCTFail("Cannot find test gpx file")
        }

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
        XCUIApplication().launch()

        // In UI tests it’s important to set the initial state required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    @discardableResult
    func commonOpen(fileOrFolder: String) -> XCUIElement {
        let app = XCUIApplication()
        let table = app.windows["GeoTag"].tables.element
        XCTAssertTrue(table.exists)
        table.typeKey("o", modifierFlags:.command)

        // The open files dialog should be on the screen

        let dialog = app.dialogs.element
        XCTAssertTrue(dialog.exists)
        dialog.typeKey("G", modifierFlags: [.shift, .command])
        let sheet = dialog.descendants(matching: .sheet).element
        XCTAssertTrue(sheet.exists)
        sheet.typeText(fileOrFolder)
        XCTAssertTrue(sheet.buttons["Go"].exists)
        sheet.buttons["Go"].click()
        let button = dialog.buttons["Open"]
        XCTAssertTrue(button.exists)
        button.click()
        // wait a good long while for background tasks to finish
        sleep(5)
        return table
    }

    func twoFileOpen() {
        let app = XCUIApplication()
        let table = app.windows["GeoTag"].tables.element
        XCTAssertTrue(table.exists)
        table.typeKey("o", modifierFlags:.command)
        let dialog = app.dialogs.element
        XCTAssertTrue(dialog.exists)
        dialog.typeKey("G", modifierFlags: [.shift, .command])
        let sheet = dialog.descendants(matching: .sheet).element
        XCTAssertTrue(sheet.exists)
        sheet.typeText(testFolder + "/" + jpgImage)
        XCTAssertTrue(sheet.buttons["Go"].exists)
        sheet.buttons["Go"].click()
//        dialog.textFields[jpgImage].click()
        XCUIElement.perform(withKeyModifiers: .command) {
            dialog.textFields[cr2Image].click()
        }
        let button = dialog.buttons["Open"]
        XCTAssertTrue(button.exists)
        // wait a good long while for background tasks to finish
        button.click()
        sleep(2)
    }

    /// Wait for an elements value that is being updated asynchronously to change

    func waitForValue(_ element: XCUIElement,
                      value: String,
                      timeout: TimeInterval = 10,
                      file: String = #file,
                      line: Int = #line) {
        let changePredicate = NSPredicate(format: "value == \"\(value)\"")
        expectation(for: changePredicate,  evaluatedWith: element)
        waitForExpectations(timeout: timeout) {
            (error) -> Void in
            if (error != nil) {
                let message = "Failed to change \(element) to \"\(value)\" after \(timeout) seconds."
                self.recordFailure(withDescription: message,
                                   inFile: file, atLine: line, expected: true)
            }
        }
    }

    func undo(name: String) {
        let editMenu = XCUIApplication().menuBarItems["Edit"]
        editMenu.click()
        let undo = editMenu.menuItems[name]
        XCTAssertTrue(undo.exists)
        undo.click()
    }

    /// discard changes
    func discardChanges() {
        let fileMenu = XCUIApplication().menuBarItems["File"]
        fileMenu.click()
        let discardItem = fileMenu.menuItems["Discard changes"]
        discardItem.click()
    }

    /// open a folder full of images with a few non images, too.
    func test1Open() {
        let table = commonOpen(fileOrFolder: testFolder)
        XCTAssertEqual(table.descendants(matching: .tableRow).count, fileCount)
        XCTAssertTrue(table.staticTexts[cr2ImageStar].exists)
        XCTAssertTrue(table.staticTexts[cr2ImageStar].isEnabled)
        // verify non image files can not be selected
        let fooItem = table.staticTexts[fooFile]
        XCTAssertTrue(fooItem.exists)
        fooItem.click()
        XCTAssertFalse(fooItem.isSelected)
}

    /// open a gpx track log
    func test2Open() {
        commonOpen(fileOrFolder: testGPX)

        // Dismiss the GPX Track Loaded alert

        let sheet = XCUIApplication().sheets.element
        XCTAssertTrue(sheet.exists)
        let button = sheet.buttons["Close"]
        XCTAssertTrue(button.exists)
        button.click()
    }

    /// test that the name and date/time columns can be sorted
    func test3Sort() {
        let table = commonOpen(fileOrFolder: testFolder)
        XCTAssertEqual(table.descendants(matching: .tableRow).count, fileCount)
        let texts = table.staticTexts

        // sort by name
        let imageNameColumnButton = table.buttons["Image Name"]
        XCTAssertTrue(imageNameColumnButton.exists)
        imageNameColumnButton.click()
        XCTAssertEqual(texts.element(boundBy: 0).value as! String, cr2ImageStar)
        // invert the sort and check again
        imageNameColumnButton.click()
        XCTAssertEqual(texts.element(boundBy: 0).value as! String, fooFile)

        // sort by Date/Time (2nd column, index 1)
        let dateTimeColumnButton = table.buttons["Date/Time"]
        XCTAssertTrue(dateTimeColumnButton.exists)
        dateTimeColumnButton.click()
        XCTAssertEqual(texts.element(boundBy: 1).value as! String, "")
        // invert the sort and check again
        dateTimeColumnButton.click()
        XCTAssertEqual(texts.element(boundBy: 1).value as! String,
                       "2015:11:12 13:08:23")
    }

    /// open specific files
    func test4Open() {
        twoFileOpen()
        let table = XCUIApplication().windows["GeoTag"].tables.element
        XCTAssertTrue(table.staticTexts[jpgImage].exists)
        XCTAssertTrue(table.staticTexts[cr2ImageStar].exists)
    }

    /// Open files and a track log. Update location from the track log
    func test5TrackLog() {
        test1Open()
        test2Open()

        let app = XCUIApplication()
        let table = app.windows["GeoTag"].tables.element
        let texts = table.staticTexts
        
        // sort by name=
        let imageNameColumnButton = table.buttons["Image Name"]
        XCTAssertTrue(imageNameColumnButton.exists)
        imageNameColumnButton.click()
        XCTAssertEqual(texts.element(boundBy: 0).value as! String, cr2ImageStar)

        // column 2 and 3 are lat/lon
        // they should be empty strings
        XCTAssertEqual(texts.element(boundBy: 2).value as! String, "")
        XCTAssertEqual(texts.element(boundBy: 3).value as! String, "")

        // Select all and assign locations from track log
        table.typeKey("a", modifierFlags:.command)
        table.typeKey("l", modifierFlags:.command)

        // check lat/lon assigned
        let lat = texts.element(boundBy: 2)
        waitForValue(lat, value: cr2Lat)
        let lon = texts.element(boundBy: 3)
        waitForValue(lon, value: cr2Lon)

        discardChanges()
    }

    /// undo/redo tests were not working.  Removed for now
}
