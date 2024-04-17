//
//  TableViewModel.swift
//  GeoTag
//
//  Created by Marco S Hyman on 7/9/23.
//

import SwiftUI
import OSLog

// MARK: State variables used primarily to control the table of images

@MainActor
@Observable
final class TableViewModel {
    var images: [ImageModel] = []
    var filteredImages: [ImageModel] {
        @AppStorage(AppSettings.hideInvalidImagesKey) var hideInvalidImages = false

        return hideInvalidImages ? images.filter { $0.isValid }
                                 : images
    }
    var selection: Set<ImageModel.ID> = [] {
        didSet {
            selectionChanged()
        }
    }
    var selected: [ImageModel] = []
    var mostSelected: ImageModel?

    // get an image from the table of images  given its ID.
    // No setter is defined
    subscript(id: ImageModel.ID?) -> ImageModel {
        if let index = images.firstIndex(where: { $0.id == id }) {
            Self.logger.notice("get \(self.images[index].name, privacy: .public)")
            return images[index]
        }

        // A view may hold on to an ID that is no longer in the table
        // If it tries to access the image associated with that id
        // return a fake image
        return ImageModel()
    }

    // A copy of the current sort order
    var sortOrder = [KeyPathComparator(\ImageModel.name)]

    init() {
        Self.logger.notice("TableViewModel created")
    }

    // init for preview

    init(images: [ImageModel]) {
        self.images.append(contentsOf: images)
    }
}

extension TableViewModel {

    private static let logger = Logger(subsystem: "org.snafu.GeoTag",
                                       category: "TableView")
    private static let signposter = OSSignposter(logger: logger)

    func markStart(_ desc: StaticString) -> OSSignpostIntervalState {
        let signpostID = Self.signposter.makeSignpostID()
        let interval = Self.signposter.beginInterval(desc, id: signpostID)
        return interval
    }

    func markEnd(_ desc: StaticString, interval: OSSignpostIntervalState) {
        Self.signposter.endInterval(desc, interval)
    }

    func withInterval<T>(_ desc: StaticString,
                         around task: () throws -> T) rethrows -> T {
        try Self.signposter.withIntervalSignpost(desc) {
            try task()
        }
    }
    func withInterval<T>(_ image: ImageModel,
                         around task: () throws -> T) rethrows -> T {
        try Self.signposter.withIntervalSignpost("Render", "image \(image.name)") {
            try task()
        }
    }

}
