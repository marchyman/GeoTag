//
//  ImageData.swift
//  GeoTag
//
//  Created by Marco S Hyman on 6/26/14.
//
// Copyright 2014-2018 Marco S Hyman
//
// Permission is hereby granted, free of charge, to any person obtaining a copy of
// this software and associated documentation files (the "Software"), to deal in the
// Software without restriction, including without limitation the rights to use,
// copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the
// Software, and to permit persons to whom the Software is furnished to do so,
// subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
// FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
// COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN
// AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
// WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

import Foundation
import AppKit
import MapKit

// A shorter name for a type I'll often use
typealias Coord = CLLocationCoordinate2D

// CFString to (NS)*String casts
let pixelHeight = kCGImagePropertyPixelHeight as NSString
let pixelWidth = kCGImagePropertyPixelWidth as NSString
let createThumbnailWithTransform = kCGImageSourceCreateThumbnailWithTransform as String
let createThumbnailFromImageAlways = kCGImageSourceCreateThumbnailFromImageAlways as String
let createThumbnailFromImageIfAbsent = kCGImageSourceCreateThumbnailFromImageIfAbsent as String
let thumbnailMaxPixelSize = kCGImageSourceThumbnailMaxPixelSize as String
let exifDictionary = kCGImagePropertyExifDictionary as NSString
let exifDateTimeOriginal = kCGImagePropertyExifDateTimeOriginal as String
let GPSDictionary = kCGImagePropertyGPSDictionary as NSString
let GPSStatus = kCGImagePropertyGPSStatus as String
let GPSLatitude = kCGImagePropertyGPSLatitude as String
let GPSLatitudeRef = kCGImagePropertyGPSLatitudeRef as String
let GPSLongitude = kCGImagePropertyGPSLongitude as String
let GPSLongitudeRef = kCGImagePropertyGPSLongitudeRef as String

final class ImageData: NSObject {
    /*
     * if we can't backup an image file display a warning that files will be
     * copied to an alternate directory.  This flag is used so the
     * warning is only displayed once per save operation
     */
    static var saveWarning = true

    // used to re-enable the save warning after a save operation has completed
    class
    func enableSaveWarnings(
    ) {
        saveWarning = true
    }

    // MARK: instance variables

    let url: URL                // URL of the image
    var name: String? {
        return url.lastPathComponent
    }
    var sandboxUrl: URL         // URL of the sandbox copy of the image

    // image date/time created
    var date: String = ""
    var timeZone: TimeZone?
    var dateFromEpoch: TimeInterval {
        let format = DateFormatter()
        format.dateFormat = "yyyy:MM:dd HH:mm:ss"
        format.timeZone = TimeZone.current
        if let convertedDate = format.date(from: date) {
            return convertedDate.timeIntervalSince1970
        }
        return 0
    }

    // image location
    var location: Coord?
    var originalLocation: Coord?

    var validImage = false  // does URL point to a valid image file?
    lazy var image: NSImage = self.loadImage()

    /// The string representation of the location of an image for copy and paste.
    /// The representation of no location is an empty string.
    var stringRepresentation: String {
        if let location = location {
            return "\(location.latitude) \(location.longitude)"
        } else {
            return ""
        }
    }

    // MARK: Init

    /// instantiate an instance of the class
    /// - Parameter url: image file this instance represents
    ///
    /// Extract geo location metadata and build a preview image for
    /// the given URL.  If the URL isn't recognized as an image mark this
    /// instance as not being valid.
    init(
        url: URL
    ) {
        // create a symlink for the URL in our sandbox
        self.url = url;
        let fileManager = FileManager.default
        do {
            let docDir = try fileManager.url(for: .documentDirectory,
                                             in: .userDomainMask,
                                             appropriateFor: nil,
                                             create: true)
            sandboxUrl = docDir.appendingPathComponent(url.lastPathComponent)
            /// if sandboxUrl already exists modify the name until it doesn't
            var fileNumber = 1
            while fileManager.fileExists(atPath: (sandboxUrl.path)) {
                var newName = url.lastPathComponent
                let nameDot = newName.index(of: ".") ?? newName.endIndex
                newName.insert(contentsOf: "-\(fileNumber)", at: nameDot)
                fileNumber += 1
                sandboxUrl = docDir.appendingPathComponent(newName)
            }
            try fileManager.createSymbolicLink(at: sandboxUrl,
                                               withDestinationURL: url)
        } catch let error as NSError {
            fatalError("docDir symlink error: \(error)")
        }
        super.init()
        validImage = loadImageData()
        originalLocation = location
    }

