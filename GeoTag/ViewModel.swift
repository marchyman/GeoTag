//
//  ViewModel.swift
//  GeoTag
//
//  Created by Marco S Hyman on 12/13/22.
//

import SwiftUI
import MapKit

// maintain state for GeoTag when running.  An instance if this class is
// created as a StateObject by GeoTagApp and passed in the environment.

@MainActor
final class ViewModel: ObservableObject {
    // The Apps main window.
    var window: NSWindow?
    var undoManager = UndoManager()

    // Let the user know when the app is busy
    @Published var showingProgressView = false

    // Type of optional sheet to attach to the content view
    // some sheets are associated with errors
    var sheetStack = [SheetInfo]()
    @Published var sheetType: SheetType?
    var sheetError: NSError?
    var sheetMessage: String?
    var saveIssues = [ImageModel.ID : String ]()

    // Confirmatin required
    @Published var presentConfirmation = false
    var confirmationMessage: String?
    var confirmationAction: (@MainActor () -> Void)?
    
    // Images to edit
    @Published var images = [ImageModel]()
    var saveInProgress = false

    // get/set an image from the table of images  given its ID.

    subscript(id: ImageModel.ID?) -> ImageModel {
         get {
             if let id {
                 if let image = images.first(where: { $0.id == id }) {
                     return image
                 }
             }
             // A view may hold on to an ID that is no longer in the table
             // If it tries to access the image associated with that id
             // return a fake image
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

    // State that changes when a menu item is picked.  Some menu actions
    // optionally need a context -- the image.id of the image to act upon
    @Published var selectedMenuAction: MenuAction = .none
    var menuContext: ImageModel.ID?

    // Tracks displayed on map and a timezone to use when matching image
    // timestamps to track logs and saving images.
    @Published var gpxTracks = [Gpx]()
    var timeZone: TimeZone?

    // GPX File Loading sheet information
    var gpxGoodFileNames = [String]()
    var gpxBadFileNames = [String]()

    // Keep track of the coords for the center of the map
    var mapCenter = Coords()
    var mapAltitude = 50000.0

    // Map Tracks and the containing span of the last track added
    var mapLines = [MKPolyline]()
    var mapSpan: MKCoordinateSpan?
    @Published var refreshTracks = false
}

// Add a sheet to display

extension ViewModel {
    struct SheetInfo {
        let sheetType: SheetType
        let sheetError: NSError?
        let sheetMessage: String?
    }

    func addSheet(type: SheetType, error: NSError? = nil, message: String? = nil) {
        if sheetType == nil {
            sheetType = type
            sheetError = error
            sheetMessage = message
        } else {
            // create a SheetInfo and add it to the stack of pending sheets
            sheetStack.append(SheetInfo(sheetType: type,
                                        sheetError: error,
                                        sheetMessage: message))
        }
    }
}

// convenience init for use with swiftui previews.  Provide a list
// of test images suitable for swiftui previews.

extension ViewModel {
    convenience init(images: [ImageModel]) {
        self.init()
        self.images = images
    }
}
