import Coords
import Exiftool
import Foundation
import ImageIO
import Metadata
import OSLog

// image metadata input and output functions

public struct Imagetool {

    // read metadata from an image referenced by URL using ImageIO functions

    public static func metadata(from imageURL: URL) -> Metadata {
        var metadata = Metadata(source: .image(imageURL))

        // create an image reference for the given URL
        guard let imgRef = CGImageSourceCreateWithURL(imageURL as CFURL, nil)
        else {
            Self.logger.error(
                "\(#function): failed to create CGImageSource from URL \(imageURL.path)")
            return metadata
        }

        // grab image properties as an NSDictionary

        guard let imgProps =
            CGImageSourceCopyPropertiesAtIndex(imgRef, 0, nil)
                as NSDictionary?
        else {
            return metadata
        }
        if imgProps.count == 0 {
            Self.logger.error(
                "\(#function): failed to copy properties from URL \(imageURL.path)")
            return metadata
        }

        // extract image date/time created

        if let exifData = imgProps[Self.exifDictionary]
            as? [String: AnyObject],
            let dto = exifData[Self.exifDateTimeOriginal] as? String {
            metadata.dateTimeCreated = dto
        }

        // extract gps info when present

        if let gpsData = imgProps[Self.GPSDictionary]
            as? [String: AnyObject] {

            // some Leica camera write GPS tags with a status tag of "V" (void)
            // when no GPS info is available. If a status tag exists and its
            // value is "V" ignore the GPS data.

            if let status = gpsData[Self.GPSStatus] as? String {
                if status == "V" {
                    return metadata
                }
            }
            if let lat = gpsData[Self.GPSLatitude] as? Double,
               let latRef = gpsData[Self.GPSLatitudeRef] as? String,
               let lon = gpsData[Self.GPSLongitude] as? Double,
               let lonRef = gpsData[Self.GPSLongitudeRef] as? String {
                metadata.location = Coords.ifValid(
                    latitude: latRef == "N" ? lat : -lat,
                    longitude: lonRef == "E" ? lon : -lon)
            }
            if let alt = gpsData[Self.GPSAltitude] as? Double,
               let altRef = gpsData[Self.GPSAltitudeRef] as? Int {
                metadata.elevation = altRef == 0 ? alt : -alt
            }

            // grab IPTC info for city/state/country/countryCode
            if let iptcInfo = imgProps[Self.IPTCDictionary] as? [String: AnyObject] {
                metadata.city = iptcInfo[Self.IPTCCity] as? String
                metadata.state = iptcInfo[Self.IPTCState] as? String
                metadata.country = iptcInfo[Self.IPTCCountry] as? String
                metadata.countryCode = iptcInfo[Self.IPTCCountryCode] as? String
            }
        }
        return metadata
    }

    // Extract metadata from sidecar file.  Exiftool can not read the
    // xmp file for an image file unless explicitly opened or in a folder
    // that was explicitly opened even when Using the XMP file presenter
    // and NSFileCoordination.
    //
    // Therefore create a folder in the sandbox containing symbolic
    // links to the files elsewhere on disk. Point exiftool at the
    // sandbox link.
    //
    // The url in the returned metadata will reference the image,
    // not the xmp file.

    public static func metadata(from imageURL: URL, xmp: URL) -> Metadata {
        let metadata: Metadata

        if let sandbox = try? Sandbox(for: imageURL, sidecar: xmp) {
            NSFileCoordinator.addFilePresenter(sandbox.xmpPresenter)
            defer {
                NSFileCoordinator.removeFilePresenter(sandbox.xmpPresenter)
                sandbox.removeSandboxFolder()
            }
            metadata = Exiftool.helper.metadata(from: sandbox.xmpURL,
                                                primaryURL: imageURL)
        } else {
            Self.logger.error("\(#function): Can't create sandbox for \(imageURL.path, privacy: .public)")
            metadata = Metadata(source: .xmp(xmp))
        }

        return metadata
    }

}

// Define a logger for the package

extension Imagetool {
    static let id = Bundle.main.bundleIdentifier ?? "ImagetoolTest"
    static let logger = Logger(subsystem: id, category: "ImageTool")
}

// CFString to (NS)*String casts for Image Property constants

extension Imagetool {
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
    static let IPTCDictionary = kCGImagePropertyIPTCDictionary as String
    static let IPTCCity = kCGImagePropertyIPTCCity as String
    static let IPTCState = kCGImagePropertyIPTCProvinceState as String
    static let IPTCCountry = kCGImagePropertyIPTCCountryPrimaryLocationName as String
    static let IPTCCountryCode = kCGImagePropertyIPTCCountryPrimaryLocationCode as String
}
