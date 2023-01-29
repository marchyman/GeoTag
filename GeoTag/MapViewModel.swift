//
//  MapViewModel.swift
//  GeoTag
//
//  Created by Marco S Hyman on 1/27/23.
//

import SwiftUI
import MapKit

// View Model for map related views.

final class MapViewModel: ObservableObject {
    @Published var refreshTracks = false
    @Published var onlyMostSelected = true
    @Published var searchString = ""
    @Published var reCenter = false

    @AppStorage(AppSettings.mapConfigurationKey)  var mapConfiguration = 0
    @AppStorage(AppSettings.mapLatitudeKey)  var initialMapLatitude = 37.7244
    @AppStorage(AppSettings.mapLongitudeKey)  var initialMapLongitude = -122.4381
    @AppStorage(AppSettings.mapAltitudeKey)  var initialMapAltitude = 50000.0
    @AppStorage(AppSettings.trackColorKey) var trackColor: Color = .blue
    @AppStorage(AppSettings.trackWidthKey) var trackWidth: Double = 0.0

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
