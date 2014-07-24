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
        return url.path
    }
    var name: String {
        return url.lastPathComponent
    }

    var date: String = ""
    var latitude: Double?, originalLatitude: Double?
    var longitude: Double?, originalLongitude: Double?
    var image: NSImage!
    var validImage = false

    var stringRepresentation: String {
        if latitude && longitude {
            return "\(latitude) \(longitude)"
        }
        return ""
    }

    //MARK: Init

    init(url: NSURL) {
        self.url = url;
        super.init()
        validImage = loadImageData()
        originalLatitude = latitude
        originalLongitude = longitude
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

    //MARK: Backup and Save

    // backup the image file by copying it to the trash
    // return true if successful
    func backupImageFile() -> Bool {
        var backupURL: NSURL?
        let fileManager = NSFileManager.defaultManager()
        //TODO: alert on error trashing item
        fileManager.trashItemAtURL(url, resultingItemURL: &backupURL,
                                   error: nil)
        if (backupURL) {
            //TODO: more error handling
            fileManager.copyItemAtURL(backupURL!, toURL: url, error: nil)
            return true
        }
        return false
    }

    // save the image if the location changed
    func saveImageFile() -> Bool {
        if validImage &&
           (latitude != originalLatitude || longitude != originalLongitude) {
            if !backupImageFile() {
                return false
            }
            // latitude exiftool args
            var latArg = "-GPSLatitude="
            var latRefArg = "-GPSLatitudeRef="
            if var lat = latitude {
                if lat < 0 {
                    latRefArg += "S"
                    lat = -lat
                } else {
                    latRefArg += "N"
                }
                latArg += "\(lat)"
            }
            // longitude exiftool args
            var lonArg = "-GPSLongitude="
            var lonRefArg = "-GPSLongitudeRef="
            if var lon = longitude {
                if lon < 0 {
                    lonRefArg += "W"
                    lon = -lon
                } else {
                    lonRefArg += "E"
                }
                lonArg += "\(lon)"
            }

            let exiftool = NSTask()
            exiftool.standardOutput = NSFileHandle.fileHandleWithNullDevice()
            exiftool.standardError = NSFileHandle.fileHandleWithNullDevice()
            exiftool.launchPath = AppDelegate.exiftoolPath
            exiftool.arguments = ["-q", "-m", "-overwrite_original",
                "-DateTimeOriginal>FileModifyDate", latArg, latRefArg,
                lonArg, lonRefArg, path]
            exiftool.launch()
            exiftool.waitUntilExit()
            originalLatitude = latitude
            originalLongitude = longitude
        }
        return true
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
