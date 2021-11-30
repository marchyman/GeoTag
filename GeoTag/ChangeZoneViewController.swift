//
//  ChangeZoneViewController.swift
//  GeoTag
//
//  Created by Marco S Hyman on 11/28/21.
//  Copyright © 2021 Marco S Hyman. All rights reserved.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy of
// this software and associated documentation files (the "Software"), to deal in the
// Software without restriction, including without limitation the rights to use,
// copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the
// Software, and to permit persons to whom the Software is furnished to do so,
// subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
// FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
// COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN
// AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
// WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

import Cocoa
import MapKit

class ChangeZoneViewController: NSViewController {
    var callback: ((_ timeZone: TimeZone) -> ())?
    var newTimeZone: TimeZone? = nil

    let validTimeZones: [String] = [
        "-12", "-11", "-10", "-9:30", "-9", "-8", "-7", "-6", "-5", "-4",
        "-3:30", "-3", "-2", "-1", "±0", "+1", "+2", "+3", "+3:30", "+4",
        "+4:30", "+5", "+5:30", "+5:45", "+6", "+6:30", "+7", "+8", "+8:45",
        "+9", "+9:30", "+10", "+10:30", "+11", "+12", "+12:45", "+13", "+14"
    ]
    @IBOutlet weak var thisUtc: NSTextField!
    @IBOutlet weak var thisTimeZone: NSTextField!
    @IBOutlet weak var selectedZone: NSPopUpButton!
    @IBOutlet weak var selectedId: NSTextField!

    override func viewWillAppear() {
        super.viewWillAppear()
        if let wc = view.window?.windowController as? ChangeZoneWindowController {
            callback = wc.callback
            // current time zone
            let seconds = TimeZone.autoupdatingCurrent.secondsFromGMT()
            let zoneTitle = timeZoneTitle(from: seconds)
            thisUtc.stringValue = zoneTitle
            thisTimeZone.stringValue = TimeZone.autoupdatingCurrent.identifier
            selectedZone.removeAllItems()
            selectedZone.addItems(withTitles: validTimeZones)
            selectedZone.selectItem(withTitle: zoneTitle)
            selectedId.stringValue = ""
            return
        }
        unexpected(error: nil, "Cannot find ChangeZone Window Controller")
        fatalError("Cannot find ChangeZone Window Controller")
    }

    /// Time Zone Changed (maybe)
    ///
    /// - Parameter NSButton: unused
    ///
    /// invoke the callback passed when the window was opened with the updated
    /// time zone if a zone has been selected

    @IBAction
    func zoneChanged(_: NSButton) {
        if let zone = newTimeZone {
            callback?(zone)
        }
        self.view.window?.close()
    }

    @IBAction
    func cancel(_ sender: Any) {
        self.view.window?.close()
    }

    @IBAction func zoneSelected(_ sender: NSPopUpButton) {
        let time = sender.titleOfSelectedItem ?? ""
        if let zone = TimeZone(secondsFromGMT: timeZoneSeconds(from: time)) {
            newTimeZone = zone
            selectedId.stringValue = zone.identifier
        }
    }

    // given a time zone as number of seconds from GMT return a string that
    // matches the nearest valid time zone.
    func timeZoneTitle(from seconds: Int) -> String {
        // special case UTC
        if seconds == 0 {
            return "±0"
        }
        // hourly time zones
        let minutes = seconds / 60
        let hours = minutes / 60
        if minutes % 60 == 0 {
            return hours < 0 ? "\(hours)" : "+" + "\(hours)"
        }
        // half hour time zones
        if minutes % 30 == 0 {
            return "\(hours):30"
        }
        // It should be one of the :45 time Zones
        return "\(hours):45"
    }

    // given a time zone title convert it to the number of seconds from GMT.
    // This is the inverse of the above function
    func timeZoneSeconds(from title: String) -> Int {
        var seconds: Int = 0
        if (title == "±0") {
            seconds = 0
        } else if let value = Int(title) {
            seconds = value * 60 * 60
        } else {
            let parts = title.split(separator: ":")
            if parts.count == 2 {
                if let hours = Int(parts[0]),
                   let minutes = Int(parts[1]) {
                    seconds = hours * 60 * 60
                    if hours < 0 {
                        seconds -= minutes * 60
                    } else {
                        seconds += minutes * 60
                    }
                }
            }
        }
        return seconds
    }
}
