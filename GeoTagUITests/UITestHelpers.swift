import XCTest

@MainActor
struct TestHelper {
    static
    func element(_ app: XCUIApplication,
                 matching id: String,
                 index: Int = 0) -> XCUIElement {
        return app.descendants(matching: .any)
                  .matching(identifier: id)
                  .element(boundBy: index)
    }
}
