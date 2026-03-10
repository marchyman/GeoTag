import Metadata
import OSLog
import Photos
import PhotosUI
import SwiftUI

public struct Phototool {
    public static func metadata(from item: PhotosPickerItem, asset: PHAsset?) -> Metadata {
        var metadata = Metadata(source: .photos(item, asset))
        if let asset {
            metadata.dateTimeCreated = if let date = asset.creationDate {
                Metadata.timestamp(from: date)
            } else {
                nil
            }
            metadata.location = asset.location?.coordinate
            metadata.elevation = asset.location?.altitude
        }
        // no city/state/country in a PHAsset
        return metadata
    }

    // return an image from the photos library

    public static func image(from item: PhotosPickerItem) async -> Image? {
        // Data -> NSImage -> Image dance needed to get proper orientation of
        // HEIC images.
        if let data = try? await item.loadTransferable(type: Data.self),
            let nsImage = NSImage(data: data) {
            return Image(nsImage: nsImage)
        }
        let name: String
        if let id = item.itemIdentifier {
            let asset = await Self.assets(for: id)
            name = Self.name(from: asset)
        } else {
            name = "unknown item"
        }
        Logger(subsystem: Bundle.main.bundleIdentifier ?? "PhotoTool",
               category: "Phototool")
            .error("Can not extract image for item \(name, privacy: .public)")
        return nil
    }

    public static func assets(for id: String) async -> PHAsset? {
        let result = PHAsset.fetchAssets(withLocalIdentifiers: [id],
                                         options: nil)
        if let asset = result.firstObject {
            return asset
        }
        return nil
    }

    public static func name(from asset: PHAsset?) -> String {
        if let asset {
            let assetResources = PHAssetResource.assetResources(for: asset)
            return assetResources.first?.originalFilename ?? "unknown"
        }
        return "unknown"
    }

    public static func update(timestamp: Date? = nil,
                              location: CLLocation?,
                              for asset: PHAsset) async -> Bool {
        let library = PHPhotoLibrary.shared()
        do {
            try await library.performChanges {
                let assetChangeReqeust = PHAssetChangeRequest(for: asset)
                if let timestamp {
                    assetChangeReqeust.creationDate = timestamp
                }
                if let location {
                    assetChangeReqeust.location = location
                }
            }
            return true
        } catch {
            Logger(subsystem: Bundle.main.bundleIdentifier ?? "PhotoTool",
                   category: "Phototool")
                .error("update: \(error.localizedDescription, privacy: .public)")
            return false
        }
    }
}
