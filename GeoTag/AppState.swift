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
    var window: NSWindow?

    // Let the user know the app is busy
    @Published var showingProgressView = false

    // Type of optional sheet to attach to the content view
    // some sheets are associated with errors
    @Published var sheetType: SheetType?
    var sheetError: NSError?
    var sheetMessage: String?

    // Images to edit
    @Published var images = [ImageModel]()

    // get/set an image from the table of images  given its ID.
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

    // Selected Image(s) by ID and the most selected image
    @Published var selection = Set<ImageModel.ID>()
    @Published var mostSelected: ImageModel.ID?

    // State that changes when a menu item is picked.
    @Published var selectedMenuAction: MenuAction = .none

    // Tracks displayed on map
    @Published var gpxTracks = [Gpx]()

    // GPX File Loading sheet information
    var gpxGoodFileNames = [String]()
    var gpxBadFileNames = [String]()

    // Map pin info
    @Published var pin: MKPointAnnotation? = nil
    @Published var pinEnabled = false

}




// convenience init for use with swiftui previews.  Provide a list
// of test images suitable for swiftui previews.

extension AppState {
    convenience init(images: [ImageModel]) {
        self.init()
        self.images = images
    }
}
