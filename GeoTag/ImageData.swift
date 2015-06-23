//
//  ImageData.swift
//  GeoTag
//
//  Created by Marco S Hyman on 6/26/14.
//  Copyright (c) 2014, 2015 Marco S Hyman, CC-BY-NC
//

import Foundation
import AppKit

final class ImageData: NSObject {
    /*
     * if we can't trash the file fall back to letting exiftool create
     * backup files.   Only display a warning that this will happen once
     * per program run.
     */
    static var firstWarning = true

    // MARK: instance variables

    let url: NSURL
    var path: String! {
        return url.path
    }
    var name: String? {
        return url.lastPathComponent
    }

    var date: String = ""
    var dateFromEpoch: NSTimeInterval {
        let format = NSDateFormatter()
        format.dateFormat = "yyyy:MM:dd HH:mm:ss"
        format.timeZone = NSTimeZone.localTimeZone()
        if let convertedDate = format.dateFromString(date) {
            return convertedDate.timeIntervalSince1970
        }
        return 0
    }

    var latitude: Double?, originalLatitude: Double?
    var longitude: Double?, originalLongitude: Double?
    var image: NSImage!
    var validImage = false

    // return the string representation of the location of an image for copy
    // and paste.
    var stringRepresentation: String {
        if latitude != nil && longitude != nil {
            return "\(latitude!) \(longitude!)"
        }
        return ""
    }

    // MARK: Init

    /// instantiate an instance of the class
    /// - Parameter url: image file this instance represents
    ///
    /// Extract geo location metadata and build a preview image for
    /// the given URL.  If the URL isn't recognized as an image mark this
    /// instance as not being valid.
    init(url: NSURL) {
        self.url = url;
        super.init()
        validImage = loadImageData()
        originalLatitude = latitude
        originalLongitude = longitude
    }

    // MARK: set/revert latitude and longitude for an image

    /// set the latitude and longitude of an image
    /// - Parameter latitude: the new latitude
    /// - Parameter longitude: the new longitude
    ///
    /// The location may be set to nil to delete location information from
    /// an image.
    func setLatitude(latitude: Double?, longitude: Double?) {
        self.latitude = latitude
        self.longitude = longitude
    }

    /// restore latitude and longitude to their initial values
    ///
    /// Image location is restored to the value when location information
    /// was last saved. If the image has not been saved the restored values
    /// will be those in the image when first read.
    func revertLocation() {
        latitude = originalLatitude
        longitude = originalLongitude
    }

    // MARK: Backup and Save

    /// link or copy a file into a save directory
    /// Parameter sourceName: path to image file to be copied or linked
    ///
    /// Link the named file into an optional save directory.  If the link fails
    /// (different filesystem?) copy the file instead.  If a file with the
    /// same name exists in the save directory it is **not** overwritten.
    ///
    /// Note: paths are used instead of URLs because linkItemAtURL fails
    /// trying to link foo.jpg_original to somedir/foo.jpg.
    private func saveOriginalFile(sourceName: String) {
        guard let saveDirURL = Preferences.saveFolder() else { return }
        let fileManager = NSFileManager.defaultManager()
        let saveFileURL = saveDirURL.URLByAppendingPathComponent(name!, isDirectory: false)
        if !fileManager.fileExistsAtPath(saveFileURL.path!) {
            do {
                try fileManager.linkItemAtPath(sourceName, toPath: saveFileURL.path!)
            } catch {
                // couldn't create hard link, copy file instead
                do {
                    try fileManager.copyItemAtPath(sourceName,
                                                   toPath: saveFileURL.path!)
                } catch let error as NSError {
                    unexpectedError(error,
                                    "Cannot copy \(sourceName) to \(saveFileURL.path)\n\nReason: ")
                }
            }
        }
    }

