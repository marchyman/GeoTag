//
//  Updates.swift
//  GeoTag
//
//  Created by Marco S Hyman on 1/1/23.
//

import SwiftUI
import MapKit

// functions that handle location changes for both the map and images

extension AppState {

    // create a map pin annotation if needed and assign to it the given location
    func updatePin(location: Coords?) {
        if pin == nil {
            pin = MKPointAnnotation()
        }
        if let location {
            let point = MKMapPoint(location);
            if !MapView.view.visibleMapRect.contains(point) {
                MapView.view.setCenter(location, animated: false)
            }
            pin!.coordinate = location
            pinEnabled = true
        } else {
            pinEnabled = false
        }
    }

    // Update an image with a location. Image is identified by its ID.
    // Elevation is optional and is only provided when matching track logs
    // Handle UNDO!
    func update(id: ImageModel.ID, location: Coords?, elevation: Double? = nil) {
        self[id].location = location
        self[id].elevation = elevation
        window?.isDocumentEdited = true
    }
}
