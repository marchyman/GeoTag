import ImageData
import OSLog
import Photos
import PhotosUI
import Phototool
import SwiftUI
import UDF

struct PhotoLibrary {
    var enabled: Bool
    @MainActor static var shared: PhotoLibrary = .init()

    private init() {
        enabled =
            PHPhotoLibrary.authorizationStatus(for: .readWrite) == .authorized
        let isEnabled = enabled
        Self.logger.notice("PhotoLibrary enabled \(isEnabled ? "true" : "false", privacy: .public)")
    }
}

// PhotoLibrary logging

extension PhotoLibrary {
    static let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "GeoTag",
                               category: "PhotoLibrary")
}

// Request authorization to use Photo Library

extension PhotoLibrary {
    func requestAuth(authStatusUpdated: @MainActor @Sendable @escaping (Bool) -> Void) {
        PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
            Self.logger.notice("Photo Library authorization: \(status.rawValue, privacy: .public)")
            Task { @MainActor in
                authStatusUpdated(status == .authorized)
            }
        }
    }
}

// Add items selected from the photo library

extension PhotoLibrary {
    func addPhotos(from items: [PhotosPickerItem],
                   store: Store<GeoTagState, GeoTagEvent>) async {
        // Self.logger.debug("\(#function)")
        var dupsFound = false
        for item in items {
            if let id = item.itemIdentifier {
                if await isDup(id, in: store) {
                    Self.logger.debug("dup id: \(id, privacy: .public)")
                    dupsFound = true
                    continue
                }
                let asset = await Phototool.assets(for: id)
                let imageData = ImageData(from: item, asset: asset)
                await store.send(.addImage(imageData))
            }
        }
        if dupsFound {
            await store.send(.duplicateImages, undoable: false)
        }
    }

    // return true if the item exists in the table of opened images

    @MainActor
    func isDup(_ id: String,
               in store: Store<GeoTagState, GeoTagEvent>) -> Bool {
        for ix in store.imageData.indices {
            if case .photos(let item, _) = store.imageData[ix].metadata.source,
               item.itemIdentifier == id {
                return true
            }
        }
        return false
    }
}
