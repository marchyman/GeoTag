import XCTest

@MainActor
final class UITestGroup2: XCTestCase {

    override func setUp() async throws {
        continueAfterFailure = false
    }

    private func element(_ app: XCUIApplication, matching id: String) -> XCUIElement {
        return app.descendants(matching: .any).matching(identifier: id).element
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

        app.buttons["_XCUI:CloseWindow"].firstMatch.click()
    }
}
