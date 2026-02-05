import Metadata
import OSLog
import Photos

struct Phototool {
    public static func metadata(from asset: PHAsset) -> Metadata {
        var metadata = Metadata(source: .photos(asset))
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
}
