//
//  LocationModel.swift
//  SMap
//
//  Created by Marco S Hyman on 3/21/24.
//

import MapKit
import SwiftUI

@Observable
final class LocationModel {
    // shared instance
    static let shared: LocationModel = .init()

    var cameraPosition: MapCameraPosition = .automatic
    var cameraDistance: Double = 0
    var showOtherPins: Bool = false

    // displayed map tracks
    var tracks: [Track] = []

    let showLocation: Bool

    private init() {
        showLocation = ProcessInfo.processInfo.environment["MAPTEST"] != nil
        // use the shared instance
    }
}

// An identifiable container for tracks

extension LocationModel {
    struct Track: Identifiable {
        let id = UUID()
        let track: [Coords]
    }

    func add(track: [Coords]) {
        let newTrack = Track(track: track)
        tracks.append(newTrack)
        cameraPosition = .automatic
    }
}

// Format center location for UI User Interface testing
extension LocationModel {
    var centerLocation: String {
        if let camera = cameraPosition.camera {
            return  """
                    Lat: \(camera.centerCoordinate.latitude)
                    Lon: \(camera.centerCoordinate.longitude)
                    """
        } else {
            return "Unknown center"
        }
    }
}
