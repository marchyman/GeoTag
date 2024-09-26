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
        app.launchEnvironment = ["MAPTEST": "1"]
        app.launch()
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

    // search
    @MainActor
    func test0MapSearch() {
        localSetup()
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

        // Click in the search window and verify search results are
        // currently empty (only the header staticTexts exists).

        searchText.click()
        let searchResults = app.outlines.element(boundBy: 1)
        XCTAssert(searchResults.waitForExistence(timeout: 1))
        XCTAssert(searchResults.staticTexts.count == 1)

        // Search and verify at least one result was found

        searchText.typeText("New York City")
        searchText.typeKey(.return, modifierFlags: [])
        sleep(1)
        XCTAssert(searchResults.staticTexts.count > 1)

        // Save the first result as a string. Click on the result.

        let firstResult = searchResults.staticTexts.firstMatch
        let firstResultString = firstResult.value as? String
        XCTAssert(firstResultString != nil)
        print(firstResultString!)
        firstResult.click()

        let loc = app.windows.firstMatch
                    .groups.firstMatch
                    .splitGroups.firstMatch
                    .groups.firstMatch
                    .staticTexts.firstMatch
        XCTAssertTrue(loc.waitForExistence(timeout: 2))

        // save the location displayed while testing
        let firstSearchLoc = loc.value as? String
        XCTAssert(firstSearchLoc != nil)

        // Now search for another location and verify the map moved as
        // evidenced by a different "loc"

        searchText.click()
        searchText.typeText("Oakland, CA")
        searchText.typeKey(.return, modifierFlags: [])
        sleep(1)
        XCTAssert(searchResults.staticTexts.count > 1)
        searchResults.staticTexts.firstMatch.click()
        XCTAssertTrue(loc.waitForExistence(timeout: 2))
        let newLoc = loc.value as? String
        XCTAssert(firstSearchLoc != newLoc)
    }

    // Search picking previous results
    @MainActor
    func test1MapSearch() {
        localSetup()
        // save the current map location
        let loc = app.windows.firstMatch
                    .groups.firstMatch
                    .splitGroups.firstMatch
                    .groups.firstMatch
                    .staticTexts.firstMatch
        let oldLocValue = loc.value as? String

        // show search results
        let searchText = app.textFields[" Search location"]
        searchText.click()
        let searchResults = app.outlines.element(boundBy: 1)
        XCTAssert(searchResults.waitForExistence(timeout: 1))
        XCTAssertTrue(searchResults.exists)

        // make them go away
        app.buttons["Cancel"].click()
        sleep(1)
        XCTAssert(!searchResults.exists)

        // show them again and select the result from test 0.

        searchText.click()
        let oldResult = searchResults
            .outlineRows.element(boundBy: 3)
            .staticTexts.firstMatch
        XCTAssertTrue(oldResult.exists)
        oldResult.click()
        XCTAssertTrue(loc.waitForExistence(timeout: 2))
        let newLocValue = loc.value as? String

        XCTAssert(oldLocValue != newLocValue)

        XCTAssert(!searchResults.exists)
        print(searchResults.debugDescription)

        // start a search and cancel with escape key
        searchText.click()
        XCTAssert(searchResults.exists)
        searchText.typeText("a.skjdhf")
        searchText.typeKey(.escape, modifierFlags: [])
        XCTAssert(!searchResults.exists)

        // start a search and cancel
        searchText.click()
        XCTAssert(searchResults.exists)
        searchText.typeText("a.skjdhf")
        searchText.typeKey("a", modifierFlags: [.command])
        searchText.typeKey(.delete, modifierFlags: [])
        app.buttons["Close"].click()
        XCTAssert(!searchResults.exists)
    }

    // Clear saved locations and verify
    @MainActor
    func test2MapSearch() {
        localSetup()
        let searchText = app.textFields[" Search location"]
        XCTAssertTrue(searchText.exists)
        searchText.click()
        let clear = app.buttons["Clear list"]
        if clear.exists {
            clear.click()
        }
        XCTAssertFalse(clear.exists)
        app.typeKey(.escape, modifierFlags: [])
    }

    // Map context menu
    @MainActor
    func test3MapContextMenu() {
        localSetup()
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

        let searchText = app.textFields[" Search location"]
        searchText.click()
        searchText.typeText("Chicago")
        searchText.typeKey(.return, modifierFlags: [])
        let searchResults = app.outlines.element(boundBy: 1)
        XCTAssert(searchResults.waitForExistence(timeout: 1))
        let searchResult = searchResults.staticTexts.firstMatch
        searchResult.click()
        let loc = app.windows.firstMatch
                    .groups.firstMatch
                    .splitGroups.firstMatch
                    .groups.firstMatch
                    .staticTexts.firstMatch
        XCTAssertTrue(loc.waitForExistence(timeout: 2))

        // Zoom the map and save the current position
        map.doubleTap()
        map.rightClick()
        XCTAssertTrue(menu.waitForExistence(timeout: 2))
        menu.menuItems["Save map location"].click()
        app.typeKey("q", modifierFlags: [.command])
    }

    // more map context menu.
    @MainActor
    func test4MapContextMenu() {
        localSetup()
        // verify the state is correct, i.e. things changed above were
        // sticky (how can I check that the zoom level was saved?)
        XCTAssertTrue(app.buttons["ModeButton3D"].exists)

        // change back to the standard map
        let map = app.maps.firstMatch
        map.rightClick()
        let menu = app.windows.menus.firstMatch
        menu.menuItems["Standard"].click()

        // Back to the SF Bay Area
        let searchText = app.textFields[" Search location"]
        searchText.click()
        searchText.typeText("oakland, ca")
        searchText.typeKey(.return, modifierFlags: [])
        let searchResults = app.outlines.element(boundBy: 1)
        XCTAssert(searchResults.waitForExistence(timeout: 1))
        let searchResult = searchResults.staticTexts.firstMatch
        searchResult.click()
        let loc = app.windows.firstMatch
                    .groups.firstMatch
                    .splitGroups.firstMatch
                    .groups.firstMatch
                    .staticTexts.firstMatch
        XCTAssertTrue(loc.waitForExistence(timeout: 2))

        // save location and exit by closing window
        map.rightClick()
        XCTAssertTrue(menu.waitForExistence(timeout: 2))
        menu.menuItems["Save map location"].click()
        app.typeKey("w", modifierFlags: [.command])
    }
}
