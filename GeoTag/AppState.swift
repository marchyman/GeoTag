//
//  AppState.swift
//  GeoTag
//
//  Created by Marco S Hyman on 12/13/22.
//

import SwiftUI
import MapKit

@MainActor
final class AppState: ObservableObject {
    // MARK: Items pertaining to the main window

    // Type of sheet to attach to the content view
    @Published var sheetType: SheetType?

    // MARK: Items pertaining to the Table of images

    // Images to edit
    @Published var images = [ImageModel]()

    // Set of image URLs used to detect duplicate images
    var processedURLs = Set<URL>()

    // Image Selection
    @Published var selectedImage: NSImage?
    @Published var selectedIndex: Int? = nil
    @Published var selectedIndexes = [Int]()

    func selections(selected: Set<ImageModel.ID>) {
        if selected.isEmpty {
            selectedImage = nil
            selectedIndex = nil
            selectedIndexes = []
        } else {
            if selectedIndex == nil ||
               !selected.contains(images[selectedIndex!].id) {
                // set the "most" selected item as the first item selected
                selectedIndex = images.firstIndex { $0.id == selected.first }
                Task {
                    selectedImage = await images[selectedIndex!].makeThumbnail()
                }
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

    // State changes that will triger actions as a result of selection
    // of a menu item

    @Published var selectedMenuAction: MenuAction = .none

    enum MenuAction: Identifiable {
        var id: Self {
            return self
        }

        case none
        case cut
        case copy
        case paste
        case delete
        case selectAll
        case clearList
    }

    func menuAction(_ action: MenuAction) {
        self.selectedMenuAction = .none
        switch action {
        case .none:
            return
        case .cut:
            print("action: \(action)")
        case .copy:
            print("action: \(action)")
        case .paste:
            print("action: \(action)")
        case .delete:
            print("action: \(action)")
        case .selectAll:
            print("action: \(action)")
        case .clearList:
            print("action: \(action)")
        }
    }

    // MARK: Items related to GPX track loading

    // Tracks displayed on may
    @Published var gpxTracks = [Gpx]()

    // GPX File Loading sheet information
    var gpxGoodFileNames = [String]()
    var gpxBadFileNames = [String]()

    // MARK: Items pertaining to the Map pins

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
