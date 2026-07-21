import XCTest

@MainActor
final class UITestGroup3: XCTestCase {

    override func setUp() async throws {
        continueAfterFailure = false
    }

    func testAPhotoLibrary() async throws {
        let photoPickerID = TestIDs.ContentView.photoPickerViewID
        let nameID = TestIDs.TableColumns.nameID
        let dismissID = TestIDs.DismissModifier.dismissButtonID
        let app = XCUIApplication()

        app.launchArguments.append("-NOBACKUP")
        app.resetAuthorizationStatus(for: .photos)
        app.activate()

        let photoPickerButton = TestHelper.element(app, matching: photoPickerID)
        XCTAssert(photoPickerButton.exists)

        // this will trigger a system alert
        photoPickerButton.click()

        // Get at the system alert via the notification center
        // Found this using test recording after setting things
        // up so that the notification would occur.
        let userNotificationCentApp =
            XCUIApplication(bundleIdentifier: "com.apple.UserNotificationCenter")
        userNotificationCentApp.activate()
        userNotificationCentApp.buttons["Allow access to all Photos"]
                               .firstMatch.click()

        // now activate the app and acknowledge access allowed
        app.activate()
        try await Task.sleep(for: .milliseconds(100))
        let sheet = app.sheets.firstMatch
        XCTAssert(sheet.staticTexts["Photo Library Access Allowed"].exists)
        sheet.buttons["OK"].click()

        // Open the library
        photoPickerButton.click()
        // wait past the "loading photos" stage and give extra time
        // for all needed UI elements to load
        // try await Task.sleep(for: .seconds(2))
        let images = app.descendants(matching: .image)
                        .matching(identifier: "PXGGridLayout-Info")
        XCTAssert(images.firstMatch.waitForExistence(timeout: 2000))

        // select the first 5 images
        for ix in 0..<5 {
            let image = images.element(boundBy: ix)
            if image.exists {
                image.click()
            }
        }
        // why do I have to click this twice? Output says the second
        // click does "Falling back to element center point".
        app.buttons["Add"].firstMatch.click()
        app.buttons["Add"].firstMatch.click()
        try await Task.sleep(for: .milliseconds(400))

        // Check that the images loaded
        let names = app.descendants(matching: .staticText)
                       .matching(identifier: nameID)
        for ix in 0..<5 {
            let name = names.element(boundBy: ix)
            XCTAssert(name.exists)
        }

        // open the library a 2nd time and select the first image again
        photoPickerButton.click()
        try await Task.sleep(for: .seconds(2))
        let dupImage = app.descendants(matching: .image)
            .matching(identifier: "PXGGridLayout-Info")
            .firstMatch

        XCTAssert(dupImage.exists)
        // for unknown reasons dumImage is not hittable. Instead of using
        // dupImage.click tap on the center of its grid.
        let center = dupImage.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        center.tap()

        // close the image picker
        app.buttons["Add"].firstMatch.click()

        // Check for a dup image sheet here
        let dupSheet = app.sheets.firstMatch
        XCTAssert(dupSheet.waitForExistence(timeout: 0.400))

        // click the sheet dismiss button
        let dismissButton = TestHelper.element(app, matching: dismissID)
        XCTAssert(dismissButton.waitForExistence(timeout: 0.300))
        dismissButton.click()

        // quit the app
        app.typeKey("q", modifierFlags: [.command])
    }
}
