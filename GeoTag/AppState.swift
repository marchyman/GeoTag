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
    // MARK: Items pertaining to the main window and content view

    // The Apps main window.
    var window: NSWindow!

    // Type of optional sheet to attach to the content view
    // some sheets are associated with errors
    @Published var sheetType: SheetType?
    var sheetError: NSError?
    var sheetMessage: String?

    // MARK: Items pertaining to the Table of images

    // Images to edit
    @Published var images = [ImageModel]()

    // Set of image URLs used to detect duplicate images
    var processedURLs = Set<URL>()

    // Selected Image(s) by ID, the most selected image, and its thumbnail
    @Published var selection = Set<ImageModel.ID>()
    @Published var selectedImage: ImageModel?
    @Published var selectedImageThumbnail: NSImage?

    // Process the set of selected images.  Pick one as the "most" selected
    // and make its thumbnail NSImage.
    func selectionChanged(newSelection: Set<ImageModel.ID>) {
        guard !newSelection.isEmpty else {
            selectedImage = nil
            selectedImageThumbnail = nil
            return
        }

        // filter out any ids in the selection that don't reference valid images
        let filteredImagesIds = images.filter { $0.isValid }.map { $0.id }
        let filteredSelection = newSelection.filter {
            filteredImagesIds.contains($0)
        }

        // Update the selection if the counts don't match
        if selection.count != filteredSelection.count {
            selection = filteredSelection
            guard !selection.isEmpty else {
                selectedImage = nil
                selectedImageThumbnail = nil
                return
            }
        }

        // set the most selected image and its thumbnail
        selectedImage = images.first { $0.id == selection.first }
        Task {
            selectedImageThumbnail = await selectedImage!.makeThumbnail()
        }
    }

    // Is there a selected and valid image?  THIS SHOULD GO AWAY
    var isSelectedImageValid: Bool {
        selectedImage?.isValid ?? false
    }

    // Should the cut or copy action be enabled for the selected image
    var canCutOrCopy: Bool {
        isSelectedImageValid && selectedImage?.location != nil
    }

    // MARK: Menu actions

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

    // Do the requested action

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
            selection = Set(images.map { $0.id })
        case .clearList:
            clearImageListAction()
        }
    }

    // MARK: Items related to GPX track loading

    // Tracks displayed on map
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
