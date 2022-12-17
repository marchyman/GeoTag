//
//  ImageModel.swift
//  GeoTag
//
//  Created by Marco S Hyman on 12/13/22.
//

import Foundation
import MapKit

// CFString to (NS)*String casts for Image Property constants

let exifDictionary = kCGImagePropertyExifDictionary as NSString
let exifDateTimeOriginal = kCGImagePropertyExifDateTimeOriginal as String
let GPSDictionary = kCGImagePropertyGPSDictionary as NSString
let GPSStatus = kCGImagePropertyGPSStatus as String
let GPSLatitude = kCGImagePropertyGPSLatitude as String
let GPSLatitudeRef = kCGImagePropertyGPSLatitudeRef as String
let GPSLongitude = kCGImagePropertyGPSLongitude as String
let GPSLongitudeRef = kCGImagePropertyGPSLongitudeRef as String


// Date formatter used to put timestamps in the form used by exiftool

let dateFormatter = DateFormatter()
let dateFormat = "yyyy:MM:dd HH:mm:ss"

// Data about an image that may have its geo-location metadata changed.
// A class instead of a struct as instances of the class are intended
// to be mutated.

final class ImageModel: Identifiable {
    // Identifying data
    let id = UUID()
    let fileURL: URL

    // is this an image file or something else

    var validImage = false

    // data shown to and adjusted by the user.  The TimeZone is calculated
    // whenever image location is updated

    var dateTimeCreated: String?
    var timeZone: TimeZone?
    var location: Coord? {
        didSet {
            if let location {
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
    var elevation: Double?

    // when image data is modified the original data is kept to restore
    // should the user decide to change their mind

    var originalDateTimeCreated: String?
    var originalLocation: Coord?
    var originalElevation: Double?

    // Sandbox references to this image and any related sidecar file

    let sandboxURL: URL
    let sandboxXmpURL: URL?
    let xmpURL: URL
    let xmpFile: XmpFile

    init(imageURL: URL) throws {
        fileURL = imageURL
        try sandboxURL = createSandboxUrl(fileURL: fileURL)
        xmpURL = fileURL.deletingPathExtension().appendingPathExtension(xmpExtension)
        xmpFile = XmpFile(url: sandboxURL)
        try sandboxXmpURL = createSandboxXmpURL(fileURL: fileURL,
                                                xmpURL: xmpURL,
                                                xmpFile: xmpFile)

        // verify this file type us writable with Exiftool and load image
        // metadata if we can

        if Exiftool.helper.fileTypeIsWritable(for: fileURL) {
            validImage = loadImageMetadata()
            if validImage, let sandboxXmpURL,
               FileManager.default.fileExists(atPath: xmpURL.path) {
                loadXmpMetadata(sandboxXmpURL)
            }
        }
    }

    // remove the symbolic link created in the sandboxed document directory
    // during instance initialization

    deinit
    {
        let fileManager = FileManager.default
        try? fileManager.removeItem(at: sandboxURL)
        if let sandboxXmpURL {
            try? fileManager.removeItem(at: sandboxXmpURL)
        }
    }

    // reset the timestamp and location to their initial values.  Initial
    // values are updated whenever an image is saved.

    func revert() {
        dateTimeCreated = originalDateTimeCreated
        location = originalLocation
        elevation = originalElevation
    }

    /// obtain image metadata
    /// - Returns: true if successful
    ///
    /// If image propertied can not be accessed or if needed properties
    /// do not exist the file is assumed to be a non-image file

    private
    func loadImageMetadata() -> Bool {
        guard let imgRef = CGImageSourceCreateWithURL(fileURL as CFURL, nil) else {
            unexpected(error: nil, "CGImageSourceCreateWithURL for \(fileURL) failed")
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
            dateTimeCreated = dto
            originalDateTimeCreated = dto
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

    /// obtain metadata from XMP file
    /// - Parameter xmp: URL of XMP file for an image
    ///
    /// Extract desired metadata from an XMP file using ExifTool.  Apple
    /// ImageIO functions do not work with XMP sidecar files.

    private
    func loadXmpMetadata(_ xmp: URL) {
        var errorCode: NSError?
        let coordinator = NSFileCoordinator(filePresenter: xmpFile)
        coordinator.coordinate(readingItemAt: xmp,
                               options: NSFileCoordinator.ReadingOptions.resolvesSymbolicLink,
                               error: &errorCode) { url in
            let results = Exiftool.helper.metadataFrom(xmp: url)
            if results.dto != "" {
                dateTimeCreated = results.dto
                originalDateTimeCreated = results.dto
            }
            if results.valid {
                location = results.location
                originalLocation = location
            }
        }
    }

}

// ImageModel instances are compared and hashed on id

extension ImageModel: Equatable, Hashable {
    static func == (lhs: ImageModel, rhs: ImageModel) -> Bool {
        return lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}


// Stand alone helper functions used when initializing an ImageModel
// instance. They can't be member functions as they are called before the
// instance is fully initialized.  They need not be member functions as
// they don't access ImageModel data.

// Link the given fileURL to the app sandbox, create a unique name if necessary

func createSandboxUrl(fileURL: URL) throws -> URL {
    var sandboxURL: URL

    let fileManager = FileManager.default
    let docDir = try fileManager.url(for: .documentDirectory,
                                     in: .userDomainMask,
                                     appropriateFor: nil,
                                     create: true)
    sandboxURL = docDir.appendingPathComponent(fileURL.lastPathComponent)

    // if sandboxURL already exists modify the name until it doesn't

    var fileNumber = 1
    while fileManager.fileExists(atPath: (sandboxURL.path)) {
        var newName = fileURL.lastPathComponent
        let nameDot = newName.lastIndex(of: ".") ?? newName.endIndex
        newName.insert(contentsOf: "-\(fileNumber)", at: nameDot)
        fileNumber += 1
        sandboxURL = docDir.appendingPathComponent(newName)
    }

    // fileExistsAtPath will return false when a symbolic link
    // exists but does not point to a valid file.  Handle that
    // situation to avoid a crash by deleting any stale link
    // that may be present before trying to create a new link.

    try? fileManager.removeItem(at: sandboxURL)
    try fileManager.createSymbolicLink(at: sandboxURL,
                                       withDestinationURL: fileURL)
    return sandboxURL
}

// Link an XMP file matching the image file, if one was found, into the sandbox.
// Add a file presenter to allow us to write to the XMP file even if only the
// image file was opened.

func createSandboxXmpURL(fileURL: URL,
                         xmpURL: URL,
                         xmpFile: XmpFile) throws -> URL? {
    var sandboxXmpURL: URL?

    // should check preferences here, too
    if fileURL.pathExtension.lowercased() != xmpExtension {
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: xmpURL.path) {
            sandboxXmpURL = xmpFile.presentedItemURL
            try? fileManager.removeItem(at: sandboxXmpURL!)
            try fileManager.createSymbolicLink(at: sandboxXmpURL!,
                                               withDestinationURL: xmpURL)
            NSFileCoordinator.addFilePresenter(xmpFile)
        }
    }
    return sandboxXmpURL
}
