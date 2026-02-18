import OSLog
import Photos
import PhotosUI
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
    func requestAuth(authStatusUpdated: @Sendable @escaping () -> Void) {
        PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
            Self.logger.notice("Photo Library authorization: \(status.rawValue, privacy: .public)")
            Task { @MainActor in
                Self.shared.statusChanged(newStatus: status == .authorized)
                authStatusUpdated()
            }
        }
    }

    mutating func statusChanged(newStatus: Bool) {
        enabled = newStatus
    }
}

// Add items selected from the photo library

extension PhotoLibrary {
    func addPhotos(from items: [PhotosPickerItem],
                   store: Store<GeoTagState, GeoTagEvent>) async {
        Self.logger.notice("\(#function)")
    }
}
