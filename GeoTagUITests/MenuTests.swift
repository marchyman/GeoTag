//
//  MenuTests.swift
//  GeoTagUITests
//
//  Created by Marco S Hyman on 8/6/18.
//  Copyright © 2018 Marco S Hyman. All rights reserved.
//

import XCTest

/// GeoTag main menu startup UI checks
class B_MenuTests: XCTestCase {

    let app = XCUIApplication()
    let menuBarsQuery = XCUIApplication().menuBars

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
        XCUIApplication().launch()

        // In UI tests it’s important to set the initial state required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func geoTagMenu() {
        menuBarsQuery.menuBarItems["GeoTag"].click()
        menuBarsQuery/*@START_MENU_TOKEN@*/.menuItems["About GeoTag"]/*[[".menuBarItems[\"GeoTag\"]",".menus.menuItems[\"About GeoTag\"]",".menuItems[\"About GeoTag\"]"],[[[-1,2],[-1,1],[-1,0,1]],[[-1,2],[-1,1]]],[0]]@END_MENU_TOKEN@*/.click()
        XCTAssertTrue(app.dialogs.element.exists)
        app.dialogs.buttons[XCUIIdentifierCloseWindow].click()
    }

    func fileMenu() {
        let fileMenu = menuBarsQuery.menuBarItems["File"]
        fileMenu.click()
        let fileMenuSearch = fileMenu.descendants(matching: .menuItem)
        XCTAssertEqual(fileMenuSearch.count, 8)

        let menuNames = [("Open…", true),
                         ("Close", true),
                         ("Save", false),
                         ("Discard changes", false),
                         ("Clear image list", false)]

        for (name, enabled) in menuNames {
            let item = fileMenuSearch[name]
            XCTAssertTrue(item.exists)
            XCTAssertEqual(item.isEnabled, enabled)
        }
    }

    func editMenu() {
        let editMenu = menuBarsQuery.menuBarItems["Edit"]
        editMenu.click()
        let editMenuSearch = editMenu.descendants(matching: .menuItem)
        // 11 items that the programs is responsible for, the OS may add more
        XCTAssert(editMenuSearch.count >= 11)

        let menuNames = ["Undo", "Redo", "Cut", "Copy", "Paste", "Delete",
                         "Interpolate", "Locn from track", "Modify Date/Time"]

        // all of the above listed menu items must exist and not be enabled.
        for name in menuNames {
            let item = editMenuSearch[name]
            XCTAssertTrue(item.exists)
            XCTAssertFalse(item.isEnabled)
        }
    }

    func windowMenu() {
        let windowMenu = menuBarsQuery.menuBarItems["Window"]
        windowMenu.click()
        let windowMenuSearch = windowMenu.descendants(matching: .menuItem)
        // The count includes option key variants
        XCTAssertEqual(windowMenuSearch.count, 10)

        let menuNames = ["Minimize", "Zoom", "Enter Full Screen",
                         "Bring All to Front", "GeoTag"]

        // all of the above listed menu items must exist and not be enabled.
        for name in menuNames {
            let item = windowMenuSearch[name]
            XCTAssertTrue(item.exists)
            XCTAssertTrue(item.isEnabled)
        }
    }

    func helpMenu() {
         menuBarsQuery.menuBarItems["Help"].click()
        // I don't know how to check if the help window is present or
        // dismiss it when done.   For now just check that the help item
        // is in the menu.
        XCTAssertTrue(menuBarsQuery/*@START_MENU_TOKEN@*/.menuItems["GeoTag Help"]/*[[".menuBarItems[\"Help\"]",".menus.menuItems[\"GeoTag Help\"]",".menuItems[\"GeoTag Help\"]"],[[[-1,2],[-1,1],[-1,0,1]],[[-1,2],[-1,1]]],[0]]@END_MENU_TOKEN@*/.exists)
    }

    func rightClickMenu() {
        let table = app.windows["GeoTag"].tables.firstMatch
        table.rightClick()
        let tableMenu = app.menus["tableMenu"]
        XCTAssert(tableMenu.exists)
        let tableMenuSearch = tableMenu.descendants(matching: .menuItem)
        XCTAssertEqual(tableMenuSearch.count, 11)

        let menuNames = ["Cut", "Copy", "Paste", "Delete", "Interpolate",
                         "Locn from track", "Modify Date/Time",
                         "Modify Location", "Clear image list" ]

        // all of the above listed menu items must exist and not be enabled.
        for name in menuNames {
            let item = tableMenuSearch[name]
            XCTAssertTrue(item.exists)
            XCTAssertFalse(item.isEnabled)
        }
    }

    func testMenus() {
        geoTagMenu()
        fileMenu()
        editMenu()
        windowMenu()
        helpMenu()
        rightClickMenu()
    }

}
