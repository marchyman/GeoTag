//
// Copyright 2024 Marco S Hyman
// See LICENSE file for info
// https://www.snafu.org/
//

import OSLog
import Photos
import PhotosUI
import SwiftUI

// Access to the users photo library.

@MainActor
final class PhotoLibrary {
    var enabled: Bool

    // force use of shared instance
    static var shared: PhotoLibrary = .init()
    private init() {
        enabled =
            PHPhotoLibrary.authorizationStatus(for: .readWrite) == .authorized
        Self.logger.notice("PhotoLibrary created")
    }
}

// A PhotoLibrary entry containing data needed to update images
extension PhotoLibrary {
    @MainActor
    struct LibraryEntry {
        let item: PhotosPickerItem
        var asset: PHAsset?

        // fake a URL from the item.itemIdentifier

        nonisolated var url: URL {
            PhotoLibrary.fakeURL(itemId: item.itemIdentifier)
        }
    }

    nonisolated static func fakeURL(itemId: String?) -> URL {
        let id = itemId ?? UUID().uuidString
        return URL(fileURLWithPath: id)
    }
}

// Request authorization to access users photo library
extension PhotoLibrary {
    func requestAuth(authStatusUpdated: @Sendable @escaping () -> Void) {
        PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
            Task { @MainActor in
                self.enabled = status == .authorized
                Self.logger.warning("Photo Library authorization: \(status.rawValue, privacy: .public)")
                authStatusUpdated()
            }
        }
    }
}

extension PhotoLibrary {
    static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier!,
        category: "PhotoLibrary")
}

// functions to build a LibraryEntry and add it to the array of
// selected photos
extension PhotoLibrary {
    func addPhotos(
        from selection: [PhotosPickerItem],
        to tvm: TableViewModel
    ) async {
        for item in selection {
            let itemId = Self.fakeURL(itemId: item.itemIdentifier)
            guard !tvm.images.contains(where: { $0.id == itemId }) else {
                continue
            }
            let libraryEntry =
                await LibraryEntry(
                    item: item,
                    asset: getAssets(for: item.itemIdentifier))
            let image = ImageModel(libraryEntry: libraryEntry)
            tvm.images.append(image)
        }
    }

    func getImage(for item: PhotosPickerItem) async -> Image? {
        // Data -> NSImage -> Image dance needed to get proper orientation of
        // HEIC images.
        if let data = try? await item.loadTransferable(type: Data.self),
            let nsImage = NSImage(data: data)
        {
            return Image(nsImage: nsImage)
        }
        return nil
    }

    func getAssets(for itemId: String?) async -> PHAsset? {
        if let itemId {
            let result = PHAsset.fetchAssets(
                withLocalIdentifiers: [itemId],
                options: nil)
            if let asset = result.firstObject {
                return asset
            }
        }
        return nil
    }
}

extension PhotoLibrary {
    func saveChanges(
        for index: Int,
        of images: [ImageModel],
        in timeZone: TimeZone?
    ) {
        guard index >= 0 && index < images.count else { return }
        if let asset = images[index].asset {
            Task {
                let library = PHPhotoLibrary.shared()
                let image = images[index]
                do {
                    try await library.performChanges {
                        let assetChangeReqeust = PHAssetChangeRequest(
                            for: asset)
                        if image.location != image.originalLocation
                            || image.elevation != image.originalElevation
                        {
                            assetChangeReqeust.location =
                                image.fullLocation(timeZone)
                        }
                        if image.dateTimeCreated
                            != image.originalDateTimeCreated
                        {
                            assetChangeReqeust.creationDate = image.timestamp(
                                for: nil)
                        }
                    }
                    // get the current asset and update the image
                    let newAsset =
                        await getAssets(for: image.pickerItem?.itemIdentifier)
                    await MainActor.run {
                        images[index].loadLibraryMetadata(asset: newAsset)
                    }
                } catch {
                    Self.logger.error(
                        "saveChanges: \(error.localizedDescription, privacy: .public)"
                    )
                }
            }
        }
    }
}
