import XCTest

@MainActor
final class UITestGroup1: XCTestCase {

    override func setUp() async throws {
        continueAfterFailure = false
    }

    func testLaunch() async throws {
        let app = XCUIApplication()
        app.activate()
        XCTAssert(app.windows["GeoTag Version Six"].exists)
        XCTAssert(app.buttons["Photo Library"].exists)
        XCTAssert(app.buttons["Toggle Inspector"].exists)
        app.buttons["_XCUI:CloseWindow"].firstMatch.click()
    }
}
