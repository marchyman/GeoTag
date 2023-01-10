//
//  ImageModel.swift
//  GeoTag
//
//  Created by Marco S Hyman on 12/13/22.
//

import Foundation
import MapKit

// Data about an image that may have its geo-location metadata changed.

struct ImageModel: Identifiable {

    // Identifying data.

    let fileURL: URL
    var id: URL {
        fileURL
    }

    // is this an image file or something else?

    var isValid = false

    // data shown to and adjusted by the user.

    var dateTimeCreated: String?
    var location: Coords?
    var elevation: Double?

    // when image data is modified the original data is kept to restore
    // should the user decide to change their mind

    var originalDateTimeCreated: String?
    var originalLocation: Coords?
    var originalElevation: Double?

    // true if image location, elevation, or timestamp have changed

    var changed: Bool {
        isValid && (dateTimeCreated != originalDateTimeCreated ||
                    location != originalLocation ||
                    elevation != originalElevation)
    }

    // Sandbox references to this image and any related sidecar file

    let sandboxURL: URL
    let sandboxXmpURL: URL?
    let xmpURL: URL
    let xmpFile: XmpFile

    // The thumbnail image displayed when and image is selected for editing
    // Thumbnail will not be created until it is needed.  Once created
    // it will be saved here.

    var thumbnail: NSImage?

    // initialization of image data given its URL.

    init(imageURL: URL, forPreview: Bool = false) throws {
        fileURL = imageURL
        if forPreview {
            // these fields are unused when creating instances for preview
            // any bogus value will work
            sandboxURL = imageURL
            xmpURL = imageURL
            xmpFile = XmpFile(url: imageURL)
            sandboxXmpURL = nil
            return
        }
        try sandboxURL = ImageModel.createSandboxUrl(fileURL: fileURL)
        xmpURL = fileURL.deletingPathExtension().appendingPathExtension(xmpExtension)
        xmpFile = XmpFile(url: sandboxURL)
        try sandboxXmpURL = ImageModel.createSandboxXmpURL(fileURL: fileURL,
                                                           xmpURL: xmpURL,
                                                           xmpFile: xmpFile)

        // verify this file type us writable with Exiftool and load image
        // metadata if we can.  If not mark it as not a valid image file.

        if Exiftool.helper.fileTypeIsWritable(for: fileURL) {
            do {
                isValid = try loadImageMetadata()
            } catch let error {
                isValid = false
                throw error
            }
            if isValid, let sandboxXmpURL,
               FileManager.default.fileExists(atPath: xmpURL.path) {
                loadXmpMetadata(sandboxXmpURL)
            }
        }
    }

    // remove the symbolic link created in the sandboxed document directory
    // during instance initialization

//    deinit
//    {
//        let fileManager = FileManager.default
//        try? fileManager.removeItem(at: sandboxURL)
//        if let sandboxXmpURL {
//            try? fileManager.removeItem(at: sandboxXmpURL)
//        }
//    }

    // reset the timestamp and location to their initial values.  Initial
    // values are updated whenever an image is saved.

    mutating func revert() {
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
    mutating func loadImageMetadata() throws -> Bool {
        guard let imgRef = CGImageSourceCreateWithURL(fileURL as CFURL, nil) else {
            enum ImageError: Error {
                case cgSourceError
            }
            throw ImageError.cgSourceError
        }

        // grab the image properties and extract height and width
        // if there are no image properties there is nothing to do.

        guard let imgProps = CGImageSourceCopyPropertiesAtIndex(imgRef, 0, nil) as NSDictionary? else {
            return false
        }

        // extract image date/time created

        if let exifData = imgProps[ImageModel.exifDictionary] as? [String: AnyObject],
           let dto = exifData[ImageModel.exifDateTimeOriginal] as? String {
            dateTimeCreated = dto
            originalDateTimeCreated = dto
        }

        // extract image existing gps info unless a location has already
        // been retrieved -- XMP files are processed first

        if location == nil,
           let gpsData = imgProps[ImageModel.GPSDictionary] as? [String: AnyObject] {

            // some Leica write GPS tags with a status tag of "V" (void) when no
            // GPS info is available.   If a status tag exists and its value
            // is "V" ignore the GPS data.

            if let status = gpsData[ImageModel.GPSStatus] as? String {
                if status == "V" {
                    return true
                }
            }
            if let lat = gpsData[ImageModel.GPSLatitude] as? Double,
               let latRef = gpsData[ImageModel.GPSLatitudeRef] as? String,
               let lon = gpsData[ImageModel.GPSLongitude] as? Double,
               let lonRef = gpsData[ImageModel.GPSLongitudeRef] as? String {
                location = Coords(latitude: latRef == "N" ? lat : -lat,
                                 longitude: lonRef == "E" ? lon : -lon)
                originalLocation = location
            }
            if let alt = gpsData[ImageModel.GPSAltitude] as? Double,
               let altRef = gpsData[ImageModel.GPSAltitudeRef] as? Int {
                elevation = altRef == 0 ? alt : -alt
                originalElevation = elevation
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
    mutating func loadXmpMetadata(_ xmp: URL) {
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
                elevation = results.elevation
                originalElevation = elevation
            }
        }
    }

}

// Add init functions for preview models and a just-in-case no-image model

extension ImageModel {
    // create a model for SwiftUI preview
    init(imageURL: URL,
         validImage: Bool,
         dateTimeCreated: String,
         latitude: Double?,
         longitude: Double?) {
        do {
            try self.init(imageURL: imageURL, forPreview: true)
        } catch {
            fatalError("ImageModel preview init failed")
        }
        self.isValid = validImage
        self.dateTimeCreated = dateTimeCreated
        if let latitude, let longitude {
            location = Coords(latitude: latitude, longitude: longitude)
        }
    }

    // create an instance of an ImageModel when one is needed but there
    // is otherwise no instance to return.
    init() {
        do {
            try self.init(imageURL: URL(filePath: ""), forPreview: true)
        } catch {
            fatalError("ImageModel no-image init failed")
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

// Date formatter used to put timestamps in the form used by exiftool

extension ImageModel {
    static let dateFormat = "yyyy:MM:dd HH:mm:ss"
}

// CFString to (NS)*String casts for Image Property constants

extension ImageModel {
    static let exifDictionary = kCGImagePropertyExifDictionary as NSString
    static let exifDateTimeOriginal = kCGImagePropertyExifDateTimeOriginal as String
    static let GPSDictionary = kCGImagePropertyGPSDictionary as NSString
    static let GPSStatus = kCGImagePropertyGPSStatus as String
    static let GPSLatitude = kCGImagePropertyGPSLatitude as String
    static let GPSLatitudeRef = kCGImagePropertyGPSLatitudeRef as String
    static let GPSLongitude = kCGImagePropertyGPSLongitude as String
    static let GPSLongitudeRef = kCGImagePropertyGPSLongitudeRef as String
    static let GPSAltitude = kCGImagePropertyGPSAltitude as String
    static let GPSAltitudeRef = kCGImagePropertyGPSAltitudeRef as String
}
