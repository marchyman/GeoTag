//
//  GeoTagUI04MapTests.swift
//  GeoTagUITests
//
//  Created by Marco S Hyman on 4/1/24.
//

/*
 * Map search tests are problematic in that search results are not
 * deterministic.  If I search for Oakland, CA I usually get Oakland, CA
 * in the search results. But maybe something else with Oak in its name,
 * sometimes Oakland airport. There may even be an element of timing
 * envolved such as I get different results when testing than when driving
 * the app by hand.
 *
 * For these reasons the tests are a bit sloppy in that I accept almost
 * any results and try to act upon them.
 */

import XCTest

final class GeoTagUI04MapTests: XCTestCase {

    private var app: XCUIApplication!

    private var firstSearchResult: String!
    private var firstSearchLoc: String!

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
        // If the "Clear list" button is hidden there are no saved
        // searched.  If present click the button so the tests start with
        // a known state.
        let clear = app.buttons["Clear list"]
        if clear.exists {
            clear.click()
        }
        XCTAssertFalse(clear.exists)
        XCTAssertTrue(app.images["Search"].exists)
        XCTAssertTrue(app.buttons["Close"].exists)

        searchText.click()
        // Verify the table of search results is empty.
        let table = app.tables.firstMatch
        let searchResult = table
                            .tableRows
                            .element(boundBy: 2)
                            .staticTexts
                            .firstMatch
        XCTAssertFalse(searchResult.exists)

        searchText.typeText("New York City")
        searchText.typeKey(.return, modifierFlags: [])
        // Verify there is a search response.  It might even be New York, NY.
        XCTAssertTrue(searchResult.waitForExistence(timeout: 1))
        firstSearchResult = searchResult.value as? String
        XCTAssert(firstSearchResult != nil)
        searchResult.click()
        let loc = app.windows.firstMatch
                    .groups.firstMatch
                    .splitGroups.firstMatch
                    .groups.firstMatch
                    .staticTexts.firstMatch
        XCTAssertTrue(loc.waitForExistence(timeout: 2))

        // save the location displayed while testing
        firstSearchLoc = loc.value as? String
        XCTAssert(firstSearchLoc != nil)

        // Now search for another location and verify the map moved as
        // evidended by a different "loc"

        searchText.click()
        searchText.typeText("Oakland, CA")
        searchText.typeKey(.return, modifierFlags: [])
        XCTAssertTrue(searchResult.waitForExistence(timeout: 1))
        searchResult.click()
        XCTAssertTrue(loc.waitForExistence(timeout: 2))
        let newLoc = loc.value as? String
        XCTAssert(firstSearchLoc != newLoc)
    }

    // Search picking previous results
    func test1MapSearch() {
        if firstSearchLoc == nil {
            // must be run first
            test0MapSearch()
        }

        // show search results
        let searchText = app.textFields[" Search location"]
        searchText.click()
        let table = app.tables.firstMatch
        XCTAssertTrue(table.exists)

        // make them go away
        app.buttons["Cancel"].click()
        sleep(1)
        XCTAssertFalse(table.exists)

        // show them again and select the result from test 0.
        searchText.click()
        XCTAssertTrue(table.staticTexts[firstSearchResult].exists)
        table.staticTexts[firstSearchResult].click()
        let loc = app.windows.firstMatch
                    .groups.firstMatch
                    .splitGroups.firstMatch
                    .groups.firstMatch
                    .staticTexts.firstMatch
        XCTAssertTrue(loc.waitForExistence(timeout: 2))
        let thisLoc = loc.value as? String
        XCTAssert(firstSearchLoc == thisLoc)

        // the table should be gone
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
    }

//    // verify that the list of saved searches is actually empty
//    func test2MapSearch() {
//        let searchText = app.textFields[" Search location"]
//        searchText.click()
//        let table = app.tables.firstMatch
//        XCTAssertFalse(table.tableRows.element(boundBy: 4).exists)
//        app.buttons["Cancel"].click()
//    }

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
