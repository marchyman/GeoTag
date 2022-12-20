//
//  AppState.swift
//  GeoTag
//
//  Created by Marco S Hyman on 12/13/22.
//

import Foundation
import MapKit

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

    // Map pin info

    @Published var pin: MKPointAnnotation? = nil
    @Published var pinEnabled = false

    /// the optional location assigned to a pin on the map
    var location: Coords? {
        return pin?.coordinate
    }

    // create a point annotation if needed and assign to it the given location
    //
    func update(location: Coords) {
        if pin == nil {
            pin = MKPointAnnotation()
        }
// undo stuff here
//            undoManager?.registerUndo(withTarget: self) { handler in
//                let oldLocation = pin!.coordinate
//                self.pin!.coordinate = oldLocation
//           }
        pin!.coordinate = location
    }


}

// convenience init for use with swiftui previews.  Provide a list
// of test images suitable for swiftui previews.

extension AppState {
    convenience init(images: [ImageModel]) {
        self.init()
        self.images = images
    }
}
