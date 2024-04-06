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
        // swiftlint: disable line_length
        if undoManager.isUndoing {
            Self.logger.debug("Undo in progress: \(image.name): \(image.location.debugDescription) -> \(location.debugDescription)")
        } else if undoManager.isRedoing {
            Self.logger.debug("Redo in progress: \(image.name): \(image.location.debugDescription) -> \(location.debugDescription)")
        } else {
            Self.logger.debug("undoManager registration: \(image.name): \(image.location.debugDescription) -> \(location.debugDescription)")
        }
        // swiftlint: enable line_length

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
        for track in gpx.tracks {
            for segment in track.segments {
                let trackCoords = segment.points.map {
                    CLLocationCoordinate2D(latitude: $0.lat,
                                           longitude: $0.lon)
                }
                if !trackCoords.isEmpty {
                    LocationModel.shared.add(track: trackCoords)
                }
            }
        }
    }

}
