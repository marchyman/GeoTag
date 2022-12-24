//
//  ImageData.swift
//  GeoTag
//
//  Created by Marco S Hyman on 6/26/14.
//  Copyright 2014-2021 Marco S Hyman
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

/// CFString to (NS)*String casts for Image Property constants

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

/// class to manage Image date/time and location metadata

final class ImageData: NSObject {

    // MARK: instance variables -- file URLs

    let url: URL               // URL of the image
    let xmpUrl: URL            // URL of sidecar file (may not exist)
    let xmpFile: XmpFile	   // Sidecar file info (if it exists)
    var sandboxUrl: URL        // URL of the sandbox copy of the image
    var sandboxXmp: URL?       // URL of sandbox copy of sidecar file
    
    // MARK: failed backup and update flag
    
    var backupFailed = false    // could not backup image if true
    var updateFailed = false    // could not update image if true

    // MARK: instance variables -- date/time related values

    var dateTime = ""           // image date/time
    var originalDateTime = ""   // date/time before any modification
    var timeZone: TimeZone?     // timezone where image was taken

    // MARK: Date/Time format
    let dateFormatter = DateFormatter()

    // MARK: instance variables -- image location

    var location: Coord? {
        didSet {
            // update the timezone to match image location
            if let location = location {
                let coder = CLGeocoder();
                let loc = CLLocation(latitude: location.latitude,
                                     longitude: location.longitude)
                coder.reverseGeocodeLocation(loc) {
                    (placemarks, error) in
                    let place = placemarks?.last
                    self.timeZone = place?.timeZone
                }
            } else {
                timeZone = nil
            }
        }
    }
    var originalLocation: Coord?  // location before any modification

    // Elevation is available when processing track logs
    var elevation: Double?
    var originalElevation: Double?

    // MARK: instance variables -- image state and thumbnail

    var validImage = false        // does URL point to a valid image file?
    lazy var image = self.loadImage()

    // MARK: Init (FYI: not run on main thread)

    /// instantiate an instance of the class
    /// - Parameter url: image file this instance represents
    ///
    /// Extract geo location and date/time metadata from the given URL or a
    /// sidecar file if sidecar processing enabled and a sidecar file exists.
    /// If the URL isn't recognized as an image mark this instance as not valid.

    init(url: URL) throws {
        self.url = url;
        dateFormatter.dateFormat = "yyyy:MM:dd HH:mm:ss"

        // create a symlink for the URL in our sandbox

        let fileManager = FileManager.default
        do {
            let docDir = try fileManager.url(for: .documentDirectory,
                                             in: .userDomainMask,
                                             appropriateFor: nil,
                                             create: true)
            sandboxUrl = docDir.appendingPathComponent(url.lastPathComponent)

            // if sandboxUrl already exists modify the name until it doesn't

            var fileNumber = 1
            while fileManager.fileExists(atPath: (sandboxUrl.path)) {
                var newName = url.lastPathComponent
                let nameDot = newName.lastIndex(of: ".") ?? newName.endIndex
                newName.insert(contentsOf: "-\(fileNumber)", at: nameDot)
                fileNumber += 1
                sandboxUrl = docDir.appendingPathComponent(newName)
            }

            // fileExistsAtPath will return false when a symbolic link
            // exists but does not point to a valid file.  Handle that
            // situation to avoid a crash by deleting any stale link
            // that may be present before trying to create a new link.

            try? fileManager.removeItem(at: sandboxUrl)
            try fileManager.createSymbolicLink(at: sandboxUrl,
                                             withDestinationURL: url)

            // Create a link for any matching sidecare file, i.e. a file with
            // the same path components but with an extension of XMP, if one
            // is found.

            xmpUrl = url.deletingPathExtension().appendingPathExtension(xmpExtension)
            xmpFile = XmpFile(url: sandboxUrl)
            if url.pathExtension.lowercased() != xmpExtension &&
               Preferences.useSidecarFiles() {
                if fileManager.fileExists(atPath: xmpUrl.path) {
                    sandboxXmp = xmpFile.presentedItemURL
                    try? fileManager.removeItem(at: sandboxXmp!)
                    try fileManager.createSymbolicLink(at: sandboxXmp!,
                                                       withDestinationURL: xmpUrl)
                    NSFileCoordinator.addFilePresenter(xmpFile)
                }
            }
        }
        super.init()

        // If the image type is writable grab the needed metadata from
        // the image.  If there is an XMP file check it for metadata
        // overrides.
        if Exiftool.helper.fileTypeIsWritable(for: url) {
            validImage = loadImageData()
            if validImage,
               let xmp = sandboxXmp,
               fileManager.fileExists(atPath: xmpUrl.path) {
                loadXmpData(xmp)
            }
        }
    }

