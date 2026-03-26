import XCTest

@MainActor
final class UITestGroup1: XCTestCase {

    private let testIDs = TestIDs.ContentView.self

    override func setUp() async throws {
        continueAfterFailure = false
    }

    private func element(_ app: XCUIApplication, matching id: String) -> XCUIElement {
        return app.descendants(matching: .any).matching(identifier: id).element
    }

    func testLaunch() async throws {
        let app = XCUIApplication()
        app.activate()
        XCTAssert(app.windows["GeoTag Version Six"].exists)
        XCTAssert(element(app, matching: testIDs.imageViewID).exists)
        XCTAssert(element(app, matching: testIDs.imageTableViewID).exists)
        XCTAssert(element(app, matching: testIDs.photoPickerViewID).exists)
        XCTAssert(element(app, matching: testIDs.inspectorButtonViewID).exists)
        app.buttons["_XCUI:CloseWindow"].firstMatch.click()
    }

    func testInspectorOpens() async throws {
        let app = XCUIApplication()
        app.activate()
        let inspectorButton = element(app, matching: testIDs.inspectorButtonViewID)
        XCTAssert(inspectorButton.exists)
        let inspectorView = element(app, matching: testIDs.imageInspectorViewID)
        XCTAssert(!inspectorView.exists)
        inspectorButton.click()
        XCTAssert(inspectorView.waitForExistence(timeout: 0.300))
        inspectorButton.click()
        XCTAssert(inspectorView.waitForNonExistence(timeout: 0.300))
    }
}
