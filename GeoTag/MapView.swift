//
//  MapView.swift
//  GeoTag
//
//  Created by Marco S Hyman on 7/19/14.
//  Copyright (c) 2014, 2016 Marco S Hyman, CC-BY-NC
//

import Foundation
import MapKit

/// Subclass MKMapView to hook into mouse up events to extract the
/// location of single click events.  I couldn't do this in an extension
/// without breaking three finger drags on a touch pad (and probably the same
/// function on a mouse).

class MapView: MKMapView {
    var clickDelegate: MapViewDelegate?

    override func mouseUp(theEvent: NSEvent) {
        super.mouseUp(theEvent)
        if theEvent.clickCount == 1 {
            let point = convertPoint(theEvent.locationInWindow, fromView: nil)
            let location = convertPoint(point, toCoordinateFromView: self)
            clickDelegate?.mapViewMouseClicked(self, location: location)
        }
    }
}

/// The delegate receiving the mouse clicks must follow this protocol
protocol MapViewDelegate: NSObjectProtocol {
    func mapViewMouseClicked(mapView: MapView!, location: CLLocationCoordinate2D)
}
