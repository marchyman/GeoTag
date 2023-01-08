//
//  ClickMapView.swift
//
//  Created by Marco S Hyman on 11/25/21.
//  Copyright ©2021 Marco S Hyman
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to
// deal in the Software without restriction, including without limitation the
// rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
// sell copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
// THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
// FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
// DEALINGS IN THE SOFTWARE.
//

import Foundation
import MapKit

/// Subclass MKMapView to hook into mouse up events to extract the
/// location of single click events.  I couldn't do this in an extension
/// without breaking three finger drags on a touch pad (and probably the same
/// function on a mouse).
/// 
class ClickMapView: MKMapView {
    var viewModel: ViewModel!
    var clickTimer: Timer?
    var dragInProgress = false

    // start a timer to mark the location on the first click.  Cancel the
    // timer on double clicks.
    override
    func mouseUp(with theEvent: NSEvent) {
        super.mouseUp(with: theEvent)
        if viewModel.mostSelected != nil &&
            theEvent.clickCount == 1 && !dragInProgress {
            // start a timer for this location.  The location will be marked
            // when the timer fires unless this is a double click
            let point = convert(theEvent.locationInWindow, from: nil)
            let coords = convert(point, toCoordinateFrom: self)
            clickTimer = Timer.scheduledTimer(timeInterval: NSEvent.doubleClickInterval,
                                              target: self,
                                              selector: #selector(self.clicked),
                                              userInfo: coords, repeats: false)
        } else {
            dragInProgress = false
            clickTimer?.invalidate()
            clickTimer = nil
        }
    }

    override
    func mouseDragged(with theEvent: NSEvent) {
        dragInProgress = true
    }

    /// Mark the saved location when the click timer expires
    @objc
    func clicked(timer: Timer) {
        let coords = timer.userInfo as! CLLocationCoordinate2D
        clickTimer?.invalidate()
        clickTimer = nil
        if let id = viewModel.mostSelected {
            viewModel.update(id: id, location: coords)
            viewModel.undoManager.setActionName("set location")
        }
    }
}
