import Imagetool
import Phototool
import PhotosUI
import SwiftUI

extension ImageData {
    public func makeThumbnail() async -> Image {
        switch metadata.source {
        case .image(let url), .xmp(let url):
            if let nsImage = Imagetool.imageThumbnail(url: url) {
                return Image(nsImage: nsImage)
            }
        case .photos(let pickerItem, _):
            if let thumbnail = await Phototool.image(from: pickerItem) {
                return thumbnail
            }
        default:
            break
        }
        return Image(systemName: "photo.badge.exclamationmark")
    }
}
