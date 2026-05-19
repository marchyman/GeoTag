import Imagetool
import Phototool
import PhotosUI
import SwiftUI

extension ImageData {
    public func makeThumbnail(scale: CGFloat) async -> Image {
        var image: Image?
        switch metadata.source {
        case .image(let url), .xmp(let url):
            if let nsImage = Imagetool.imageThumbnail(url: url) {
                image = Image(nsImage: nsImage)
            }
        case .photos(let pickerItem, _):
            if let thumbnail = await Phototool.image(from: pickerItem) {
                image = thumbnail
            }
        default:
            break
        }
        if image == nil {
            // try to create an image of noImageView for proper
            // opacity
            await MainActor.run {
                let renderer = ImageRenderer(content: noImageView())
                renderer.scale = scale
                if let nsImage = renderer.nsImage {
                    image = Image(nsImage: nsImage)
                }
            }
        }
        if let image {
            return image
        }
        return Image(systemName: "photo.badge.exclamationmark")
    }

    func noImageView() -> some View {
        VStack {
            Image(systemName: "photo.badge.exclamationmark")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .opacity(0.18)
        }
        .frame(width: 1024, height: 1024)
    }
}
