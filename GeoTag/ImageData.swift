//
//  ImageData.swift
//  GeoTag
//
//  Created by Marco S Hyman on 6/26/14.
//  Copyright (c) 2014 Marco S Hyman. All rights reserved.
//

import Cocoa


class ImageData: NSObject {
    /*
     * if we can't trash the file fall back to letting exiftool create
     * backup files.   Only display a warning that this will happen once
     * per program run.
     */
    static var firstWarning = true

    //MARK: instance variables

    let url: NSURL
    var path: String! {
        return url.path
    }
    var name: String? {
        return url.lastPathComponent
    }

    var date: String = ""
    var latitude: Double?, originalLatitude: Double?
    var longitude: Double?, originalLongitude: Double?
    var image: NSImage!
    var validImage = false

    var stringRepresentation: String {
        if latitude != nil && longitude != nil {
            return "\(latitude!) \(longitude!)"
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

    /*
     * Link given backup file name to an optional specified save directory
     * If the link fails (different filesystem?) fall back to a copy.
     * Note: paths are used instead of URLs because linkItemAtURL fails
     * trying to link foo.jpg_original to somedir/foo.jpg.
     */
    func saveOriginalFile(sourceName: String) {
        /*
         * If an optional save directory is specified link the file
         * to the named directory ignoring errors.  If a file with the same
         * file exists at the save location it will not be overwritten.
         * If the file can not be linked it will be copied.
         */
        if let saveDirURL = Preferences.saveDirectory() {
            var errorRet: NSError?
            let fileManager = NSFileManager.defaultManager()
            let saveFileURL =
                saveDirURL.URLByAppendingPathComponent(name!,
                                                       isDirectory: false)
            if !fileManager.fileExistsAtPath(saveFileURL.path!) {
                if !fileManager.linkItemAtPath(sourceName,
                                               toPath: saveFileURL.path!,
                                               error: &errorRet) {
                    // couldn't create hard link, copy file instead
                    if !fileManager.copyItemAtPath(sourceName,
                                                   toPath: saveFileURL.path!,
                                                   error: &errorRet) {
                        unexpectedError(errorRet,
                                        "Cannot copy \(sourceName) to \(saveFileURL.path)\n\nReason: ")
                    }
                }
            }
        }
    }

    /*
     * backup the image file by copying it to the trash.
     * return true if successful
     */
    func backupImageFile() -> Bool {
        var firstWarning = true
        var backupURL: NSURL?
        let fileManager = NSFileManager.defaultManager()
        var errorRet: NSError?
        if fileManager.trashItemAtURL(url, resultingItemURL: &backupURL,
                                      error: &errorRet) {
            saveOriginalFile(backupURL!.path!)
            if fileManager.copyItemAtURL(backupURL!, toURL: url,
                                         error: &errorRet) {
                return true
            }
            unexpectedError(errorRet,
                            "Cannot copy \(backupURL) to \(url) for update.\n\nReason: ")
        } else if let error = errorRet {
            if ImageData.firstWarning {
                ImageData.firstWarning = false
                let alert = NSAlert()
                alert.addButtonWithTitle(NSLocalizedString("CLOSE", comment: "Close"))
                alert.messageText = NSLocalizedString("NO_TRASH_TITLE",
                                                      comment: "can't trash file")
                alert.informativeText = path
                alert.informativeText! += NSLocalizedString("NO_TRASH_DESC",
                                                            comment: "can't trash file")
                if let reason = error.localizedFailureReason {
                    alert.informativeText! += reason
                } else {
                    alert.informativeText! += NSLocalizedString("NO_TRASH_REASON",
                                                                comment: "unknown error reason")
                }
                alert.runModal()
            }
        }
    return false
    }

    /*
     * save the image if the location changed
     */
    func saveImageFile() -> Bool {
        if validImage &&
           (latitude != originalLatitude || longitude != originalLongitude) {
            let overwriteOriginal = backupImageFile()
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
            exiftool.arguments = ["-q", "-m",
                "-DateTimeOriginal>FileModifyDate", latArg, latRefArg,
                lonArg, lonRefArg, path]

            // add -overwrite_original option if we can
            if overwriteOriginal {
                exiftool.arguments.insert("-overwrite_original", atIndex: 2)
            }
            exiftool.launch()
            exiftool.waitUntilExit()
            if !overwriteOriginal {
                saveOriginalFile(path + "_original")
            }
            originalLatitude = latitude
            originalLongitude = longitude
        }
        return true
    }


    //MARK: extract image metadata and build thumbnail preview

    func loadImageData() -> Bool {
        if let imgRef = CGImageSourceCreateWithURL(url, nil) {
            // CFString! to String! conversions (for Xcode 6.1 beta)
            let pixelHeight = kCGImagePropertyPixelHeight as String!
            let pixelWidth = kCGImagePropertyPixelWidth as String!
            let createThumbnailWithTransform = kCGImageSourceCreateThumbnailWithTransform as String!
            let createThumbnailFromImageAlways = kCGImageSourceCreateThumbnailFromImageAlways as String!
            let thumbnailMaxPixelSize = kCGImageSourceThumbnailMaxPixelSize as String!
            let exifDictionary = kCGImagePropertyExifDictionary as String!
            let exifDateTimeOriginal = kCGImagePropertyExifDateTimeOriginal as String!
            let GPSDictionary = kCGImagePropertyGPSDictionary as String!
            let GPSLatitude = kCGImagePropertyGPSLatitude as String!
            let GPSLatitudeRef = kCGImagePropertyGPSLatitudeRef as String!
            let GPSLongitude = kCGImagePropertyGPSLongitude as String!
            let GPSLongitudeRef = kCGImagePropertyGPSLongitudeRef as String!

            // grab the image properties
            let imgProps = CGImageSourceCopyPropertiesAtIndex(imgRef, 0, nil) as NSDictionary!
            if imgProps == nil {
                return false
            }
            let height = imgProps[pixelHeight] as! Int!
            let width = imgProps[pixelWidth] as! Int!
            if height == nil || width == nil {
                return false
            }

            /// Create a "preview" of the image. If the image is larger than
            /// 512x512 constrain the preview to that size.  512x512 is an
            /// arbitrary limit.   Preview generation is used to work around a
            /// performance hit when using large raw images
            let maxDimension = 512
            var imgOpts: NSMutableDictionary = [
                createThumbnailWithTransform : kCFBooleanTrue,
                createThumbnailFromImageAlways : kCFBooleanTrue
            ]
            if height > maxDimension || width > maxDimension {
                // add a max pixel size to the dictionary of options
                imgOpts[thumbnailMaxPixelSize] = maxDimension as AnyObject
            }
            if let imgPreview = CGImageSourceCreateThumbnailAtIndex(imgRef, 0, imgOpts) {
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
                        context = unsafeBitCast(currentContext.graphicsPort,
                                                CGContext.self)
                    }
                    if context != nil {
                        CGContextDrawImage(context, imgRect, imgPreview)
                    }
                }
                image.unlockFocus()

                // extract image date/time created
                if let exifData = imgProps[exifDictionary] as? NSDictionary,
                            dto = exifData[exifDateTimeOriginal] as? String {
                    date = dto
                }

                // extract image existing gps info
                if let gpsData = imgProps[GPSDictionary] as? NSDictionary {
                    if let lat = gpsData[GPSLatitude] as? Double,
                        latRef = gpsData[GPSLatitudeRef] as? String {
                        if latRef == "N" {
                            latitude = lat
                        } else {
                            latitude = -lat
                        }
                    }
                    if let lon = gpsData[GPSLongitude] as? Double,
                        lonRef = gpsData[GPSLongitudeRef] as? String {
                        if lonRef == "E" {
                            longitude = lon
                        } else {
                            longitude = -lon
                        }
                    }
                }

                return true
            }
        }
        return false
    }
}
