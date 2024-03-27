//
//  GeoTagUITestsLaunchTests.swift
//  GeoTagUITests
//
//  Created by Marco S Hyman on 3/27/24.
//

import XCTest

final class GeoTagUITestsLaunchTests: XCTestCase {

    private var app: XCUIApplication!

//    override class var runsForEachTargetApplicationUIConfiguration: Bool {
//        true
//    }

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
//        app.launchArguments = ["-some0-arg"]
//        app.launchEnvironment = ["-some-other-arg" : "value"]

        app.launch()
    }

    func takeScreenshot(name: String) {
//        let screenshot = app.screenshot()
        let screenshot = app.windows.firstMatch.screenshot()

        let attachment =
            XCTAttachment(uniformTypeIdentifier: "public.png",
                          name: "\(name).png",
                          payload: screenshot.pngRepresentation,
                          userInfo: nil)
        attachment.lifetime = .keepAlways
        add(attachment)
      }

    func testLaunch() throws {

        // Insert steps here to perform after app launch but before taking a screenshot,
        // such as logging into a test account or navigating somewhere in the app

        _ = app.waitForExistence(timeout: 5)
        takeScreenshot(name: "Launch")
    }
}
