//
//  MapViewModel.swift
//  GeoTag
//
//  Created by Marco S Hyman on 1/27/23.
//

import SwiftUI
import MapKit

// View Model for map related views.

@Observable
final class MapViewModel {
    var refreshTracks = false
    var onlyMostSelected = true
    var searchString = ""
    var reCenter = false

    public static let shared = MapViewModel()

    // Map pins
    var mainPin: MKPointAnnotation?
    var otherPins = [MKPointAnnotation]()

    // Keep track of the coords for the center of the map
    var currentMapCenter = Coords()
    var currentMapAltitude = 50000.0

    // Map Tracks and the containing span of the last track added
    var mapLines = [MKPolyline]()
    var mapSpan: MKCoordinateSpan?
}
