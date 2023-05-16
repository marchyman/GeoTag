//
//  ClickMapView.swift
//
//  Created by Marco S Hyman on 11/25/21.
//

import Foundation
import MapKit

// Subclass MKMapView to hook into mouse up events to extract the
// location of single click events.  I couldn't do this in an extension
// without breaking three finger drags on a touch pad (and probably the same
// function on a mouse).

class ClickMapView: MKMapView {
    var viewModel: AppViewModel!
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

    // Mark the saved location when the click timer expires

    @objc
    func clicked(timer: Timer) {
        // swiftlint:disable force_cast
        let coords = timer.userInfo as! CLLocationCoordinate2D
        // swiftlint:enable force_cast
        clickTimer?.invalidate()
        clickTimer = nil
        if !viewModel.selection.isEmpty {
            viewModel.undoManager.beginUndoGrouping()
            for id in viewModel.selection {
                viewModel.update(id: id, location: coords)
            }
            viewModel.undoManager.endUndoGrouping()
            viewModel.undoManager.setActionName("set location")
        }
    }
}
