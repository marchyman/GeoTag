//
// Copyright 2024 Marco S Hyman
// See LICENSE file for info
// https://www.snafu.org/
//

import XCTest

final class GeoTagUI01LaunchTests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    // launch with a value in the environment that will cause a backup
    // folder to be created.

    @MainActor
    func testBackupFolder() throws {
        let app = XCUIApplication()
        app.launchEnvironment = ["BACKUP": NSTemporaryDirectory()]
        app.launch()
        app.terminate()
    }

    @MainActor
    func testLaunchPerformance() throws {
        if #available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 7.0, *) {
            // This measures how long it takes to launch your application.
            measure(metrics: [XCTApplicationLaunchMetric()]) {
                XCUIApplication().launch()
            }
        }
    }
}