    /// remove the symbolic link created in the sandboxed document directory
    /// during instance initialization
    deinit
    {
        let fileManager = FileManager.default
        try? fileManager.removeItem(at: sandboxUrl)
    }

    // MARK: set/revert latitude and longitude for an image

    /// set the latitude and longitude of an image
    /// - Parameter location: the new coordinates
    ///
    /// The location may be set to nil to delete location information from
    /// an image.
    func setLocation(
        _ location: Coord?
    ) {
        self.location = location
        setTimeZoneFor(location)
    }

    /// restore latitude and longitude to their initial values
    ///
    /// Image location is restored to the value when location information
    /// was last saved. If the image has not been saved the restored values
    /// will be those in the image when first read.
    func revertLocation(
    ) {
        location = originalLocation
        setTimeZoneFor(location)
    }

    // MARK: Backup and Save

    /// copy the image into the backup folder
    ///
    /// If an image file with the same name exists in the backup folder append
    /// an available number to the image name to make the name unique to the
    /// folder.
    private
    func saveOriginalFile(
    ) -> Bool {
        guard let saveDirUrl = Preferences.saveFolder() else {
            if ImageData.saveWarning {
                ImageData.saveWarning = false

                let alert = NSAlert()
                alert.addButton(withTitle: NSLocalizedString("CLOSE", comment: "Close"))
                alert.messageText = NSLocalizedString("NO_BACKUP_TITLE",
                                                      comment: "can't backup file")
                alert.informativeText = url.path
                alert.informativeText += NSLocalizedString("NO_BACKUP_DESC",
                                                           comment: "can't backup file")
                alert.informativeText += NSLocalizedString("NO_BACKUP_REASON",
                                                           comment: "unknown error reason")
                alert.runModal()
            }
            return false
        }
        guard let name = name else { return false }
        var fileNumber = 1
        var saveFileUrl = saveDirUrl.appendingPathComponent(name, isDirectory: false)
        let fileManager = FileManager.default
        let _ = saveDirUrl.startAccessingSecurityScopedResource()
        defer { saveDirUrl.stopAccessingSecurityScopedResource() }
        // add a suffix to the name until no file is found at the save location
        while fileManager.fileExists(atPath: (saveFileUrl.path)) {
            var newName = name
            let nameDot = newName.index(of: ".") ?? newName.endIndex
            newName.insert(contentsOf: "-\(fileNumber)", at: nameDot)
            fileNumber += 1
            saveFileUrl = saveDirUrl.appendingPathComponent(newName, isDirectory: false)
        }
        // Copy the image file to the backup folder
        do {
            try fileManager.copyItem(at: url, to: saveFileUrl)
            /// DANGER WILL ROBINSON -- the above call can fail to return an
            /// error when the file is not copied.  radar filed and closed
            /// as a DUPLICATE OF 30350792 which was still open as of macOS
            /// 10.12.x.  As a result I must verify that the copied file exists
            if !fileManager.fileExists(atPath: (saveFileUrl.path)) {
                unexpected(error: nil,
                           "Cannot copy \(url.path) to \(saveFileUrl.path)")
                return false
            }
        } catch let error as NSError {
            unexpected(error: error,
                       "Cannot copy \(url.path) to \(saveFileUrl.path)\n\nReason: ")
            return false
        }
        return true
    }

    /// save image file if location has changed
    /// - Returns: false if a changed location could not be saved
    ///
    /// Invokes exiftool to update image metadata with the current
    /// latitude and longitude.  Non valid images and images that have not
    /// had their location changed do not invoke exiftool.
    ///
    /// No update will occur if a backup of the original file could not be
    /// created.
    ///
    /// exiftool is called with the symbolic link to the file in our
    /// sandbox.  This is needed as exiftool creates temporary files.
    /// The updated file is copied back to its original location after
    /// exiftool does its job.
    func saveImageFile(
    ) -> Bool {
        guard validImage &&
              (location?.latitude != originalLocation?.latitude ||
               location?.longitude != originalLocation?.longitude) else {
            return true     // nothing to update
        }
        if saveOriginalFile() &&
           Exiftool.helper.updateLocation(from: self) == 0 {
            originalLocation = location
            return true
        }

        // failed to backup or update
        return false
    }

