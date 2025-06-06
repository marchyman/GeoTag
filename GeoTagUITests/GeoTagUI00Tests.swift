//
// Copyright 2019 Marco S Hyman
// See LICENSE file for info
// https://www.snafu.org/
//

import XCTest

final class GeoTagUI00Tests: XCTestCase {

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
    func localSetup() {
        app = XCUIApplication()
        app.launchEnvironment = ["UITESTS": "1"]
        app.launch()

        // Now set up user defaults for testing.  The app should be showing
        // a sheet saying no backup file exists.  Dismiss the sheet.

        let sheet = app.windows.sheets.element
        XCTAssert(sheet.waitForExistence(timeout: 2))
        takeScreenshot(name: "InitialLaunch")
        sheet.buttons.firstMatch.click()
        takeScreenshot(name: "Launch")
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

    // test that app contains the normal elements at initial launch and that
    // the appropriate menu items appear.
    @MainActor
    func test0Startup() {
        localSetup()
        let window = app.windows["main"]
        XCTAssert(window.exists)
        XCTAssertEqual(window.descendants(matching: .tableColumn).count, 4)
        XCTAssertEqual(window.descendants(matching: .image).count, 4)
        XCTAssert(window.descendants(matching: .map).element.exists)
        XCTAssert(window.descendants(matching: .toolbar).element.exists)

        XCTAssert(app.buttons["Toggle Inspector"].exists)
        app.buttons["Toggle Inspector"].firstMatch.click()
        XCTAssert(app.staticTexts["Please select an image"].waitForExistence(timeout: 2))
        takeScreenshot(name: "Inspector")
        app.buttons["Toggle Inspector"].firstMatch.click()
        XCTAssert(app.searchFields["Image name"].exists)

        // The photo picker does not show up as one of the apps XCUIElements.
        // I can take a screenshot.
        XCTAssert(app.buttons["Photo Library"].exists)
        app.buttons["Photo Library"].firstMatch.click()
        sleep(1)
        takeScreenshot(name: "Photo Library")
        app.buttons["Cancel"].click()

        let menubar = app.menuBars.element
        XCTAssert(menubar.exists)
        XCTAssertEqual(menubar.children(matching: .menuBarItem).count, 7)
        menuBarItem0(menubar.children(matching: .menuBarItem).element(boundBy: 0))
        menuBarItem1(menubar.children(matching: .menuBarItem).element(boundBy: 1))
        menuBarItem2(menubar.children(matching: .menuBarItem).element(boundBy: 2))
        menuBarItem3(menubar.children(matching: .menuBarItem).element(boundBy: 3))
        menuBarItem4(menubar.children(matching: .menuBarItem).element(boundBy: 4))
        menuBarItem5(menubar.children(matching: .menuBarItem).element(boundBy: 5))
        menuBarItem6(menubar.children(matching: .menuBarItem).element(boundBy: 6))
    }

    // set the "no backup" flag in Settings to get rid of the warning sheet
    // when the app is launched in future tests.
    @MainActor
    func test1SetNoBackup() {
        localSetup()
        app.menuItems["Settings…"].click()
        XCTAssert(app.windows["GeoTag Settings"].waitForExistence(timeout: 2))
        app.checkBoxes["Disable image backups"].click()
        app.buttons["Close"].click()
    }

    // Apple menu
    @MainActor
    func menuBarItem0(_ item: XCUIElement) {
        XCTAssert(item.exists)
    }

    // GeoTag menu
    @MainActor
    func menuBarItem1(_ item: XCUIElement) {
        XCTAssert(item.exists)
        XCTAssertEqual(item.title, "GeoTag")
        XCTAssert(item.descendants(matching: .menuItem)["About GeoTag"].exists)
        XCTAssert(item.descendants(matching: .menuItem)["Settings…"].exists)
        XCTAssert(item.descendants(matching: .menuItem)["Quit GeoTag"].exists)
    }

    // File menu
    @MainActor
    func menuBarItem2(_ item: XCUIElement) {
        XCTAssert(item.exists)
        XCTAssertEqual(item.title, "File")
        XCTAssertGreaterThan(item.descendants(matching: .menuItem).count, 6)
        XCTAssert(item.descendants(matching: .menuItem)["Open…"].exists)
        XCTAssert(item.descendants(matching: .menuItem)["Close"].exists)
        XCTAssert(item.descendants(matching: .menuItem)["Save…"].exists)
        XCTAssert(item.descendants(matching: .menuItem)["Discard changes"].exists)
        XCTAssert(item.descendants(matching: .menuItem)["Discard tracks"].exists)
        XCTAssert(item.descendants(matching: .menuItem)["Clear Image List"].exists)
    }

    // Edit menu
    @MainActor
    func menuBarItem3(_ item: XCUIElement) {
        XCTAssert(item.exists)
        XCTAssertEqual(item.title, "Edit")
        XCTAssertGreaterThan(item.descendants(matching: .menuItem).count, 10)
        XCTAssert(item.descendants(matching: .menuItem)["Undo"].exists)
        XCTAssert(item.descendants(matching: .menuItem)["Redo"].exists)
        XCTAssert(item.descendants(matching: .menuItem)["Cut"].exists)
        XCTAssert(item.descendants(matching: .menuItem)["Copy"].exists)
        XCTAssert(item.descendants(matching: .menuItem)["Paste"].exists)
        XCTAssert(item.descendants(matching: .menuItem)["Delete"].exists)
        XCTAssert(item.descendants(matching: .menuItem)["Select All"].exists)
        XCTAssert(item.descendants(matching: .menuItem)["Show In Finder"].exists)
        XCTAssert(item.descendants(matching: .menuItem)["Locn From Track"].exists)
        XCTAssert(item.descendants(matching: .menuItem)["Specify Time Zone…"].exists)
    }

    // View menu
    @MainActor
    func menuBarItem4(_ item: XCUIElement) {
        XCTAssert(item.exists)
        XCTAssertEqual(item.title, "View")
        XCTAssert(item.descendants(matching: .menuItem)["Hide Disabled Files"].exists)
        XCTAssert(item.descendants(matching: .menuItem)["Pin view options…"].exists)
        XCTAssert(item.descendants(matching: .menuItem)["Show pins for all selected items"].exists)
        XCTAssert(item.descendants(matching: .menuItem)["Show pin for most selected item"].exists)
    }

    // Window menu
    @MainActor
    func menuBarItem5(_ item: XCUIElement) {
        XCTAssert(item.exists)
        XCTAssertEqual(item.title, "Window")
    }

    // Help menu
    @MainActor
    func menuBarItem6(_ item: XCUIElement) {
        XCTAssert(item.exists)
        XCTAssertEqual(item.title, "Help")
        XCTAssert(item.descendants(matching: .menuItem)["GeoTag 5 Help…"].exists)
        XCTAssert(item.descendants(matching: .menuItem)["Report a bug…"].exists)
        XCTAssert(item.descendants(matching: .menuItem)["Show log…"].exists)
    }

}
