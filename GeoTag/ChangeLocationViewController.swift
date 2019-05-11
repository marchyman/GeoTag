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
    
//    @IBOutlet weak var originalLocation: NSDatePicker!
//    @IBOutlet weak var newLocation: Coord!
    
    override func viewWillAppear() {
        super.viewWillAppear()
        if let wc = view.window?.windowController as? ChangeLocationWindowController {
            image = wc.image
            callback = wc.callback
//            if let dateValue = image.dateValue {
//                originalDate.dateValue = dateValue
//                newDate.dateValue = dateValue
//            } else {
//                // no current dateTime
//                originalDate.dateValue = Date(timeIntervalSince1970: 0)
//                newDate.dateValue = Date()
//            }
            return
        }
        unexpected(error: nil, "Cannot find ChangeTime Window Controller")
        fatalError("Cannot find ChangeTime Window Controller")
    }
    
    /// Location change for a single image
    ///
    /// - Parameter NSButton: unused
    ///
    /// invoke the callback passed when the window was opened with the updated
    /// dateValue.

    
    @IBAction
    func locationChanged(_: NSButton) {
//        if newDate.dateValue != originalDate.dateValue {
//            callback?(newDate.dateValue)
//        }
        self.view.window?.close()
    }
    
    @IBAction
    func cancel(_ sender: Any) {
        self.view.window?.close()
    }
    
}
