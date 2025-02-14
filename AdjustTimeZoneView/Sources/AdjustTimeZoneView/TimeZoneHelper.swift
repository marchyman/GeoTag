//
// Copyright 2023 Marco S Hyman
// See LICENSE file for info
// https://www.snafu.org/
//

import Foundation

// handle data conversion tasks between TimeZones and information needed
// by the user interface to show the current TimeZone and select a
// different TimeZone.

// Give the TimeZones this app supports a case and a name

enum TimeZoneName: String, Identifiable, CaseIterable {
    case minus12 = "-12", minus11 = "-11", minus10 = "-10",
        minus930 = "-9:30", minus9 = "-9", minus8 = "-8", minus7 = "-7",
        minus6 = "-6", minus5 = "-5", minus4 = "-4", minus330 = "-3:30",
        minus3 = "-3", minus2 = "-2", minus1 = "-1", zero = "±0",
        plus1 = "+1", plus2 = "+2", plus3 = "+3", plus330 = "+3:30",
        plus4 = "+4", plus430 = "+4:30", plus5 = "+5", plus530 = "+5:30",
        plus545 = "+5:45", plus6 = "+6", plus630 = "+6:30", plus7 = "+7",
        plus8 = "+8", plus845 = "+8:45", plus9 = "+9", plus930 = "+9:30",
        plus10 = "+10", plus130 = "+10:30", plus11 = "+11", plus12 = "+12",
        plus1245 = "+12:45", plus13 = "+13", plus14 = "+14"

    var id: Self { self }

    // the "rawValue" returns the name associated with self.

    // return the TimeZone of self

    var timeZone: TimeZone {
        let rawValue = self.rawValue
        var seconds: Int = 0

        // convert the rawValue into a number of seconds.

        if rawValue == "±0" {
            seconds = 0
        } else if let value = Int(rawValue) {
            // value is in hours
            seconds = value * 60 * 60
        } else {
            let parts = rawValue.split(separator: ":")
            if parts.count == 2 {
                if let hours = Int(parts[0]),
                    let minutes = Int(parts[1])
                {
                    seconds = hours * 60 * 60
                    if hours < 0 {
                        seconds -= minutes * 60
                    } else {
                        seconds += minutes * 60
                    }
                }
            }
        }

        // Use the number of seconds to get the TimeZone
        if let zone = TimeZone(secondsFromGMT: seconds) {
            return zone
        }
        fatalError("Bad time zone calculation")
    }

    // Static functions that work with any time zone.

    // Returns the case given a name.  If a bad name is given return .zero

    static func timeZoneCase(name: String) -> Self {
        if let timeZoneCase = TimeZoneName(rawValue: name) {
            return timeZoneCase
        }
        return .zero
    }

    // Return the name associated with a TimeZone. If the given zone
    // is nil use TimeZone.autoupdatingCurrent [unused]

    // static func timeZoneName(zone: TimeZone?) -> String {
    //     return timeZoneCase(zone: zone).rawValue
    // }

    // return the identifier for a given TimeZone.  If no zone is
    // specified return the identifier for TimeZone.autoupdatingCurrent
    // [unused]

    // static func timeZoneIdentifier(zone: TimeZone?) -> String {
    //     if let zone {
    //         return zone.identifier
    //     }
    //     return TimeZone.autoupdatingCurrent.identifier
    // }

    // return the timeZoneCase given a TimeZone. If the given zone
    // is nil use TimeZone.autoupdatingCurrent

    static func timeZoneCase(zone: TimeZone?) -> Self {
        let seconds: Int
        if let zone {
            seconds = zone.secondsFromGMT()
        } else {
            seconds = TimeZone.autoupdatingCurrent.secondsFromGMT()
        }
        return timeZoneCase(name: timeZoneTitle(from: seconds))
    }

    // return the string name of a timeZone given its +/- offset from
    // UTC/GMT in seconds.

    static func timeZoneTitle(from seconds: Int) -> String {
        // special case UTC/GMT
        if seconds == 0 {
            return "±0"
        }
        // hourly time zones
        let minutes = seconds / 60
        if minutes % 60 == 0 {
            return timeZoneTitleHours(from: minutes)
        }
        // half hour time zones
        if minutes % 30 == 0 {
            return "\(timeZoneTitleHours(from: minutes)):30"
        }
        if minutes % 60 == 45 {
            return "\(timeZoneTitleHours(from: minutes)):45"
        }
        // Unknown time zone, treat it as GMT
        return "±0"
    }

    // Convert minutes to hours with a + or - prefix.  Returns whole number
    // of hours, ignoring any remainder minutes.

    static func timeZoneTitleHours(from minutes: Int) -> String {
        let hours = minutes / 60
        return hours < 0 ? "\(hours)" : "+" + "\(hours)"
    }
}
