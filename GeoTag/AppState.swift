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
            deleteAction()
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

    // MARK: Items pertaining to the Map pins and Image Locations

    // Map pin info

    @Published var pin: MKPointAnnotation? = nil
    @Published var pinEnabled = false

    // create a map pin annotation if needed and assign to it the given location
    //
    func updatePin(location: Coords?) {
        if pin == nil {
            pin = MKPointAnnotation()
        }
        if let location {
            let point = MKMapPoint(location);
            if !MapView.view.visibleMapRect.contains(point) {
                MapView.view.setCenter(location, animated: false)
            }
            pin!.coordinate = location
            pinEnabled = true
        } else {
            pinEnabled = false
        }
    }

    // Update the image with a location
    // Handle UNDO!
    func update(image: ImageModel, location: Coords?) {
        image.location = location
        window.isDocumentEdited = true
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
