//
// Copyright 2024 Marco S Hyman
// See LICENSE file for info
// https://www.snafu.org/
//

import MapKit
import OSLog
import SwiftUI

@MainActor
@Observable
public final class MapAndSearchData {
    // map camera control
    var cameraPosition: MapCameraPosition = .automatic
    var cameraDistance: Double = 0
    var mapRect: MKMapRect?

    // pin control
    public var showOtherPins: Bool = false

    // tracks shown on map
    var tracks: [MapTrack] = []  // tracks shown on map

    // search related data
    var searchResult: SearchPlace?
    var searchPlaces: [SearchPlace] = []
    var searchText: String = ""
    var pickFirst = false
    public var searchBarActive = false {
        didSet {
            if searchBarActive != oldValue {
                logger.debug("SearchBarActive: \(self.searchBarActive, privacy: .public)")
            }
        }
    }
    @ObservationIgnored
    var writing = false

    @ObservationIgnored
    let showLocation: Bool  // set when performing some XCUITests
    @ObservationIgnored
    let logger: Logger  // package logging

    public init() {
        showLocation = ProcessInfo.processInfo.environment["MAPTEST"] != nil
        logger = Logger(
            subsystem: Bundle.main.bundleIdentifier!,
            category: "MapAndSearchViews")
        logger.notice("MapAndSearchData created")
        Task {
            searchPlaces = fetchPlaces()
        }
    }
}

extension MapAndSearchData {
    // an identifiable container for map tracks
    struct MapTrack: Identifiable {
        let id = UUID()
        let coords: [CLLocationCoordinate2D]
    }

    // add a track to the map
    public func add(coords: [CLLocationCoordinate2D]) {
        let track = MapTrack(coords: coords)
        tracks.append(track)
        logger.info("\(#function): MapTrack added to map")
        // this centers the map on the track(s)
        cameraPosition = .automatic
    }

    // remove all tracks from the map
    public func removeTracks() {
        tracks = []
    }
}

extension MapAndSearchData {

    // change the map camera position
    func setCameraPosition(to coords: CLLocationCoordinate2D) {
        cameraPosition = .camera(
            .init(
                centerCoordinate: coords,
                distance: cameraDistance))
    }

    // recenter the map if the given location is not in the current
    // map rectangle.
    func recenterMap(coords: CLLocationCoordinate2D?) {
        if let coords {
            if let rect = mapRect {
                if rect.contains(MKMapPoint(coords)) {
                    return
                }
            }
            setCameraPosition(to: coords)
        }
    }

    // return a string containing the lat/lon of the center of the map
    // if known. Used when showLocation is set for XCUITests
    var centerLocation: String {
        if let camera = cameraPosition.camera {
            return """
                Lat: \(camera.centerCoordinate.latitude)
                Lon: \(camera.centerCoordinate.longitude)
                """
        } else {
            return "Unknown center"
        }
    }
}

extension MapAndSearchData {
    struct OtherPins: Identifiable {
        let id = UUID()
        let location: CLLocationCoordinate2D
    }

    // Return an array of "other" pins where "other" excludes
    // the main pin. This is controlled by the "showOtherPins" flag
    // controlled by the user.

    func otherPins(
        mainPin: Locatable?,
        allPins: [Locatable]
    ) -> [OtherPins] {
        if showOtherPins && !allPins.isEmpty {
            let convertedPins =
                allPins.filter { $0.location != nil }
                .map { OtherPins(location: $0.location!) }
            if let mainLocation = mainPin?.location {
                // filter out items with the same location as mainPin
                return convertedPins.filter { $0.location != mainLocation }
            }
            return convertedPins
        }
        return []
    }
}

// Extend CLLocationCoordinate2D by adding Equatable conformance

extension CLLocationCoordinate2D: @retroactive Equatable {
    static public func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude
    }
}
