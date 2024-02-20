//
//  TableViewModel.swift
//  GeoTag
//
//  Created by Marco S Hyman on 7/9/23.
//

import SwiftUI
import OSLog

// MARK: State variables used primarily to control the table of images

@Observable
final class TableViewModel {
    var images: [ImageModel] = []
    var selection: Set<ImageModel.ID> = []
    var selected: [ImageModel] {
        selection.map { self[$0] }
    }
    var mostSelected: ImageModel?

    // get/set an image from the table of images  given its ID.
    subscript(id: ImageModel.ID?) -> ImageModel {
        get {
            if let index = images.firstIndex(where: { $0.id == id }) {
                Self.logger.trace("get \(self.images[index].name)")
                return images[index]
            }

            // A view may hold on to an ID that is no longer in the table
            // If it tries to access the image associated with that id
            // return a fake image
            return ImageModel()
        }

        set(newValue) {
            if let index = images.firstIndex(where: { $0.id == newValue.id }) {
                Self.logger.trace("set \(newValue.name)")
                images[index] = newValue
            }
        }
    }

    // A copy of the current sort order
    var sortOrder = [KeyPathComparator(\ImageModel.name)]

    // Instruments performance logging tools
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

    init() {
        Self.logger.trace("TableViewModel created")
    }

    // init for preview

    init(images: [ImageModel]) {
        self.images.append(contentsOf: images)
    }
}
