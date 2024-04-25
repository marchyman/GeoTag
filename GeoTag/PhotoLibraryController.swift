//
//  PhotoLibraryController.swift
//  GeoTag
//
//  Created by Marco S Hyman on 4/10/24.
//

import OSLog
import Photos
import PhotosUI
import SwiftUI

@MainActor
@Observable
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
    struct LibraryEntry {
        let item: PhotosPickerItem
        var asset: PHAsset?

        // fake a URL from the item.itemIdentifier

        var url: URL {
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
    func requestAuth() {
        PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
            self.enabled = status == .authorized
        }
    }
}

extension PhotoLibrary {
    static let logger = Logger(subsystem: Bundle.main.bundleIdentifier!,
                               category: "PhotoLibrary")
}

// functions to build a LibraryEntry and add it to the array of
// selected photos
extension PhotoLibrary {
    func addPhotos(from selection: [PhotosPickerItem],
                   to tvm: TableViewModel) {
        for item in selection {
            guard !isDuplicate(item, in: tvm) else { continue }
            let libraryEntry = LibraryEntry(item: item,
                                            asset: getAssets(for: item))
            let image = ImageModel(libraryEntry: libraryEntry)
            tvm.images.append(image)
        }
    }

    func isDuplicate(_ item: PhotosPickerItem,
                     in tvm: TableViewModel) -> Bool {
        return tvm.images.contains(where: {
            $0.id == Self.fakeURL(itemId: item.itemIdentifier)
        })
    }

    func getImage(for item: PhotosPickerItem) async -> Image? {
        // Data -> NSImage -> Image dance needed to get proper orientation of
        // HEIC images.
        if let data = try? await item.loadTransferable(type: Data.self),
           let nsImage = NSImage(data: data) {
            return Image(nsImage: nsImage)
        }
        return nil
    }

    func getAssets(for item: PhotosPickerItem?) -> PHAsset? {
        if let item, let id = item.itemIdentifier {
            let result = PHAsset.fetchAssets(withLocalIdentifiers: [id],
                                             options: nil)
            if let asset = result.firstObject {
                return asset
            }
        }
        return nil
    }
}

extension PhotoLibrary {
    func saveChanges(for index: Int,
                     of images: [ImageModel],
                     in timeZone: TimeZone?) {
        guard index >= 0 && index < images.count else { return }
        if let asset = images[index].asset {
            Task {
                let library = PHPhotoLibrary.shared()
                let image = images[index]
                do {
                    try await library.performChanges { [self] in
                        let assetChangeReqeust = PHAssetChangeRequest(for: asset)
                        if image.location != image.originalLocation ||
                           image.elevation != image.originalElevation {
                            assetChangeReqeust.location =
                                newLocation(from: image, in: timeZone)
                        }
                        if image.dateTimeCreated != image.originalDateTimeCreated {
                            assetChangeReqeust.creationDate = image.timestamp(for: nil)
                        }
                    }
                    // get the current asset and update the image
                    let newAsset = getAssets(for: image.pickerItem)
                    await MainActor.run {
                        images[index].loadLibraryMetadata(asset: newAsset)
                    }
                } catch {
                    Self.logger.error("saveChanges: \(error.localizedDescription, privacy: .public)")
                }
            }
        }
    }

    private func newLocation(from image: ImageModel,
                             in timeZone: TimeZone?) -> CLLocation? {
        if let coords = image.location {
            let altitude: Double
            let verticalAccuracy: Double
            if let elevation = image.elevation {
                altitude = elevation
                verticalAccuracy = 20   // a number picked out of the air
            } else {
                altitude = 0
                verticalAccuracy = 0
            }
            let timeStamp = image.gmtTimeStamp(timeZone)
            return CLLocation(coordinate: coords,
                              altitude: altitude,
                              horizontalAccuracy: 10,
                              verticalAccuracy: verticalAccuracy,
                              timestamp: timeStamp)
        }
        return nil
    }
}
