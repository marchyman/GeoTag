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
        switch state[id].metadata.source {
        case .image, .xmp:
            reverseGeocode(&state, id: id)
        default:
            // reverse geocoding not needed for photos library assets
            break
        }
        // TODO:
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
    
    private func reverseGeocode(_ state: inout GeoTagState, id: ImageData.ID) {
        // until I figure out what to do

        state[id].metadata.city = nil
        state[id].metadata.state = nil
        state[id].metadata.country = nil
        state[id].metadata.countryCode = nil

        if let location = state[id].location(state.timeZone) {
            Task {
                if let fullAddress = try? await ReverseLocationFinder.shared.get(location) {
                    // TODO: how do I update the image without holding on
                    // to state which I can't do.
                    print(fullAddress)
                }
            }
        }
    }
}
