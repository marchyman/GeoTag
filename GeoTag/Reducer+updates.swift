import Coords
import ImageData
import Metadata
import SwiftUI
import UDF

extension GeoTagReducer {
    // Update all selected images with the given coords

    func update(_ state: inout GeoTagState, coords: Coords) {
        for id in state.selection {
            update(&state, id: id, location: coords)
        }
    }

    // update a specific image with the given location

    func update(_ state: inout GeoTagState, id: ImageData.ID,
                location: Coords?, elevation: Double? = nil) {
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

        let logImg = state[id]
        logger.notice("""
            \(logImg.name, privacy: .public)
                \(logFormat(logImg.metadata.location,
                            elevation: logImg.metadata.elevation), privacy: .public) -> \
            \(logFormat(location, elevation: elevation), privacy: .public)
            """)

        state[id].metadata.location = location
        state[id].metadata.elevation = elevation
        if let pairedID = state[id].pairedID, state[pairedID].updatable {
            state[pairedID].metadata.location = location
            state[pairedID].metadata.elevation = elevation
        }
        state.unsavedChanges = true
    }

    // update a specific image with reverse geocode information

    func update(_ state: inout GeoTagState, selected: Set<ImageData.ID>,
                address: Place) {
        for id in selected {
            state[id].metadata.city = address.city
            state[id].metadata.state = address.state
            state[id].metadata.country = address.country
            state[id].metadata.countryCode = address.countryCode
            if let pairedID = state[id].pairedID, state[pairedID].updatable {
                state[pairedID].metadata.city = address.city
                state[pairedID].metadata.state = address.state
                state[pairedID].metadata.country = address.country
                state[pairedID].metadata.countryCode = address.countryCode
            }
        }
    }

    // adjust the timestamp of all selected images by the given amount
    // If the image did not have an original timestamp assign the given date

    func update(_ state: inout GeoTagState,
                date: Date, adjustment: TimeInterval) {
        for id in state.selection {
            let updatedDate: Date
            if state[id].metadata.dateTimeCreated == nil {
                updatedDate = date
            } else {
                let originalDate = state[id].metadata.date(timeZone: state.timeZone)
                updatedDate = Date(timeInterval: adjustment,
                                   since: originalDate)
            }
            state[id].metadata.dateTimeCreated =
                Metadata.timestamp(from: updatedDate)
        }
    }
}
