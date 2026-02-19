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
        Self.logger.notice("PhotoLibrary enabled \(isEnabled ? "true" : "false")")
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
        Self.logger.notice("\(#function)")
        for item in items {
            if let id = item.itemIdentifier {
                Self.logger.notice("\(id, privacy: .public)")
                // check for dups... how?
                // Look for .photos items with a matching id
                let asset = await Phototool.assets(for: id)
                let imageData = ImageData(from: item, asset: asset)
                await store.send(.addImage(imageData))
            }
        }
    }
}
