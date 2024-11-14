//
//  ImageModelMetadata.swift
//  GeoTag
//
//  Created by Marco S Hyman on 4/14/24.
//

import Photos

// MARK: Grab image metadata

extension ImageModel {

    // extract metadata from Image file
    func loadImageMetadata() throws -> Bool {
        guard let imgRef = CGImageSourceCreateWithURL(fileURL as CFURL, nil)
        else {
            enum ImageError: Error {
                case cgSourceError
            }
            throw ImageError.cgSourceError
        }

        // grab the image properties and extract height and width
        // if there are no image properties there is nothing to do.

        guard
            let imgProps = CGImageSourceCopyPropertiesAtIndex(imgRef, 0, nil)
                as NSDictionary?
        else {
            return false
        }

        // extract image date/time created

        if let exifData = imgProps[ImageModel.exifDictionary]
            as? [String: AnyObject],
            let dto = exifData[ImageModel.exifDateTimeOriginal] as? String
        {
            dateTimeCreated = dto
            originalDateTimeCreated = dto
        }

        // extract image existing gps info unless a location has already
        // been retrieved

        if location == nil,
            let gpsData = imgProps[ImageModel.GPSDictionary]
                as? [String: AnyObject]
        {

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
                let lonRef = gpsData[ImageModel.GPSLongitudeRef] as? String
            {
                location = validCoords(
                    latitude: latRef == "N" ? lat : -lat,
                    longitude: lonRef == "E" ? lon : -lon)
                originalLocation = location
            }
            if let alt = gpsData[ImageModel.GPSAltitude] as? Double,
                let altRef = gpsData[ImageModel.GPSAltitudeRef] as? Int
            {
                elevation = altRef == 0 ? alt : -alt
                originalElevation = elevation
            }
        }
        return true
    }

    // Extract metadata from sidecar file.  For an unknown reason exiftool
    // can no longer read the xmp file for an image file unless explicitly
    // opened or in a folder that was explicitly opened.  Using the XMP
    // file presenter and NSFileCoordination do not help.
    //
    // (Temporary?) solution: make a copy of an exising XMP file inside the
    // sandbox and pass the copy to exiftool.  Every file in the sandbox
    // is placed in a unique folder: using "tmpfile.xmp" as the name does
    // does not collide.

    func loadXmpMetadata() {
        if let sandbox = try? Sandbox(self) {
            let tmpfileURL = sandbox.sidecarURL
                .deletingLastPathComponent()
                .appendingPathComponent("tmpfile.xmp")

            NSFileCoordinator.addFilePresenter(sandbox.xmpPresenter)
            defer {
                NSFileCoordinator.removeFilePresenter(sandbox.xmpPresenter)
            }

            if let data = sandbox.xmpPresenter.readData() {
                try? data.write(to: tmpfileURL)
            }
            let results = Exiftool.helper.metadataFrom(xmp: tmpfileURL)

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

    // extract metadata from a PHAsset obtained from the photo library
    func loadLibraryMetadata(asset: PHAsset?) {
        self.asset = asset
        if let asset {
            if let date = asset.creationDate {
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = Self.dateFormat
                dateTimeCreated = dateFormatter.string(from: date)
            } else {
                dateTimeCreated = ""
            }
            originalDateTimeCreated = dateTimeCreated

            location = asset.location?.coordinate
            originalLocation = location

            elevation = asset.location?.altitude
            originalElevation = elevation
        }
    }
}

// MARK: CFString to (NS)*String casts for Image Property constants

extension ImageModel {
    static let exifDictionary = kCGImagePropertyExifDictionary as String
    static let exifDateTimeOriginal =
        kCGImagePropertyExifDateTimeOriginal as String
    static let GPSDictionary = kCGImagePropertyGPSDictionary as String
    static let GPSStatus = kCGImagePropertyGPSStatus as String
    static let GPSLatitude = kCGImagePropertyGPSLatitude as String
    static let GPSLatitudeRef = kCGImagePropertyGPSLatitudeRef as String
    static let GPSLongitude = kCGImagePropertyGPSLongitude as String
    static let GPSLongitudeRef = kCGImagePropertyGPSLongitudeRef as String
    static let GPSAltitude = kCGImagePropertyGPSAltitude as String
    static let GPSAltitudeRef = kCGImagePropertyGPSAltitudeRef as String
}
