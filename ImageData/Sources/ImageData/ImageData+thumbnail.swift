import SwiftUI

extension ImageData {
    public func makeThumbnail() -> Image {
        switch metadata.source {
        case .image(let url), .xmp(let url):
            if let nsImage = imageThumbnail(url: url) {
                return Image(nsImage: nsImage)
            }
        case .photos:
            // TODO: handle photos
            // if let pickerItem {
            //     let library = await PhotoLibrary.shared
            //     if let thumbnail = await library.getImage(for: pickerItem) {
            //         return thumbnail
            //     }
            //     return Image(systemName: "exclamationmark.octagon.fill")
            // }
            break
        default:
            break
        }
        return Image(systemName: "photo.badge.exclamationmark")
    }

    private func imageThumbnail(url: URL) -> NSImage? {
        var image = NSImage(size: NSRect(x: 0, y: 0, width: 0, height: 0).size)
        guard let imgRef = CGImageSourceCreateWithURL(url as CFURL, nil)
        else {
            return nil
        }

        // Create a "preview" of the image. If the image is larger than
        // 1024x1024 constraint the preview to that size.  1024x1024 is an
        // arbitrary limit.   Preview generation is used to work around a
        // performance hit when using large raw images
        let maxDimension = 1024.0
        var imgOpts: [String: AnyObject] = [
            Self.createThumbnailWithTransform: kCFBooleanTrue,
            Self.createThumbnailFromImageIfAbsent: kCFBooleanTrue,
            Self.thumbnailMaxPixelSize: maxDimension as AnyObject
        ]
        var checkSize = true
        repeat {
            if let imgPreview = CGImageSourceCreateThumbnailAtIndex(
                imgRef, 0, imgOpts as NSDictionary) {
                // Create an NSImage from the preview
                let imgHeight = CGFloat(imgPreview.height)
                let imgWidth = CGFloat(imgPreview.width)
                if imgOpts[Self.createThumbnailFromImageAlways] == nil
                    && imgHeight < maxDimension && imgWidth < maxDimension {
                    // thumbnail too small.   Build a larger thumbnail
                    imgOpts[Self.createThumbnailFromImageIfAbsent] = nil
                    imgOpts[Self.createThumbnailFromImageAlways] =
                        kCFBooleanTrue
                    continue
                }
                image = NSImage(cgImage: imgPreview, size: .zero)
            } else {
                // could not create a preview
                return nil
            }
            checkSize = false
        } while checkSize
        return image
    }
}

// CFString to String casts for Image constants

extension ImageData {
    static let createThumbnailWithTransform =
        kCGImageSourceCreateThumbnailWithTransform as String
    static let createThumbnailFromImageAlways =
        kCGImageSourceCreateThumbnailFromImageAlways as String
    static let createThumbnailFromImageIfAbsent =
        kCGImageSourceCreateThumbnailFromImageIfAbsent as String
    static let thumbnailMaxPixelSize =
        kCGImageSourceThumbnailMaxPixelSize as String
}