    /// remove the symbolic link created in the sandboxed document directory
    /// during instance initialization
    
    deinit
    {
        let fileManager = FileManager.default
        try? fileManager.removeItem(at: sandboxUrl)
        if let xmp = sandboxXmp {
            try? fileManager.removeItem(at: xmp)
        }
    }

    // MARK: revert changes to an image

    /// restore latitude, longitude, and date/time to their initial values
    ///
    /// Image location and time is restored to the value when location information
    /// was last saved. If the image has not been saved the restored values
    /// will be those in the image when first read.
    
    func revert() {
        location = originalLocation
        dateTime = originalDateTime
        elevation = originalElevation
    }

    // MARK: Backup and Save (functions do not run on main thread)

    /// copy the image into the backup folder
    ///
    /// If an image file with the same name exists in the backup folder append
    /// an available number to the image name to make the name unique to the
    /// folder.
    ///
    /// If a sidecar file is being used the sidecar file is backed up in place
    /// of the image file.

    private
    func saveOriginalFile() -> Bool {
        guard let saveDirUrl = Preferences.saveFolder() else { return false }
        
        // If a sidecar file exists use it istead of the image file
        let fileUrl = sandboxXmp == nil ? url : xmpUrl
        let name = fileUrl.lastPathComponent

        var fileNumber = 1
        var saveFileUrl = saveDirUrl.appendingPathComponent(name, isDirectory: false)
        let fileManager = FileManager.default
        let _ = saveDirUrl.startAccessingSecurityScopedResource()
        defer { saveDirUrl.stopAccessingSecurityScopedResource() }

        // add a suffix to the name until no file is found at the save location
        while fileManager.fileExists(atPath: (saveFileUrl.path)) {
            var newName = name
            let nameDot = newName.lastIndex(of: ".") ?? newName.endIndex
            newName.insert(contentsOf: "-\(fileNumber)", at: nameDot)
            fileNumber += 1
            saveFileUrl = saveDirUrl.appendingPathComponent(newName, isDirectory: false)
        }
        // Copy the image file to the backup folder
        do {
            
            try fileManager.copyItem(at: fileUrl, to: saveFileUrl)
            /// DANGER WILL ROBINSON -- the above call can fail to return an
            /// error when the file is not copied.  radar filed and closed
            /// as a DUPLICATE OF 30350792 which was still open as of macOS
            /// 10.12.x.  As a result I must verify that the copied file exists
            if !fileManager.fileExists(atPath: (saveFileUrl.path)) {
                // UI interaction must run on the main thread
                DispatchQueue.main.async {
                    unexpected(error: nil,
                               "Cannot copy \(fileUrl.path) to \(saveFileUrl.path)")
                }
                return false
            }
        } catch let error as NSError {
            // UI interaction must run on the main thread
            DispatchQueue.main.async {
                unexpected(error: error,
                           "Cannot copy \(fileUrl.path) to \(saveFileUrl.path)\n\nReason: ")
            }
            return false
        }
        return true
    }

    /// save image file if location or timestamp has changed
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
    /// - Returns:  0 if nothing to save or file saved
    ///             -1 if the file could not be backed up
    ///             non-zero exifcode return value
    
