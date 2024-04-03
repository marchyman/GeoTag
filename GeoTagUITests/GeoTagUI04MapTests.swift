//
//  GeoTagUI04MapTests.swift
//  GeoTagUITests
//
//  Created by Marco S Hyman on 4/1/24.
//

import XCTest

final class GeoTagUI04MapTests: XCTestCase {

    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false

        app = XCUIApplication()
        app.launchEnvironment = ["MAPTEST": "1"]
        app.launch()
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the
        // invocation of each test method in the class.
        try super.tearDownWithError()
        app = nil
    }

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

    // search
    func test0MapSearch() {
        let map = app.maps.firstMatch
        XCTAssertTrue(map.exists)
        let searchText = app.textFields[" Search location"]
        XCTAssertTrue(searchText.exists)
        searchText.click()
        takeScreenshot(name: "MapSearch")
        XCTAssertTrue(app.buttons["Cancel"].exists)
        // Clear list button it hidden if the list is empty
        // XCTAssertTrue(app.buttons["Clear list"].exists)
        XCTAssertTrue(app.images["Search"].exists)
        XCTAssertTrue(app.buttons["Close"].exists)
        searchText.click()
        searchText.typeText("New York City")
        searchText.typeKey(.return, modifierFlags: [])
        XCTAssertTrue(app.tableRows.element(boundBy: 2)
                      .staticTexts["New York, NY"].waitForExistence(timeout: 2))
        app.tableRows.element(boundBy: 2).staticTexts["New York, NY"].click()
        sleep(2)
        if let value = app.staticTexts.firstMatch.value as? String {
            XCTAssertFalse(value.hasPrefix("Lat: 40."))
        } else {
            XCTAssert(false, "wrong location")
        }
    }

    // Search picking previous results
    func test1MapSearch() {
        // show search results
        let searchText = app.textFields[" Search location"]
        searchText.click()
        let table = app.tables.firstMatch
        XCTAssertTrue(table.exists)

        // make them go away
        app.buttons["Cancel"].click()
        XCTAssertFalse(table.exists)

        // show them again and select New York.
        searchText.click()
        XCTAssertTrue(table.staticTexts["New York, NY"].exists)
        table.staticTexts["New York, NY"].click()
        sleep(2)
        if let value = app.staticTexts.firstMatch.value as? String {
            XCTAssertFalse(value.hasPrefix("Lat: 40."))
        } else {
            XCTAssert(false, "wrong location")
        }
        XCTAssertFalse(table.exists)

        // start a search and cancel with escape key
        searchText.click()
        XCTAssertTrue(table.exists)
        searchText.typeText("a.skjdhf")
        searchText.typeKey(.escape, modifierFlags: [])
        XCTAssertFalse(table.exists)

        // start a search and cancel
        searchText.click()
        XCTAssertTrue(table.exists)
        searchText.typeText("a.skjdhf")
        searchText.typeKey("a", modifierFlags: [.command])
        searchText.typeKey(.delete, modifierFlags: [])
        app.buttons["Close"].click()
        XCTAssertFalse(table.exists)

        // clear the list of saved entries
        searchText.click()
        XCTAssertTrue(table.exists)
        app.buttons["Clear list"].click()
        XCTAssertFalse(table.tableRows.element(boundBy: 4).exists)
        app.buttons["Cancel"].click()
    }

    // verify that the list of saved searches is actually empty
    func test2MapSearch() {
        let searchText = app.textFields[" Search location"]
        searchText.click()
        let table = app.tables.firstMatch
        XCTAssertFalse(table.tableRows.element(boundBy: 4).exists)
        app.buttons["Cancel"].click()
    }

    // Map context menu
    func test3MapContextMenu() {
        let map = app.maps.firstMatch
        map.rightClick()
        let menu = app.windows.menus.firstMatch
        XCTAssertTrue(menu.waitForExistence(timeout: 2))
        XCTAssertTrue(menu.menuItems["Standard"].exists)
        XCTAssertTrue(menu.menuItems["Imagery"].exists)
        XCTAssertTrue(menu.menuItems["Hybrid"].exists)
        XCTAssertTrue(menu.menuItems["Save map location"].exists)
        menu.menuItems["Hybrid"].click()
        XCTAssertFalse(menu.exists)
        XCTAssertTrue(app.buttons["ModeButton3D"].exists)

        // position the map and save the current position
        let searchText = app.textFields[" Search location"]
        searchText.click()
        searchText.typeText("Bakersfield, CA")
        searchText.typeKey(.return, modifierFlags: [])
        XCTAssertTrue(app.staticTexts["Bakersfield, CA"].waitForExistence(timeout: 2))
        app.staticTexts["Bakersfield, CA"].click()
        map.rightClick()
        XCTAssertTrue(menu.waitForExistence(timeout: 2))
        menu.menuItems["Save map location"].click()
        app.typeKey("q", modifierFlags: [.command])
    }

    // more map context menu.
    func test4MapContextMenu() {
        // verify the state is correct, i.e. things changed above were
        // sticky
        XCTAssertTrue(app.buttons["ModeButton3D"].exists)
        if let value = app.staticTexts.firstMatch.value as? String {
            XCTAssertFalse(value.hasPrefix("35.373333"))
        } else {
            XCTAssert(false, "wrong location")
        }

        // change back to the standard map
        let map = app.maps.firstMatch
        map.rightClick()
        let menu = app.windows.menus.firstMatch
        menu.menuItems["Standard"].click()

        // Back to the SF Bay Area
        let searchText = app.textFields[" Search location"]
        searchText.click()
        let table = app.tables.firstMatch
        XCTAssertTrue(table.exists)
        searchText.typeText("oakland, ca")
        searchText.typeKey(.return, modifierFlags: [])
        XCTAssertTrue(table.staticTexts["Oakland, CA"].waitForExistence(timeout: 2))
        table.staticTexts["Oakland, CA"].click()
        map.rightClick()
        XCTAssertTrue(menu.waitForExistence(timeout: 2))
        menu.menuItems["Save map location"].click()
    }
}
