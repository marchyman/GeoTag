//
//  ImageData.swift
//  GeoTag
//
//  Created by Marco S Hyman on 6/26/14.
//  Copyright (c) 2014 Marco S Hyman. All rights reserved.
//

import Cocoa

class ImageData: NSObject {

    //MARK: instance variables

    let url: NSURL
    var path: String {
        get {
            return url.path
        }
    }
    var name: String {
        get {
            return url.lastPathComponent
        }
    }

    var date: String = ""
    var latitude: Double?, originalLatitude: Double?
    var longitude: Double?, originalLongitude: Double?
    var image: NSImage!
    var validImage = false

    var stringRepresentation: String {
        get {
            if latitude && longitude {
                return "\(latitude) \(longitude)"
            }
            return ""
        }
    }

    //MARK: Init

    init(url: NSURL) {
        self.url = url;
        super.init()
        validImage = loadImageData()
        if latitude {
            originalLatitude = latitude
        }
        if longitude {
            originalLongitude = longitude
        }
    }

    //MARK: set/revert latitude and longitude for an image

    func setLatitude(latitude: Double?, longitude: Double?) {
        self.latitude = latitude
        self.longitude = longitude
    }

    func revertLocation() {
        latitude = originalLatitude
        longitude = originalLongitude
    }

    //MARK: extract image metadata and build thumbnail preview

    func loadImageData() -> Bool {
        if let imgRef = CGImageSourceCreateWithURL(url,
                                                   nil)?.takeRetainedValue() {
            // grab the image properties
            let imgProps = CGImageSourceCopyPropertiesAtIndex(imgRef, 0, nil).takeUnretainedValue() as NSDictionary
            let height = imgProps[kCGImagePropertyPixelHeight] as Int!
            let width = imgProps[kCGImagePropertyPixelWidth] as Int!
            if !height || !width {
                return false
            }

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
                // Create an NSImage from the preview
                let imgHeight = CGFloat(CGImageGetHeight(imgPreview))
                let imgWidth = CGFloat(CGImageGetWidth(imgPreview))
                let imgRect = NSMakeRect(0.0, 0.0, imgWidth, imgHeight)
                image = NSImage(size: imgRect.size)
                // 10.9 doesn't have CGContext
                image.lockFocus()
                if let currentContext = NSGraphicsContext.currentContext() {
                    var context: CGContext! = nil
                    if currentContext.respondsToSelector("CGContext") {
                        context = currentContext.CGContext
                    } else {
                        // graphicsPort is type UnsafePointer<()>
                        context = reinterpretCast(currentContext.graphicsPort)
                    }
                    if context {
                        CGContextDrawImage(context, imgRect, imgPreview)
                    }
                }
                image.unlockFocus()

                // extract image date/time created
                if let exifData = imgProps[kCGImagePropertyExifDictionary] as? NSDictionary! {
                    if let dto = exifData[kCGImagePropertyExifDateTimeOriginal] as? String! {
                        date = dto
                    }
                }

                // extract image existing gps info
                if let gpsData = imgProps[kCGImagePropertyGPSDictionary] as NSDictionary! {
                    if let lat = gpsData[kCGImagePropertyGPSLatitude] as Double! {
                        if let latRef = gpsData[kCGImagePropertyGPSLatitudeRef] as String! {
                            if latRef == "N" {
                                latitude = lat
                            } else {
                                latitude = -lat
                            }
                        }
                    }
                    if let lon = gpsData[kCGImagePropertyGPSLongitude] as Double! {
                        if let lonRef = gpsData[kCGImagePropertyGPSLongitudeRef] as String! {
                            if lonRef == "E" {
                                longitude = lon
                            } else {
                                longitude = -lon
                            }
                        }
                    }
                }

                return true
            }
        }
        return false
    }
}
