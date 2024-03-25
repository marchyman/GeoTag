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

    private init() {
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
