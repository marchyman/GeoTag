import XCTest

@MainActor
final class UITestGroup1: XCTestCase {
    private let testIDs = TestIDs.ContentView.self
    let initialLaunchName = "Initial-launch.png"

    override func setUp() async throws {
        continueAfterFailure = false
    }

    private func element(_ app: XCUIApplication, matching id: String) -> XCUIElement {
        return app.descendants(matching: .any).matching(identifier: id).element
    }
    // removing 'async' from the test function definitions allowd the tests
    // to work in that the main window now opens.

    func testALaunch() throws {
        let dismissID = TestIDs.DismissModifier.dismissButtonID
        let app = XCUIApplication()
        app.launchArguments.append("-UIINIT")
        app.activate()
        let window = app.windows["GeoTag Version Six"]
        XCTAssert(window.exists)
        let screenshot = window.screenshot().pngRepresentation
        try Snapshots.saveImage(screenshot, as: initialLaunchName)
        let dismissButton = element(app, matching: dismissID)
        XCTAssert(dismissButton.waitForExistence(timeout: 0.300))
        dismissButton.click()
        XCTAssert(dismissButton.waitForNonExistence(timeout: 0.300))
        XCTAssert(element(app, matching: testIDs.imageViewID).exists)
        XCTAssert(element(app, matching: testIDs.imageTableViewID).exists)
        XCTAssert(element(app, matching: testIDs.photoPickerViewID).exists)
        XCTAssert(element(app, matching: testIDs.inspectorButtonViewID).exists)
        app.typeKey("q", modifierFlags: [.command])
    }

    // find the screenshot captured above and compare it with a known
    // good version.
    func testAVerify() throws {
        // path to known good image
        guard let snapshotPath =
            ProcessInfo.processInfo.environment["Snapshots"] else {
                XCTFail("Snapshots path not in environment")
                return
            }
        let savedLaunchImage = snapshotPath + "/" + initialLaunchName
        guard FileManager.default.isReadableFile(atPath: savedLaunchImage) else {
            XCTFail("\(savedLaunchImage) not readable")
            return
        }

        // path to most recent test snapshot
        let saveURL = Snapshots.saveImageURL(from: initialLaunchName)
        guard FileManager.default.isReadableFile(atPath: saveURL.path()) else {
            XCTFail("\(saveURL.path()) not readable")
            return
        }

        // run odiff to test if image changed
        try Snapshots.diffImage(good: savedLaunchImage, test: saveURL.path)
    }

    func testBInspectorOpens() throws {
        let app = XCUIApplication()
        app.launchArguments.append("-NOBACKUP")
        app.activate()
        let inspectorButton = element(app, matching: testIDs.inspectorButtonViewID)
        XCTAssert(inspectorButton.exists)
        let inspectorView = element(app, matching: testIDs.imageInspectorViewID)
        XCTAssert(!inspectorView.exists)
        inspectorButton.click()
        XCTAssert(inspectorView.waitForExistence(timeout: 0.300))
        inspectorButton.click()
        XCTAssert(inspectorView.waitForNonExistence(timeout: 0.300))
        app.typeKey("q", modifierFlags: [.command])
    }

    // func testCLibraryOpens() throws { ... }
    // library opens and item selection in UITestGroup3

    func testDAdjustTimezoneWindow() throws {
        let timezoneID = "Specify Time Zone…"
        let cameraTimezoneID = TestIDs.AdjustTimeZoneView.cameraTimeZoneID
        let app = XCUIApplication()
        app.launchArguments.append("-NOBACKUP")
        app.activate()
        let timezoneButton = element(app, matching: timezoneID)
        XCTAssert(timezoneButton.exists)
        timezoneButton.click()
        XCTAssert(element(app, matching: cameraTimezoneID).exists)
        app.buttons["_XCUI:CloseWindow"].firstMatch.click()
        app.typeKey("q", modifierFlags: [.command])
    }

    func testEShowRunLogWindow() throws {
        let runlogID = "Show log…"
        let testIDs = TestIDs.RunLogView.self
        let app = XCUIApplication()
        app.launchArguments.append("-NOBACKUP")
        app.activate()
        let runlogButton = element(app, matching: runlogID)
        XCTAssert(runlogButton.exists)
        runlogButton.click()
        XCTAssert(element(app, matching: testIDs.refreshID).waitForExistence(timeout: 0.300))
        XCTAssert(element(app, matching: testIDs.copyID).exists)
        sleep(1)
        app.buttons["_XCUI:CloseWindow"].firstMatch.click()
        app.typeKey("q", modifierFlags: [.command])
    }

    func testFSettingsWindow() throws {
        let settingsID = "Settings…"
        let closeButtonID = TestIDs.SettingsView.closeID
        let app = XCUIApplication()
        app.launchArguments.append("-NOBACKUP")
        app.activate()
        let settingsButton = element(app, matching: settingsID)
        XCTAssert(settingsButton.exists)
        settingsButton.click()
        sleep(1)
        let screenshot = app.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "Settings"
        attachment.lifetime = .keepAlways
        add(attachment)
        let closeButton = element(app, matching: closeButtonID)
        XCTAssert(closeButton.exists)
        closeButton.click()
        app.typeKey("q", modifierFlags: [.command])
    }
}
