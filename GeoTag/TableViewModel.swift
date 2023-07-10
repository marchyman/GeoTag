//
//  TableViewModel.swift
//  GeoTag
//
//  Created by Marco S Hyman on 7/9/23.
//

import SwiftUI

// MARK: State variables used primarily to control the table of images

@Observable
final class TableViewModel {
    var images: [ImageModel] = []
    var selection: Set<ImageModel.ID> = []
    var mostSelected: ImageModel?

    // get/set an image from the table of images  given its ID.
    subscript(id: ImageModel.ID?) -> ImageModel {
        get {
            if let index = images.firstIndex(where: { $0.id == id }) {
                return images[index]
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

    // A copy of the current sort order
    var sortOrder = [KeyPathComparator(\ImageModel.name)]

    init() { }

    // init for preview

    init(images: [ImageModel]) {
        self.images.append(contentsOf: images)
    }
}
