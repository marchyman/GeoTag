//
// Copyright 2023 Marco S Hyman
// See LICENSE file for info
// https://www.snafu.org/
//

import CoreLocation
import GpxTrackLog
import MapKit
import SwiftUI

// functions that handle location changes for both the map and images

extension AppState {

    // Update an image with a location.
    // Elevation is optional and is only provided when matching track logs

    func update(
        _ image: ImageModel, location: Coords?,
        elevation: Double? = nil, documentEdited: Bool = true
    ) {
        if undoManager.isUndoing {
            Self.logger.notice(
                """
                Undo in progress: \(image.name, privacy: .public): \
                \(image.location.debugDescription, privacy: .public) -> \
                \(location.debugDescription, privacy: .public)
                """)
        } else if undoManager.isRedoing {
            Self.logger.notice(
                """
                Redo in progress: \(image.name, privacy: .public): \
                \(image.location.debugDescription, privacy: .public) -> \
                \(location.debugDescription, privacy: .public)
                """)
        } else {
            Self.logger.notice(
                """
                undoManager registration: \(image.name, privacy: .public): \
                \(image.location.debugDescription, privacy: .public) -> \
                \(location.debugDescription, privacy: .public)
                """)
        }

        let currentLocation = image.location
        let currentElevation = image.elevation
        let currentDocumentEdited = isDocumentEdited
        undoManager.registerUndo(withTarget: self) { target in
            Task { @MainActor in
                target.update(
                    image, location: currentLocation,
                    elevation: currentElevation,
                    documentEdited: currentDocumentEdited)
            }
        }
        image.location = location
        image.elevation = elevation
        reverseGeocode(image)
        if let pairedID = image.pairedID {
            let pairedImage = tvm[pairedID]
            if pairedImage.isValid {
                pairedImage.location = location
                pairedImage.elevation = elevation
                reverseGeocode(pairedImage)
            }
        }
        isDocumentEdited = documentEdited
    }

    // Revese geocode an image's location and update the
    // city/state/county/countyCode

    private func reverseGeocode(_ image: ImageModel) {
        if let fullLocation = image.fullLocation(timeZone) {
            Task {
                let geoCoder = CLGeocoder()
                let placeMarks =
                    try? await geoCoder.reverseGeocodeLocation(fullLocation)
                if let placeMark = placeMarks?.first {
                    image.city = placeMark.locality
                    image.state = placeMark.administrativeArea
                    image.country = placeMark.country
                    image.countryCode = placeMark.isoCountryCode
                }
            }
        } else {
            image.city = nil
            image.state = nil
            image.country = nil
            image.countryCode = nil
        }
    }

    // Update an image with a new timestamp.  Image is identifid by its ID.
    // timestamp is in the string format used by Exiftool

    func update(
        _ image: ImageModel, timestamp: String?,
        documentEdited: Bool = true
    ) {
        let currentDateTimeCreated = image.dateTimeCreated
        let currentDocumentEdited = isDocumentEdited
        undoManager.registerUndo(withTarget: self) { target in
            Task { @MainActor in
                target.update(
                    image, timestamp: currentDateTimeCreated,
                    documentEdited: currentDocumentEdited)
            }
        }
        image.dateTimeCreated = timestamp
        isDocumentEdited = documentEdited
    }

    // Add track overlays to the map.  This is not undoable.

    func updateTracks(trackLog: GpxTrackLog) {
        guard trackLog.tracks.count > 0 else { return }
        for track in trackLog.tracks {
            for segment in track.segments {
                let trackCoords = segment.points.map {
                    CLLocationCoordinate2D(
                        latitude: $0.lat,
                        longitude: $0.lon)
                }
                if !trackCoords.isEmpty {
                    masData.add(coords: trackCoords)
                }
            }
        }
    }

}
