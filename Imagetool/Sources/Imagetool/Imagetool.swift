import Foundation
import Metadata

struct Imagetool {
    enum ImageError {
        case cgSourceError
        case noMetadataError
    }

    func metadata(from imageURL: URL) throws -> Metadata {
        var metadata = Metadata(source: .image(imageURL))

        // create an image reference for the given URL
        guard let imgRef = CGImageSourceCreateWithURL(fileURL as CFURL, nil)
        else {
            throw ImageError.cgSourceError
        }

        // grab image properties as an NSDictionary

        guard let imgProps =
            CGImageSourceCopyPropertiesAtIndex(imgRef, 0, nil)
                as NSDictionary?
        else {
            return false
        }
        if imgProps.count == 0 {
            throw ImageError.noMetadataError
        }

        // extract image date/time created

        if let exifData = imgProps[Imagetool.exifDictionary]
            as? [String: AnyObject],
            let dto = exifData[Imagetool.exifDateTimeOriginal] as? String {
            metadata.dateTimeCreated = dto
        }

        // extract image existing gps info unless a location has already
        // been retrieved

        if location == nil,
            let gpsData = imgProps[Imagetool.GPSDictionary]
            as? [String: AnyObject] {

            // some Leica camera write GPS tags with a status tag of "V" (void)
            // when no GPS info is available. If a status tag exists and its
            // value is "V" ignore the GPS data.

            if let status = gpsData[Imagetool.GPSStatus] as? String {
                if status == "V" {
                    return metadata
                }
            }
            if let lat = gpsData[Imagetool.GPSLatitude] as? Double,
               let latRef = gpsData[Imagetool.GPSLatitudeRef] as? String,
               let lon = gpsData[Imagetool.GPSLongitude] as? Double,
               let lonRef = gpsData[Imagetool.GPSLongitudeRef] as? String {
                metadata.location = Coords.ifValid(
                    latitude: latRef == "N" ? lat : -lat,
                    longitude: lonRef == "E" ? lon : -lon)
            }
            if let alt = gpsData[Imagetool.GPSAltitude] as? Double,
               let altRef = gpsData[Imagetool.GPSAltitudeRef] as? Int {
                metadata.elevation = altRef == 0 ? alt : -alt
            }

            // grab IPTC info for city/state/country/countryCode
            if let iptcInfo = imgProps[Imagetool.IPTCDictionary] as? [String: AnyObject] {
                metadata.city = iptcInfo[Imagetool.IPTCCity] as? String
                metadata.state = iptcInfo[Imagetool.IPTCState] as? String
                metadata.country = iptcInfo[Imagetool.IPTCCountry] as? String
                metadata.countryCode = iptcInfo[Imagetool.IPTCCountryCode] as? String
            }
        }
        return metadata
    }
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
