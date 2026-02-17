import Metadata
import OSLog
import Photos
import PhotosUI
import SwiftUI

public struct Phototool {
    public static func metadata(from item: PhotosPickerItem, asset: PHAsset) -> Metadata {
        var metadata = Metadata(source: .photos(item, asset))
        metadata.dateTimeCreated = if let date = asset.creationDate {
            Metadata.timestamp(from: date)
        } else {
            ""
        }
        metadata.location = asset.location?.coordinate
        metadata.elevation = asset.location?.altitude
        // no city/state/country in a PHAsset
        return metadata
    }

    public static func image(from item: PhotosPickerItem) async -> Image? {
        // Data -> NSImage -> Image dance needed to get proper orientation of
        // HEIC images.
        if let data = try? await item.loadTransferable(type: Data.self),
            let nsImage = NSImage(data: data) {
            return Image(nsImage: nsImage)
        }
        return nil
    }
}
