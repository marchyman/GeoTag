//
//  ChangeLocationViewController.swift
//  GeoTag
//
//  Created by Marco S Hyman on 5/10/19.
//  Copyright © 2019 Marco S Hyman. All rights reserved.
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

class ChangeLocationViewController: NSViewController {
    var image: ImageData!
    var callback: ((_ location: Coord) -> ())?
    
    @IBOutlet weak var newLatitude: NSTextField!
    @IBOutlet weak var newLongitude: NSTextField!
    
    override func viewWillAppear() {
        super.viewWillAppear()
        if let wc = view.window?.windowController as? ChangeLocationWindowController {
            image = wc.image
            callback = wc.callback
            if let coord = image.location {
                switch Preferences.coordFormat() {
                case .deg:
                    newLatitude.stringValue = String(format: "% 2.6f", coord.latitude)
                    newLongitude.stringValue = String(format: "% 2.6f", coord.longitude)
                case .degMin:
                    newLatitude.stringValue = coord.dm.latitude
                    newLongitude.stringValue = coord.dm.longitude
                case .degMinSec:
                    newLatitude.stringValue = coord.dms.latitude
                    newLongitude.stringValue = coord.dms.longitude
                }
            }
            return
        }
        unexpected(error: nil, "Cannot find ChangeTime Window Controller")
        fatalError("Cannot find ChangeTime Window Controller")
    }
    

    /// Convert a text string assumed to contain a coordinate to a double
    /// value representing the coordinate.
    ///
    /// - Parameter input: the string containing the coordinate
    /// - Parameter range: the allowable range for the number of degrees
    /// - Parameter reference: the allowable reference values
    /// - Returns: the coordinate converted to a double
    ///
    /// Possible inputs
    /// -dd.dddd R          Coordinate in degrees
    /// -dd mm.mmmm R       Coordinate in degrees and minutes
    /// -dd mm ss.ssss R    Coordinate in degrees, minutes, and seconds
    ///
    /// S latitudes and W longitudes can be indicated by a negative number
    /// of degrees or the appropriate reference.  It is an error if both
    /// are used.  Degree (°), Minute ('), and Second (") marks are optional
    /// and ignored if found at the end of a value.

    private
    func validateLocation(input: String,
                          range: ClosedRange<UInt>,
                          reference: [String]) -> Double? {
        var coordinate: Double? = nil
        var invert = false
        let maxParts = 3            // maximum numeric parts to a coordinate
        let delims = [ "°", "'", "\""]
        var subStrings = input.split(separator: " ")

        // See if the last part of the input string matches one of the
        // given reference values.
        if let ref = subStrings.last?.uppercased() {
            for c in reference {
                if c.uppercased() == ref {
                    if  ref == "S" || ref == "W" {
                        invert = true
                    }
                    subStrings.removeLast()
                    break
                }
            }
        }

        // There sould be from 1...maxParts substrings to process

        guard !subStrings.isEmpty &&
              subStrings.count <= maxParts else { return nil }

        var dms = [0.0, 0.0, 0.0]   // degrees, minutes, seconds
        var index = 0
        for str in subStrings {
            var digits: Substring
            if str.hasSuffix(delims[index]) {
                digits = str.dropLast()
            } else {
                digits = str
            }
            if let val = Double(digits) {
                // verify the number of degrees/min/sec is in the allowed range
                if index == 0 {
                    if !range.contains(Int(val).magnitude) {
                        return nil
                    }
                } else if !(0...60).contains(Int(val)) {
                    return nil
                }
                dms[index] = val
            } else {
                return nil
            }
            index += 1
        }
        coordinate = dms[0] + (dms[1]/60) + (dms[2]/60/60)
        if invert {
            coordinate = -coordinate!
        }
        return coordinate
    }

    /// Location change for a single image
    ///
    /// - Parameter NSButton: unused
    ///
    /// invoke the callback passed when the window was opened with the updated
    /// dateValue.
    
    @IBAction
    func locationChanged(_: NSButton) {
        if let lat = validateLocation(input: newLatitude.stringValue,
                                      range: 0...90, reference: ["N", "S"]),
            let lon = validateLocation(input: newLongitude.stringValue,
                                       range: 0...180, reference: ["E", "W"]) {
            if let coord = image.location,
                coord.latitude == lat, coord.longitude == lon {
                // nothing changed
            } else {
                callback?(Coord(latitude: lat, longitude: lon))
            }
            view.window?.close()
        }

        // location syntax is incorrect
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.addButton(withTitle: NSLocalizedString("CLOSE", comment: "Close"))
        alert.messageText = NSLocalizedString("CFE_TITLE",
                                              comment: "Coordinate Format Error")
        alert.informativeText = NSLocalizedString("CFE_TEXT",
                                                  comment: "Coordinate Format Error")
        alert.beginSheetModal(for: view.window!)
    }
    
    @IBAction
    func cancel(_ sender: Any) {
        self.view.window?.close()
    }
    
}
