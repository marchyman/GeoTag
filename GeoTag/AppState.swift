//
//  AppState.swift
//  GeoTag
//
//  Created by Marco S Hyman on 12/13/22.
//

import Foundation

final class AppState: ObservableObject {
    @Published var images = [ImageModel]()
    @Published var gpxTracks = [Gpx]()

    // Type of sheet to attach to the content view
    @Published var sheetType: SheetType?

    // GPX File Loading sheet information
    var gpxGoodFileNames = [String]()
    var gpxBadFileNames = [String]()

}
