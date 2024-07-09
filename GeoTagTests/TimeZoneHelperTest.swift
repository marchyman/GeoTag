//
// Copyright 2024 Marco S Hyman
// See LICENSE file for info
// https://www.snafu.org/
//

import Foundation
import Testing
@testable import GeoTag

struct TimeZoneHelperTest {

    @Test func timeZoneCalc() async throws {
        var timeZoneName: TimeZoneName = .zero

        #expect(timeZoneName.timeZone == TimeZone(secondsFromGMT: 0))
        timeZoneName = .plus845
        #expect(timeZoneName.timeZone.identifier == "GMT+0845")
        timeZoneName = .minus930
        #expect(timeZoneName.timeZone.identifier == "GMT-0930")
    }

    // this also tests timeZoneTitleHours(from minutes:)
    @Test func timeZoneTitleFromSeconds() async throws {
        #expect(TimeZoneName.timeZoneTitle(from: 0) == "±0")
        #expect(TimeZoneName.timeZoneTitle(from: 60 * 60) == "+1")
        #expect(TimeZoneName.timeZoneTitle(from: -60 * 60) == "-1")
        #expect(TimeZoneName.timeZoneTitle(from: -9 * 60 * 60 - 30 * 60) == "-9:30")
        #expect(TimeZoneName.timeZoneTitle(from: 8 * 60 * 60 + 45 * 60) == "+8:45")
    }

    @Test func timeZoneCaseTests() async throws {
        let seconds = TimeZone.autoupdatingCurrent.secondsFromGMT()
        let title = TimeZoneName.timeZoneTitle(from: seconds)
        let zone = TimeZoneName.timeZoneCase(name: title)
        #expect(TimeZoneName.timeZoneCase(zone: nil) == zone)

        let gmt = TimeZone(secondsFromGMT: 0)
        #expect(TimeZoneName.timeZoneCase(zone: gmt) == .zero)
    }
}
