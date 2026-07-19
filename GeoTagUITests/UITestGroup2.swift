import XCTest

@MainActor
final class UITestGroup2: XCTestCase {

    override func setUp() async throws {
        continueAfterFailure = false
    }

    private func element(_ app: XCUIApplication,
                         matching id: String,
                         index: Int = 0) -> XCUIElement {
        return app.descendants(matching: .any)
                  .matching(identifier: id)
                  .element(boundBy: index)
    }

    func testAPathView() async throws {
        let dismissID = TestIDs.DismissModifier.dismissButtonID
        let pathViewID = TestIDs.SettingsView.pathViewID
        let settingsID = "Settings…"
        let closeButtonID = TestIDs.SettingsView.closeID

        let app = XCUIApplication()
        app.launchArguments.append("-NOBACKUPFOLDER")
        app.activate()
        let dismissButton = element(app, matching: dismissID)
        if dismissButton.exists {
            dismissButton.click()
        }
        let settingsButton = element(app, matching: settingsID)
        XCTAssert(settingsButton.exists)
        settingsButton.click()

        let pathView = element(app, matching: pathViewID)
        XCTAssert(pathView.exists)
        pathView.click()
        pathView.menuItems["Choose…"].click()
        app.typeKey("g", modifierFlags: [.shift, .command])
        app.typeText("/tmp")
        app.typeKey(.enter, modifierFlags: [])
        app.typeKey(.enter, modifierFlags: [])

        let closeButton = element(app, matching: closeButtonID)
        XCTAssert(closeButton.exists)
        closeButton.click()

        // now check that the path we set is the path shown
        settingsButton.click()
        pathView.click()
        XCTAssert(pathView.menuItems["tmp"].exists)
        closeButton.click()

        app.typeKey("q", modifierFlags: [.command])
    }

    func testBContextMenuView() async throws {
        let app = XCUIApplication()
        app.launchArguments.append("-NOBACKUP")
        app.activate()
        var testImageFolder = ""
        if let imagePath = ProcessInfo.processInfo.environment["ImagePath"] {
            testImageFolder = imagePath
        } else {
            XCTFail("missing ImagePath in environment")
        }

        app.typeKey("o", modifierFlags: .command)
        app.typeKey("g", modifierFlags: [.shift, .command])
        app.typeText("\(testImageFolder)/TestPictures")
        app.typeKey(.enter, modifierFlags: [])
        app.typeKey(.enter, modifierFlags: [])

        // select an image and assign a lat/log
        let testCell = element(app, matching: "L1000038.DNG")
        XCTAssert(testCell.waitForExistence(timeout: 0.300))
        testCell.rightClick()
        let edit = element(app, matching: "Edit…")
        XCTAssert(edit.exists)
        edit.click()
        let latitude = app.textFields["Latitude"]
        let longitude = app.textFields["Longitude"]
        XCTAssert(latitude.waitForExistence(timeout: 0.300))
        latitude.click()
        app.typeText("37.345")
        longitude.click()
        app.typeText("-121.234")
        app.typeKey(.enter, modifierFlags: [])
        app.typeKey("i", modifierFlags: .command)

        // copy the lat lon
        testCell.rightClick()
        let copy = element(app, matching: "Copy", index: 1)
        XCTAssert(copy.exists)
        copy.click()

        // paste the copied data into a different cell
        let pasteCell = element(app, matching: "L1000050.DNG")
        XCTAssert(pasteCell.exists)
        pasteCell.rightClick()
        let paste = element(app, matching: "Paste", index: 1)
        XCTAssert(paste.exists)
        paste.click()

        app.menuItems["Discard changes"].click()
        app.typeKey("q", modifierFlags: [.command])
    }

    func testCContextMenuView() async throws {
        let testID = TestIDs.ContentView.imageTableViewID
        let app = XCUIApplication()
        app.launchArguments.append("-NOBACKUP")
        app.activate()

        app.outlines[testID].firstMatch.rightClick()
        XCTAssert(element(app, matching: "Edit…").exists)
        XCTAssert(element(app, matching: "Cut", index: 1).exists)
        XCTAssert(element(app, matching: "Copy", index: 1).exists)
        XCTAssert(element(app, matching: "Paste", index: 1).exists)
        XCTAssert(element(app, matching: "Delete", index: 1).exists)
        XCTAssert(element(app, matching: "Show In Finder", index: 1).exists)
        XCTAssert(element(app, matching: "Locn From Track", index: 1).exists)
        XCTAssert(element(app, matching: "Clear Image List", index: 1).exists)

        app.typeKey("q", modifierFlags: [.command])
    }

    func testDPlaceSaver() async throws {
        let app = XCUIApplication()
        app.launchArguments.append("-NOBACKUP")
        app.launchArguments.append("-NOPLACES")
        app.activate()

        // wait a bit for any existing places to be cleared
        try? await Task.sleep(for: .milliseconds(300))

        // look for LA
        app.typeKey("f", modifierFlags: .command)
        app.typeText("Los Angeles")
        // Give the search some time before accepting results
        // this can take quite a while
        try? await Task.sleep(for: .milliseconds(700))
        app.typeKey(.enter, modifierFlags: [])

        // See if the results were saved
        app.typeKey("f", modifierFlags: .command)
        try? await Task.sleep(for: .milliseconds(300))
        let predicate = NSPredicate(format: "value CONTAINS[c] 'Los Angeles'")
        let la = app.staticTexts.containing(predicate).element
        XCTAssert(la.exists)

        app.typeKey("q", modifierFlags: [.command])
    }

    func testEMapContextMenu() async throws {
        let testIDs = TestIDs.MapContextMenu.self
        let app = XCUIApplication()
        app.launchArguments.append("-NOBACKUP")
        app.activate()

        try? await Task.sleep(for: .milliseconds(300))
        let map = app.maps.firstMatch
        XCTAssert(map.exists)
        map.rightClick()
        let style = element(app, matching: testIDs.stylePickerID)
        XCTAssert(style.exists)
        style.click()
        XCTAssert(element(app, matching: "Hybrid").exists)

        XCTAssert(element(app, matching: testIDs.pinOptionID).exists)

        app.typeKey("q", modifierFlags: [.command])
    }
}
