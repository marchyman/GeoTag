//
//  PhotoLibraryController.swift
//  GeoTag
//
//  Created by Marco S Hyman on 4/10/24.
//

import Photos
import PhotosUI
import SwiftUI

@Observable
final class PhotoLibrary {
    var enabled: Bool

    // force use of shared instance
    static var shared: PhotoLibrary = .init()
    private init() {
        enabled =
            PHPhotoLibrary.authorizationStatus(for: .readWrite) == .authorized
    }
}

// A photoLibrary entry containing data needed to update images
extension PhotoLibrary {
    struct LibraryEntry {
        let item: PhotosPickerItem
        let image: Image?
        var asset: PHAsset?

        // fake a URL from the item.itemIdentifier

        var url: URL {
            let id = item.itemIdentifier ?? UUID().uuidString
            let fakePath = "file://Photo/Library/\(id)"
            return URL(fileURLWithPath: fakePath)
        }

        init(item: PhotosPickerItem,
             image: Image?,
             asset: PHAsset?) {
            self.item = item
            self.image = image
            self.asset = asset
        }
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

// functions to build a LibraryEntry and add it to the array of
// selected photos
extension PhotoLibrary {
    func addPhotos(from selection: [PhotosPickerItem]) async {
        for item in selection {
            guard !isDuplicate(item) else { continue }
            let libraryEntry = LibraryEntry(item: item,
                                            image: await getImage(for: item),
                                            asset: getAssets(for: item))
            print(libraryEntry)
//            await MainActor.run {
//                libraryPhotos.append(libraryPhoto)
//            }
        }
    }

    func isDuplicate(_ item: PhotosPickerItem) -> Bool {
//        return libraryPhotos.contains(where: {
//            $0.item.itemIdentifier == item.itemIdentifier
//        })
        return false    // until I figure things out
    }

    func getImage(for item: PhotosPickerItem) async -> Image? {
        return try? await item.loadTransferable(type: Image.self)
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
