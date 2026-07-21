import XCTest

@MainActor
final class UITestGroup4: XCTestCase {
    let mapPinName = "MapPinPlaced.png"
    let mapNoPinName = "MapNoPin.png"
    let noImagesName = "Second-launch.png"  // reuse existing image

    func testAPins() throws {
        guard let imagePath = ProcessInfo.processInfo.environment["ImagePath"] else {
            XCTFail("missing ImagePath in environment")
            return
        }
        let app = XCUIApplication()
        app.launchArguments.append("-NOBACKUP")

        // load images
        app.activate()
        app.typeKey("o", modifierFlags: [.command])
        app.typeKey("g", modifierFlags: [.shift, .command])
        app.typeText("\(imagePath)/TestPictures")
        app.typeKey(.enter, modifierFlags: [])
        app.typeKey(.enter, modifierFlags: [])

        // find a cell to select
        let testCell = TestHelper.element(app, matching: "L1000038.DNG")
        XCTAssert(testCell.waitForExistence(timeout: 0.300))
        testCell.click()

        // click on the map
        let map = app.maps["ContentView.view.mapSearchView"]
        map.click()
        XCTAssert(TestHelper.element(app, matching: "main pin").exists)

        // Use a snapshot to verify the view
        let window = app.windows["GeoTag Version Six"]
        XCTAssert(window.exists)
        var screenshot = window.screenshot().pngRepresentation
        try Snapshots.saveImage(screenshot, as: mapPinName)
        try Snapshots.diffImage(name: mapPinName)

        // undo the change and verify the view
        app.typeKey("z", modifierFlags: [.command])
        screenshot = window.screenshot().pngRepresentation
        try Snapshots.saveImage(screenshot, as: mapNoPinName)
        try Snapshots.diffImage(name: mapNoPinName)

        // redo and check again
        app.typeKey("z", modifierFlags: [.shift, .command])
        screenshot = window.screenshot().pngRepresentation
        try Snapshots.saveImage(screenshot, as: mapPinName)
        try Snapshots.diffImage(name: mapPinName)

        // discard changes
        app.menuItems["Discard changes"].click()
        screenshot = window.screenshot().pngRepresentation
        try Snapshots.saveImage(screenshot, as: mapNoPinName)
        try Snapshots.diffImage(name: mapNoPinName)

        // clear image list
        app.menuItems["Clear Image List"].click()
        screenshot = window.screenshot().pngRepresentation
        try Snapshots.saveImage(screenshot, as: noImagesName)
        try Snapshots.diffImage(name: noImagesName)

        app.typeKey("q", modifierFlags: [.command])
    }
}
