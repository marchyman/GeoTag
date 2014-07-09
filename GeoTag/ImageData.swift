//
//  ImageData.swift
//  GeoTag
//
//  Created by Marco S Hyman on 6/26/14.
//  Copyright (c) 2014 Marco S Hyman. All rights reserved.
//

import Cocoa

@objc(ImageData)
class ImageData: NSObject {

    let path: NSURL

    var name: String {
        get {
            return path.lastPathComponent
        }
    }

    var date: String = ""
    var latitude = 0.0, originalLatitude = 0.0
    var longitude = 0.0, originalLongitude = 0.0

    var image: NSImage!
    var validImage: Bool = false

    init(path: NSURL) {
        self.path = path;
        super.init()
        validImage = loadImageData()
        // more init here
    }

    func loadImageData() -> Bool {
        if let imgRef = CGImageSourceCreateWithURL(path, nil)?.takeRetainedValue() {
            /// grab the image properties
            let imgProps = CGImageSourceCopyPropertiesAtIndex(imgRef, 0, nil).takeUnretainedValue() as NSDictionary
            let height = imgProps["PixelHeight"] as Int!
            let width = imgProps["PixelWidth"] as Int!

            /// Create a "preview" of the image. If the image is larger than
            /// 512x512 constrain the preview to that size.  512x512 is an
            /// arbitrary limit.   Preview generation is used to work around a
            /// performance hit when using large raw images
            let maxDimension = 512
            var imgOpts: NSMutableDictionary = [
                kCGImageSourceCreateThumbnailWithTransform : kCFBooleanTrue as AnyObject,
                kCGImageSourceCreateThumbnailFromImageAlways : kCFBooleanTrue as AnyObject
            ]
            if height > maxDimension || width > maxDimension {
                // add a max pixel size to the dictionary of options
                imgOpts[kCGImageSourceThumbnailMaxPixelSize] = maxDimension as AnyObject
            }
            if let imgPreview = CGImageSourceCreateThumbnailAtIndex(imgRef, 0, imgOpts)?.takeRetainedValue() {
                /// Create an NSImage from the preview
                let imgHeight = Double(CGImageGetHeight(imgPreview))
                let imgWidth = Double(CGImageGetWidth(imgPreview))
                var imgRect = NSMakeRect(0.0, 0.0, imgHeight, imgWidth)
                image = NSImage(size: imgRect.size)
                image.lockFocus()
                CGContextDrawImage(NSGraphicsContext.currentContext().cgcontext, imgRect, imgPreview);
                image.unlockFocus()
                return true
            }
        }
        return false
    }
}


/*
 * Convert the graphicsPort to a COpaquePointer
 * fromOpaque turns the COpaquePointer to an Unmanaged<T>
 * takeUnretainedValue turns the Unmanaged<T> to an unretained T
 * It seems to work.
 */
extension NSGraphicsContext {
    var cgcontext: CGContext {
        let graphicsPort = NSGraphicsContext.currentContext().graphicsPort()
        let context = COpaquePointer(graphicsPort)
        println("context \(context)")
        let uValue = Unmanaged<CGContext>.fromOpaque(context)
        println("uValue \(uValue)")
        let value = uValue.takeUnretainedValue()
        println("value \(value)")
        return value
    }
}

