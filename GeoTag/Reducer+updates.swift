import Coords
import ImageData
import SwiftUI
import UDF

extension GeoTagReducer {
    // Update all selected images with the given coords

    func update(_ state: inout GeoTagState, coords: Coords) {
        for id in state.selection {
            update(&state, id: id, location: coords)
        }
    }

    // update a specific image with the given location and do a reverse
    // lookup to set the city/state/country/countryCode

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
        // TODO:
        // don't bother reverse geocoding items from the users
        // photo library
        // if image.pickerItem == nil {
        //     reverseGeocode(image)
        // }
        // if let pairedID = image.pairedID {
        //     let pairedImage = tvm[pairedID]
        //     if pairedImage.isValid {
        //         pairedImage.location = location
        //         pairedImage.elevation = elevation
        //         reverseGeocode(pairedImage)
        //     }
        // }
        state.unsavedChanges = true
    }
}
