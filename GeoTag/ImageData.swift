//
//  ImageData.swift
//  GeoTag
//
//  Created by Marco S Hyman on 6/26/14.
//  Copyright (c) 2014, 2015 Marco S Hyman, CC-BY-NC
//

import Foundation
import AppKit

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
     * warning is only displayed once per execution of the program.
     */
    static var saveWarning = true

    class func enableSaveWarnings() {
        saveWarning = true
    }

    // MARK: instance variables

    let url: URL                // URL of the image
    var name: String? {
        return url.lastPathComponent
    }
    let sandboxUrl: URL         // URL of the sandbox copy of the image

    var date: String = ""
    var dateFromEpoch: TimeInterval {
        let format = DateFormatter()
        format.dateFormat = "yyyy:MM:dd HH:mm:ss"
        format.timeZone = TimeZone.current
        if let convertedDate = format.date(from: date) {
            return convertedDate.timeIntervalSince1970
        }
        return 0
    }

    var latitude: Double?, originalLatitude: Double?
    var longitude: Double?, originalLongitude: Double?
    var validImage = false
    lazy var image: NSImage = self.loadImage()

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
    init(url: URL) {
        // create a symlink for the URL in our sandbox
        self.url = url;
        let fileManager = FileManager.default
        do {
            let docDir = try fileManager.url(for: .documentDirectory,
                                             in: .userDomainMask,
                                             appropriateFor: nil,
                                             create: true)
            sandboxUrl = docDir.appendingPathComponent(url.lastPathComponent)
            try? fileManager.removeItem(at: sandboxUrl)
            try fileManager.createSymbolicLink(at: sandboxUrl,
                                               withDestinationURL: url)
        } catch let error as NSError {
            fatalError("docDir symlink error: \(error)")
        }
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
    func setLocation(latitude: Double?, longitude: Double?) {
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

    /// copy the image into the backup folder
    ///
    /// If an image file with the same name exists in the backup folder append
    /// an available number to the image name to make the name unique to the
    /// folder.
    private func saveOriginalFile() -> Bool {
        guard let saveDirUrl = Preferences.saveFolder() else {
            if ImageData.saveWarning {
                ImageData.saveWarning = false

                let alert = NSAlert()
                alert.addButton(withTitle: NSLocalizedString("CLOSE", comment: "Close"))
                alert.messageText = NSLocalizedString("NO_BACKUP_TITLE",
                                                      comment: "can't backup file")
                alert.informativeText = url.path
                alert.informativeText += NSLocalizedString("NO_BACKUP_DESC",
                                                           comment: "can't trash file")
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
        // add a suffix to the name until no file is found at the save location
        while fileManager.fileExists(atPath: (saveFileUrl.path)) {
            var newName = name
            let nameDot = newName.index(of: ".") ?? name.endIndex
            newName.insert(contentsOf: "-\(fileNumber)", at: nameDot)
            fileNumber += 1
            saveFileUrl = saveDirUrl.appendingPathComponent(newName, isDirectory: false)
        }
        // couldn't create hard link, copy file instead
        do {
            try fileManager.copyItem(at: url, to: saveFileUrl)
            /// DANGER WILL ROBINSON -- the above call can fail to return an
            /// error when the file is not copied.  radar filed and
            /// closed as a DUPLICATE OF 30350792 which is still open.
            /// As a result I must verify that the copied file exists
            if !fileManager.fileExists(atPath: (saveFileUrl.path)) {
                saveDirUrl.stopAccessingSecurityScopedResource()
                unexpected(error: nil,
                           "Cannot copy \(url.path) to \(saveFileUrl.path)")
                return false
            }
        } catch let error as NSError {
            saveDirUrl.stopAccessingSecurityScopedResource()
            unexpected(error: error,
                       "Cannot copy \(url.path) to \(saveFileUrl.path)\n\nReason: ")
            return false
        }
        saveDirUrl.stopAccessingSecurityScopedResource()
        return true
    }

    /// save image file if location has changed
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
    func saveImageFile() -> Bool {
        if validImage &&
           (latitude != originalLatitude || longitude != originalLongitude) {
            if saveOriginalFile() &&
               Exiftool.helper.updateLocation(from: self) == 0 {
                originalLatitude = latitude
                originalLongitude = longitude
                return true
            } else {
                // failed to backup or update
                return false
            }
        }
        // nothing to save
        return true
    }


    // MARK: extract image metadata and build thumbnail preview

    /// obtain image metadata
    /// - Returns: true if successful
    ///
    /// If image propertied can not be accessed or if needed properties
    /// do not exist the file is assumed to be a non-image file
    private func loadImageData() -> Bool {
        guard let imgRef = CGImageSourceCreateWithURL(url as CFURL, nil) else {
            print("Failed CGImageSourceCreateWithURL \(url)")
            return false
        }

        // grab the image properties and extract height and width
        // if there are no image properties there is nothing to do.
        guard let imgProps = CGImageSourceCopyPropertiesAtIndex(imgRef, 0, nil) as NSDictionary! else {
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
               let latRef = gpsData[GPSLatitudeRef] as? String {
                if latRef == "N" {
                    latitude = lat
                } else {
                    latitude = -lat
                }
            }
            if let lon = gpsData[GPSLongitude] as? Double,
               let lonRef = gpsData[GPSLongitudeRef] as? String {
                if lonRef == "E" {
                    longitude = lon
                } else {
                    longitude = -lon
                }
            }
        }
        return true
    }

    /// Load an image thumbnail
    /// - Returns: NSImage of the thumbnail if sucessful
    ///
    /// If image propertied can not be accessed or if needed properties
    /// do not exist the file is assumed to be a non-image file and a preview
    /// is not created.
    private func loadImage() -> NSImage {
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