    // Get the time zone for a given location
    private
    func setTimeZoneFor(
        _ location: Coord?
    ) {
        timeZone = nil
        if #available(OSX 10.11, *) {
            if let location = location {
                let coder = CLGeocoder();
                let loc = CLLocation(latitude: location.latitude,
                                     longitude: location.longitude)
                coder.reverseGeocodeLocation(loc) {
                    (placemarks, error) in
                    let place = placemarks?.last
                    self.timeZone = place?.timeZone
                }
            }
        }
    }

    // MARK: extract image metadata and build thumbnail preview

    /// obtain image metadata
    /// - Returns: true if successful
    ///
    /// If image propertied can not be accessed or if needed properties
    /// do not exist the file is assumed to be a non-image file
    private
    func loadImageData(
    ) -> Bool {
        guard let imgRef = CGImageSourceCreateWithURL(url as CFURL, nil) else {
            print("Failed CGImageSourceCreateWithURL \(url)")
            return false
        }

        // grab the image properties and extract height and width
        // if there are no image properties there is nothing to do.
        guard let imgProps = CGImageSourceCopyPropertiesAtIndex(imgRef, 0, nil) as NSDictionary? else {
            return false
        }

        // extract image date/time created
        if let exifData = imgProps[exifDictionary] as? [String: AnyObject],
           let dto = exifData[exifDateTimeOriginal] as? String {
            date = dto
        }

        // extract image existing gps info
        if let gpsData = imgProps[GPSDictionary] as? [String: AnyObject] {
            // some Leica write GPS tags with a status tag of "V" (void) when no
            // GPS info is available.   If a status tag exists and its value
            // is "V" ignore the GPS data.
            if let status = gpsData[GPSStatus] as? String {
                if status == "V" {
                    return true
                }
            }
            if let lat = gpsData[GPSLatitude] as? Double,
               let latRef = gpsData[GPSLatitudeRef] as? String,
               let lon = gpsData[GPSLongitude] as? Double,
               let lonRef = gpsData[GPSLongitudeRef] as? String {
                location = Coord(latitude: latRef == "N" ? lat : -lat,
                                longitude: lonRef == "E" ? lon : -lon)
            }
        }
        return true
    }

    /// Load an image thumbnail
    /// - Returns: NSImage of the thumbnail
    ///
    /// If image propertied can not be accessed or if needed properties
    /// do not exist the file is assumed to be a non-image file and a zero
    /// sized empty image is returned.
    private
    func loadImage(
    ) -> NSImage {
        var image = NSImage(size: NSMakeRect(0, 0, 0, 0).size)
        guard let imgRef = CGImageSourceCreateWithURL(url as CFURL, nil) else {
            return image
        }
        // Create a "preview" of the image. If the image is larger than
        // 512x512 constrain the preview to that size.  512x512 is an
        // arbitrary limit.   Preview generation is used to work around a
        // performance hit when using large raw images
        let maxDimension = 512
        var imgOpts: [String: AnyObject] = [
            createThumbnailWithTransform : kCFBooleanTrue,
            createThumbnailFromImageIfAbsent : kCFBooleanTrue,
            thumbnailMaxPixelSize : maxDimension as AnyObject
        ]
        var checkSize = true
        repeat {
            if let imgPreview = CGImageSourceCreateThumbnailAtIndex(imgRef, 0, imgOpts as NSDictionary) {
                // Create an NSImage from the preview
                let imgHeight = CGFloat(imgPreview.height)
                let imgWidth = CGFloat(imgPreview.width)
                if imgOpts[createThumbnailFromImageAlways] == nil &&
                    imgHeight < 512 && imgWidth < 512 {
                    // thumbnail too small.   Build a larger thumbnail
                    imgOpts[createThumbnailFromImageIfAbsent] = nil
                    imgOpts[createThumbnailFromImageAlways] = kCFBooleanTrue
                    continue
                }
                let imgRect = NSMakeRect(0.0, 0.0, imgWidth, imgHeight)
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
        return image
    }
}

/// Key-value names for tableview column sorting
extension ImageData {
    @objc var imageName: String {
        return name ?? ""
    }
    @objc var dateTime: Double {
        return dateFromEpoch
    }
    @objc var latitude: Double {
        return location?.latitude ?? 0
    }
    @objc var longitude: Double {
        return location?.longitude ?? 0
    }
}