    /// backup the image file by copying it to the trash.
    /// - Returns: true if the backup was succcesful
    ///
    /// The first time backup to the trash fails an alert is shown to the user
    /// letting them know an alternate backup method is being used.
    private func backupImageFile() -> Bool {
        var backupURL: NSURL?
        let fileManager = NSFileManager.defaultManager()
        do {
            try fileManager.trashItemAtURL(url, resultingItemURL: &backupURL)
            saveOriginalFile(backupURL!.path!)
            do {
                try fileManager.copyItemAtURL(backupURL!, toURL: url)
                return true
            } catch let error as NSError {
                unexpectedError(error,
                                "Cannot copy \(backupURL) to \(url) for update.\n\nReason: ")
            }
        } catch let error as NSError {
            // couldn't trash file, warn user of alternate backup location
            if ImageData.firstWarning {
                ImageData.firstWarning = false
                let alert = NSAlert()
                alert.addButtonWithTitle(NSLocalizedString("CLOSE", comment: "Close"))
                alert.messageText = NSLocalizedString("NO_TRASH_TITLE",
                                                      comment: "can't trash file")
                alert.informativeText = path
                alert.informativeText += NSLocalizedString("NO_TRASH_DESC",
                                                           comment: "can't trash file")
                if let reason = error.localizedFailureReason {
                    alert.informativeText += reason
                } else {
                    alert.informativeText += NSLocalizedString("NO_TRASH_REASON",
                                                               comment: "unknown error reason")
                }
                alert.runModal()
            }
        }
        return false
    }

    /// save image file if location has changed
    ///
    /// Invokes exiftool to update image metadata with the current
    /// latitude and longitude.  Non valid images and images that have not
    /// had their location changed do not invoke exiftool.
    ///
    /// The updated file will overwrite the original file if a backup file
    /// was created.  If a backup could not be created exiftool will rename
    /// the original file.
    func saveImageFile() {
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

            // add -overwrite_original option to the exiftool args if we were
            // able to create a backup.
            if overwriteOriginal {
                exiftool.arguments?.insert("-overwrite_original", atIndex: 2)
            }
            exiftool.launch()
            exiftool.waitUntilExit()

            // if a backup could not be created prior to running exiftool
            // copy the exiftool created original to the save directory.
            if !overwriteOriginal {
                saveOriginalFile(path + "_original")
            }
            originalLatitude = latitude
            originalLongitude = longitude
        }
    }


    // MARK: extract image metadata and build thumbnail preview

    /// obtain image metadata and build thumbnail
    /// - Returns: true if successful
    ///
    /// If image propertied can not be accessed or if needed properties
    /// do not exist the file is assumed to be a non-image file and a preview
    /// is not created.
    private func loadImageData() -> Bool {
        guard let imgRef = CGImageSourceCreateWithURL(url, nil) else {
            return false
        }

        // CFString to String conversions
        let pixelHeight = kCGImagePropertyPixelHeight as String
        let pixelWidth = kCGImagePropertyPixelWidth as String
        let createThumbnailWithTransform = kCGImageSourceCreateThumbnailWithTransform as String
        let createThumbnailFromImageAlways = kCGImageSourceCreateThumbnailFromImageAlways as String
        let thumbnailMaxPixelSize = kCGImageSourceThumbnailMaxPixelSize as String
        let exifDictionary = kCGImagePropertyExifDictionary as String
        let exifDateTimeOriginal = kCGImagePropertyExifDateTimeOriginal as String
        let GPSDictionary = kCGImagePropertyGPSDictionary as String
        let GPSLatitude = kCGImagePropertyGPSLatitude as String
        let GPSLatitudeRef = kCGImagePropertyGPSLatitudeRef as String
        let GPSLongitude = kCGImagePropertyGPSLongitude as String
        let GPSLongitudeRef = kCGImagePropertyGPSLongitudeRef as String

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

        // Create a "preview" of the image. If the image is larger than
        // 512x512 constrain the preview to that size.  512x512 is an
        // arbitrary limit.   Preview generation is used to work around a
        // performance hit when using large raw images
        let maxDimension = 512
        let imgOpts: NSMutableDictionary = [
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
            image.lockFocus()
            if let currentContext = NSGraphicsContext.currentContext() {
                var context: CGContext! = nil
                // 10.9 doesn't have CGContext
                if #available(OSX 10.10, *) {
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
        }

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
