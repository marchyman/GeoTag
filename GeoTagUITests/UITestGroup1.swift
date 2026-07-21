import XCTest

@MainActor
final class UITestGroup1: XCTestCase {
    private let testIDs = TestIDs.ContentView.self
    let initialLaunchName = "Initial-launch.png"
    let secondLaunchName = "Second-launch.png"
    let inspectorName = "Inspector.png"
    let timezoneName = "Timezone.png"
    let settingsName = "Settings.png"

    override func setUp() async throws {
        continueAfterFailure = false
    }

    func testALaunch() throws {
        let dismissID = TestIDs.DismissModifier.dismissButtonID
        let app = XCUIApplication()
        app.launchArguments.append("-UIINIT")
        app.activate()
        XCTAssert(TestHelper.element(app, matching: testIDs.mapSearchViewID).waitForExistence(timeout: 1.300))
        let window = app.windows["GeoTag Version Six"]
        XCTAssert(window.exists)
        let screenshot = window.screenshot().pngRepresentation
        try Snapshots.saveImage(screenshot, as: initialLaunchName)
        try Snapshots.diffImage(name: initialLaunchName)
        let dismissButton = TestHelper.element(app, matching: dismissID)
        XCTAssert(dismissButton.waitForExistence(timeout: 0.300))
        dismissButton.click()
        XCTAssert(dismissButton.waitForNonExistence(timeout: 0.300))
        XCTAssert(TestHelper.element(app, matching: testIDs.imageViewID).exists)
        XCTAssert(TestHelper.element(app, matching: testIDs.imageTableViewID).exists)
        XCTAssert(TestHelper.element(app, matching: testIDs.photoPickerViewID).exists)
        XCTAssert(TestHelper.element(app, matching: testIDs.inspectorButtonViewID).exists)
        app.typeKey("q", modifierFlags: [.command])
    }

    func testBInspectorOpens() throws {
        let app = XCUIApplication()
        app.launchArguments.append("-NOBACKUP")
        app.activate()
        XCTAssert(TestHelper.element(app, matching: testIDs.mapSearchViewID).waitForExistence(timeout: 0.300))
        let window = app.windows["GeoTag Version Six"]
        XCTAssert(window.exists)
        var screenshot = window.screenshot().pngRepresentation
        try Snapshots.saveImage(screenshot, as: secondLaunchName)
        try Snapshots.diffImage(name: secondLaunchName)
        let inspectorButton = TestHelper.element(app, matching: testIDs.inspectorButtonViewID)
        XCTAssert(inspectorButton.exists)
        let inspectorView = TestHelper.element(app, matching: testIDs.imageInspectorViewID)
        XCTAssert(!inspectorView.exists)
        inspectorButton.click()
        XCTAssert(inspectorView.waitForExistence(timeout: 0.300))
        // update screenshot with inspector open
        screenshot = window.screenshot().pngRepresentation
        try Snapshots.saveImage(screenshot, as: inspectorName)
        try Snapshots.diffImage(name: inspectorName)
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
        let timezoneButton = TestHelper.element(app, matching: timezoneID)
        XCTAssert(timezoneButton.exists)
        timezoneButton.click()
        let window = app.windows["Change Time Zone"]
        XCTAssert(window.exists)
        let screenshot = window.screenshot().pngRepresentation
        try Snapshots.saveImage(screenshot, as: timezoneName)
        try Snapshots.diffImage(name: timezoneName)
        XCTAssert(TestHelper.element(app, matching: cameraTimezoneID).exists)
        app.buttons["_XCUI:CloseWindow"].firstMatch.click()
        app.typeKey("q", modifierFlags: [.command])
    }

    func testEShowRunLogWindow() throws {
        let runlogID = "Show log…"
        let testIDs = TestIDs.RunLogView.self
        let app = XCUIApplication()
        app.launchArguments.append("-NOBACKUP")
        app.activate()
        let runlogButton = TestHelper.element(app, matching: runlogID)
        XCTAssert(runlogButton.exists)
        runlogButton.click()
        XCTAssert(TestHelper.element(app, matching: testIDs.refreshID).waitForExistence(timeout: 0.300))
        XCTAssert(TestHelper.element(app, matching: testIDs.copyID).exists)
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
        let settingsButton = TestHelper.element(app, matching: settingsID)
        XCTAssert(settingsButton.exists)
        settingsButton.click()
        let closeButton = TestHelper.element(app, matching: closeButtonID)
        XCTAssert(closeButton.waitForExistence(timeout: 0.300))
        let window = app.windows["GeoTag Settings"]
        let screenshot = window.screenshot().pngRepresentation
        try Snapshots.saveImage(screenshot, as: settingsName)
        try Snapshots.diffImage(name: settingsName)
        closeButton.click()
        app.typeKey("q", modifierFlags: [.command])
    }
}