    func saveImageFile() -> Int32 {
        guard validImage &&
              (location?.latitude != originalLocation?.latitude ||
               location?.longitude != originalLocation?.longitude ||
               elevation != originalElevation ||
               dateTime != originalDateTime) else {
            return 0     // nothing to update
        }
        if Preferences.doNotBackup() || saveOriginalFile() {
            backupFailed = false
            let result = Exiftool.helper.updateLocation(from: self)
            if result == 0 {
                originalLocation = location
                originalDateTime = dateTime
                originalElevation = elevation
                updateFailed = false
            } else {
                updateFailed = true
            }
            return result
        }

        // failed to backup file

        backupFailed = true
        return -1
    }

    // MARK: extract image metadata and build thumbnail preview

    /// obtain metadata from XMP file
    /// - Parameter xmp: URL of XMP file for an image
    ///
    /// Extract desired metadata from an XMP file using ExifTool.  Apple
    /// ImageIO functions do not work with XMP sidecar files.
    
    private
    func loadXmpData(_ xmp: URL) {
        var errorCode: NSError?
        let coordinator = NSFileCoordinator(filePresenter: xmpFile)
        coordinator.coordinate(readingItemAt: xmp,
                               options: NSFileCoordinator.ReadingOptions.resolvesSymbolicLink,
                               error: &errorCode) {
            url in
            let results = Exiftool.helper.metadataFrom(xmp: url)
            if results.dto != "" {
                dateTime = results.dto
                originalDateTime = dateTime
            }
            if results.valid {
                location = results.location
                originalLocation = location
            }
        }
    }

    /// obtain image metadata
    /// - Returns: true if successful
    ///
    /// If image propertied can not be accessed or if needed properties
    /// do not exist the file is assumed to be a non-image file
    
    private
    func loadImageData() -> Bool {
        guard let imgRef = CGImageSourceCreateWithURL(url as CFURL, nil) else {
            unexpected(error: nil, "CGImageSourceCreateWithURL for \(url) failed")
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
            dateTime = dto
            originalDateTime = dateTime
        }

        // extract image existing gps info unless a location has already
        // been retrieved -- XMP files are processed first
        if location == nil,
           let gpsData = imgProps[GPSDictionary] as? [String: AnyObject] {
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
                originalLocation = location
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
    func loadImage() -> NSImage {
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

// MARK: date/time manipulation extensions

/// Image date/time format for ExifTool

extension ImageData {

    // image date/time as a Date
    // When this value is set the date string variable is also updated
    // timezone information is NOT used in this conversion

    var dateValue: Date? {
        get {
            dateFormatter.timeZone = nil
            return dateFormatter.date(from: dateTime)
        }
        set {
            if let value = newValue {
                dateFormatter.timeZone = nil
                dateTime = dateFormatter.string(from: value)
            } else {
                dateTime = ""
            }
        }
    }
    
    // returns image date/time as a Date
    // image timezone is used in the conversion

    var dateValueWithZone: Date? {
        dateFormatter.timeZone = timeZone
        return dateFormatter.date(from: dateTime)
    }

    // dateTime as a TimeInterval

    var dateFromEpoch: TimeInterval {
        if let convertedDate = dateValue {
            return convertedDate.timeIntervalSince1970
        }
        return 0
    }

    func intervalFromEpoch(with zone: TimeZone?) -> TimeInterval {
        dateFormatter.timeZone = zone
        if let convertedDate = dateFormatter.date(from: dateTime) {
            return convertedDate.timeIntervalSince1970
        }
        return 0
    }
}


// MARK: string representation extension

/// The string representation of the location of an image for copy and paste.
/// The representation of no location is an empty string.

extension ImageData {
    var stringRepresentation: String {
        if let location = location {
            return "\(location.latitude) | \(location.longitude)"
        } else {
            return ""
        }
    }
}

// MARK: Key-value names extension

extension ImageData {
    @objc var imageName: String {
        return url.lastPathComponent
    }
    @objc var dateTimeSort: Double {
        return dateFromEpoch
    }
    @objc var latitude: Double {
        return location?.latitude ?? 0
    }
    @objc var longitude: Double {
        return location?.longitude ?? 0
    }
}

// MARK: unit testing extension

/// indirect access to private methods needed only for unit testing.
extension ImageData {
    func testBackup() -> Bool {
        return saveOriginalFile()
    }
}
