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

// first an extension to undoManage stolen from Matt Massicotte
// https://github.com/mattmassicotte/MainOffender/blob/main/Sources/MainOffender/UndoManager%2BMainActor.swift
// to get around @MainActor requirements of the calling function that are
// not met by the registerUndo callback.

extension UndoManager {
	@MainActor
	public func registerMainActorUndo<TargetType>(
		withTarget target: TargetType,
		handler: @escaping @MainActor (TargetType) -> Void
	)
	where TargetType: AnyObject {
		registerUndo(withTarget: target, handler: { handlerTarget in
			nonisolated(unsafe) let mainTarget = handlerTarget

			MainActor.assumeIsolated {
				handler(mainTarget)
			}
		})
	}
}

extension AppState {

    // Update an image with a location.
    // Elevation is optional and is only provided when matching track logs

    func update(
        _ image: ImageModel, location: Coords?,
        elevation: Double? = nil, documentEdited: Bool = true
    ) {
        func logFormat(_ location: Coords?, elevation: Double?) -> String {
            var formatted = "none"
            if let location {
                formatted = "\(location.latitude), \(location.longitude)"
                if let elevation {
                    formatted += ", \(elevation)"
                }
            }
            return formatted
        }

        Self.logger.notice(
            """
            \(self.undoManager.isUndoing
                ? "Undo in Progress: "
                : self.undoManager.isRedoing
                    ? "Redo in Progress: "
                    : "Registration: ") \(image.name, privacy: .public)
                  \(logFormat(image.location, elevation: image.elevation), privacy: .public) -> \
            \(logFormat(location, elevation: elevation), privacy: .public)
            """
        )

        let currentLocation = image.location
        let currentElevation = image.elevation
        let currentDocumentEdited = isDocumentEdited
        undoManager.registerMainActorUndo(withTarget: self) { target in
            target.update(image, location: currentLocation,
                          elevation: currentElevation,
                          documentEdited: currentDocumentEdited)
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
                if let placeMark = try? await ReverseLocationFinder.shared.get(fullLocation) {
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
        undoManager.registerMainActorUndo(withTarget: self) { target in
            target.update(image, timestamp: currentDateTimeCreated,
                          documentEdited: currentDocumentEdited)
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
