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

    // Update an image with a location.
    // Elevation is optional and is only provided when matching track logs

    func update(_ image: ImageModel, location: Coords?,
                elevation: Double? = nil, documentEdited: Bool = true) {
        let currentLocation = image.location
        let currentElevation = image.elevation
        let currentDocumentEdited = isDocumentEdited
        undoManager.registerUndo(withTarget: self) { target in
            target.update(image, location: currentLocation,
                          elevation: currentElevation,
                          documentEdited: currentDocumentEdited)
        }

        image.location = location
        image.elevation = elevation
        if let pairedID = image.pairedID {
            let pairedImage = tvm[pairedID]
            if pairedImage.isValid {
                pairedImage.location = location
                pairedImage.elevation = elevation
            }
        }
        isDocumentEdited = documentEdited
    }

    // Update an image with a new timestamp.  Image is identifid by its ID
    // timestamp is in the string format used by Exiftool

    func update(_ image: ImageModel, timestamp: String?,
                documentEdited: Bool = true) {
        let currentDateTimeCreated = image.dateTimeCreated
        let currentDocumentEdited = isDocumentEdited
        undoManager.registerUndo(withTarget: self) { target in
            target.update(image, timestamp: currentDateTimeCreated,
                          documentEdited: currentDocumentEdited)
        }
        image.dateTimeCreated = timestamp
        isDocumentEdited = documentEdited
    }

    // Add track overlays to the map

    func updateTracks(gpx: Gpx) {
        guard gpx.tracks.count > 0 else { return}
        // storage for min/max latitude found in the track
        var minlat = CLLocationDegrees(90)
        var minlon = CLLocationDegrees(180)
        var maxlat = CLLocationDegrees(-90)
        var maxlon = CLLocationDegrees(-180)
        var newOverlay = false
        for track in gpx.tracks {
            for segment in track.segments {
                var trackCoords = segment.points.map {
                    CLLocationCoordinate2D(latitude: $0.lat,
                                           longitude: $0.lon)
                }
                if !trackCoords.isEmpty {
                    for loc in trackCoords {
                        if loc.latitude < minlat {
                            minlat = loc.latitude
                        }
                        if loc.latitude > maxlat {
                            maxlat = loc.latitude
                        }
                        if loc.longitude < minlon {
                            minlon = loc.longitude
                        }
                        if loc.longitude > maxlon {
                            maxlon = loc.longitude
                        }
                    }
                    let mapLine = MKPolyline(coordinates: &trackCoords,
                                             count: segment.points.count)
                    MapViewModel.shared.mapLines.append(mapLine)
                    newOverlay = true
                }
            }
        }
        if newOverlay {
            MapViewModel.shared.mapSpan = MKCoordinateSpan(latitudeDelta: maxlat - minlat,
                                                           longitudeDelta: maxlon - minlon)
            MapViewModel.shared.currentMapCenter = Coords(latitude: (minlat + maxlat)/2,
                                                          longitude: (minlon + maxlon)/2)
            MapViewModel.shared.refreshTracks = true
        }
    }

}
