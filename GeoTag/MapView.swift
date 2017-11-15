//
//  MapView.swift
//  GeoTag
//
//  Created by Marco S Hyman on 7/19/14.
//
// Copyright 2014-2017 Marco S Hyman
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

import Foundation
import MapKit

/// Subclass MKMapView to hook into mouse up events to extract the
/// location of single click events.  I couldn't do this in an extension
/// without breaking three finger drags on a touch pad (and probably the same
/// function on a mouse).

class MapView: MKMapView {
    var clickDelegate: MapViewDelegate?

    override func mouseUp(with theEvent: NSEvent) {
        super.mouseUp(with: theEvent)
        if theEvent.clickCount == 1 {
            let point = convert(theEvent.locationInWindow, from: nil)
            let location = convert(point, toCoordinateFrom: self)
            clickDelegate?.mouseClicked(mapView: self, location: location)
        }
    }
}

/// The delegate receiving the mouse clicks must follow this protocol
protocol MapViewDelegate: NSObjectProtocol {
    func mouseClicked(mapView: MapView!, location: CLLocationCoordinate2D)
}
