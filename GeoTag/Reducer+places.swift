import MapKit
import OSLog
import SwiftUI

let maxPlaces = 10      // used when testing

// Functions to update the list of visited places and store
// them in the Application Support folder so they won't be lost between
// program runs.

extension GeoTagReducer {

    // set the current place and add it to the array of places unless
    // already there.  The array is capped at maxPlaces entries

    func savePlace(_ state: inout GeoTagState, _ place: Place) {
        if !state.places.contains(where: { $0.name == place.name }) {
            state.places.append(place)
            if state.places.count > maxPlaces {
                state.places.removeFirst()
            }
            writePlaces(state.places)
        }
    }

    // clear the list of Places

    func clearPlaces(_ state: inout GeoTagState) {
        state.places = []
        writePlaces([])
    }

    // use the PlaceSaver actor to write the current list of places

    private func writePlaces(_ places: [Place]) {
        Task {
            do {
                try await PlaceSaver.shared.write(places: places)
            } catch {
                logger.error("cannot write search places: \(error.localizedDescription, privacy: .public)")
            }
        }
    }
}
