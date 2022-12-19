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

    // Set of image URLs used to detect duplicate images
    var processedURLs = Set<URL>()

    // Image Selection
    @Published var selectedIndex: Int? = nil
    @Published var selectedIndexes = [Int]()

    func selections(selected: Set<ImageModel.ID>) {
        if selected.isEmpty {
            selectedIndex = nil
            selectedIndexes = []
        } else {
            if selectedIndex == nil ||
               !selected.contains(images[selectedIndex!].id) {
                // set the "most" selected item as the first item selected
                selectedIndex = images.firstIndex { $0.id == selected.first }
            }
            // create the array of all selected images
            selectedIndexes = images.compactMap { image in
                if selected.contains(image.id) {
                    return images.firstIndex{ $0 == image }
                }
                return nil
            }
        }
    }

}
