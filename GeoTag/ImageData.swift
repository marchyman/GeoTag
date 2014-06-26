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

    var image: NSImage?
    var validImage: Bool = false

    init(path: NSURL) {
        self.path = path;
        super.init()
        validImage = loadImageData()
    }

    func loadImageData() -> Bool {
        /*
         * Create an image source and grab the image properties
         */
        var imgRef = CGImageSourceCreateWithURL(path, nil).takeRetainedValue()
        if imgRef == nil {
            return false
        }
        var imgProps = CGImageSourceCopyPropertiesAtIndex(imgRef, 0, nil).takeUnretainedValue() as NSDictionary
        println(imgProps)       // Debug

        /*
         * Create a "thumbnail" of the image. If the image is larger than
         * 512x512 constrain the thumbnail to that size.  512x512 is an
         * arbitrary limit.   Thumbnail generation is used to work around a
         * performance hit when using large raw images
         */
        var height = imgProps["PixelHeight"] as Int!
        var width = imgProps["PixelWidth"] as Int!
        var imgOpts: NSMutableDictionary =
            [kCGImageSourceCreateThumbnailWithTransform : kCFBooleanTrue as AnyObject,
             kCGImageSourceCreateThumbnailFromImageAlways : kCFBooleanTrue as AnyObject]
        if height > 512 || width > 512 {
            imgOpts[kCGImageSourceThumbnailMaxPixelSize] = NSNumber.numberWithInt(512) as AnyObject
        }
        var imgPreview = CGImageSourceCreateThumbnailAtIndex (imgRef, 0, imgOpts).takeRetainedValue()
        ///
        return true
    }
}

