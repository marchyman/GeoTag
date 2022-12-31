//
//  AppState.swift
//  GeoTag
//
//  Created by Marco S Hyman on 12/13/22.
//

import SwiftUI
import MapKit

// maintain state for GeoTag when running.  An instance if this class is
// created as a StateObject by GeoTagApp and passed in the environment.

@MainActor
final class AppState: ObservableObject {
    // The Apps main window.
    var window: NSWindow!

    // Let the user know the app is busy
    @Published var showingProgressView = false

    // Type of optional sheet to attach to the content view
    // some sheets are associated with errors
    @Published var sheetType: SheetType?
    var sheetError: NSError?
    var sheetMessage: String?

    // Images to edit
    @Published var images = [ImageModel]()

    // get/set an image from the table given its ID.
    subscript(id: ImageModel.ID?) -> ImageModel {
         get {
             if let id {
                 return images.first(where: { $0.id == id })!
             }
             // should never occur. Return a made up invalid image
             return ImageModel()
         }

         set(newValue) {
             if let index = images.firstIndex(where: { $0.id == newValue.id }) {
                 images[index] = newValue
             }
         }
     }

    // Selected Image(s) by ID, the most selected image, and its thumbnail
    @Published var selection = Set<ImageModel.ID>()
    @Published var selectedImage: ImageModel.ID?

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

    // Update an image with a location. Image is identified by its ID.
    // Handle UNDO!
    func update(id: ImageModel.ID, location: Coords?) {
        self[id].location = location
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
