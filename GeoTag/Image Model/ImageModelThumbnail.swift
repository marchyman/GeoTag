//
// Copyright 2022 Marco S Hyman
// See LICENSE file for info
// https://www.snafu.org/
//

import AppKit
import SwiftUI

extension ImageModel {

    // create a thumbnail image
    // if an image can not be created a placeholder image is returned

    func makeThumbnail() async -> Image {
        // first check if the image came from the Photos Library
        if let pickerItem {
            let library = await PhotoLibrary.shared
            if let thumbnail = await library.getImage(for: pickerItem) {
                return thumbnail
            }
            return Image(systemName: "exclamationmark.octagon.fill")
        }

        // build an image of an appropriate size
        var image = NSImage(size: NSRect(x: 0, y: 0, width: 0, height: 0).size)
        guard let imgRef = CGImageSourceCreateWithURL(fileURL as CFURL, nil)
        else {
            return Image(systemName: "photo")
        }

        // Create a "preview" of the image. If the image is larger than
        // 1024x1024 constraint the preview to that size.  1024x1024 is an
        // arbitrary limit.   Preview generation is used to work around a
        // performance hit when using large raw images
        let maxDimension = 1024.0
        var imgOpts: [String: AnyObject] = [
            ImageModel.createThumbnailWithTransform: kCFBooleanTrue,
            ImageModel.createThumbnailFromImageIfAbsent: kCFBooleanTrue,
            ImageModel.thumbnailMaxPixelSize: maxDimension as AnyObject
        ]
        var checkSize = true
        repeat {
            if let imgPreview = CGImageSourceCreateThumbnailAtIndex(
                imgRef, 0, imgOpts as NSDictionary)
            {
                // Create an NSImage from the preview
                let imgHeight = CGFloat(imgPreview.height)
                let imgWidth = CGFloat(imgPreview.width)
                if imgOpts[ImageModel.createThumbnailFromImageAlways] == nil
                    && imgHeight < maxDimension && imgWidth < maxDimension
                {
                    // thumbnail too small.   Build a larger thumbnail
                    imgOpts[ImageModel.createThumbnailFromImageIfAbsent] = nil
                    imgOpts[ImageModel.createThumbnailFromImageAlways] =
                        kCFBooleanTrue
                    continue
                }
                let imgRect = NSRect(
                    x: 0.0, y: 0.0, width: imgWidth, height: imgHeight)
                image = NSImage(size: imgRect.size)
                image.lockFocus()
                if let currentContext = NSGraphicsContext.current {
                    let context = currentContext.cgContext
                    context.draw(imgPreview, in: imgRect)
                }
                image.unlockFocus()
            }
            checkSize = false
        } while checkSize
        return Image(nsImage: image)
    }
}

// CFString to String casts for Image constants

extension ImageModel {
    static let createThumbnailWithTransform =
        kCGImageSourceCreateThumbnailWithTransform as String
    static let createThumbnailFromImageAlways =
        kCGImageSourceCreateThumbnailFromImageAlways as String
    static let createThumbnailFromImageIfAbsent =
        kCGImageSourceCreateThumbnailFromImageIfAbsent as String
    static let thumbnailMaxPixelSize =
        kCGImageSourceThumbnailMaxPixelSize as String
}
