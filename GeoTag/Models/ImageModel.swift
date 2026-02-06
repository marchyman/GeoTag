// import MapAndSearchViews
import Coords
import Exiftool
// import MapKit
import OSLog
import PhotosUI
import SwiftUI

// Data about an image that may have its geo-location metadata changed.
// Images may be loaded from disk or selected from the users photo library.
// Image handling is different depending upon the source

struct ImageModel: Identifiable, Sendable {
    let fileURL: URL                // Image identifies by its URL
    var id: URL {                   // Can be the ID as no dups allowed
        fileURL
    }

    let name: String                // Image name is set at init
    var dateTimeCreated: String?    // Timestamp of the image when present.
    var timeStamp: String {
        dateTimeCreated ?? ""
    }

    var location: Coords?           // Lat and Lon
    var formattedLatitude: String {
        location?.formatted(.latitude) ?? ""
    }
    var formattedLongitude: String {
        location?.formatted(.longitude) ?? ""
    }

    var elevation: Double?          // elevation if present
    var formattedElevation: String {
        var value = "Elevation: "
        if let elevation {
            value += String(format: "% 4.2f", elevation)
            value += " meters"
        } else {
            value += "Unknown"
        }
        return value
    }

    var city: String?                   // IPTC Image location
    var state: String?
    var country: String?
    var countryCode: String?

    var pickerItem: PhotosPickerItem?   // Photos picker item
    var asset: PHAsset?

    // URL of related sidecar file (if one exists) and an NSFilePresenter
    // to access the sidecar/XMP file
    let sidecarURL: URL
    var sidecarExists: Bool

    // Optional ID of a paired file.  Used when both raw and jpeg versions
    // of a raw/jpeg pair are opened.
    var pairedID: URL?

    // is this an image file or something else?
    // no metadata is set when image properties can not be read or
    // do not exist.
    var isValid = false
    var noMetadata = false

    // when image data is modified the original data is kept to restore
    // should the user decide to change their mind
    var originalDateTimeCreated: String?
    var originalLocation: Coords?
    var originalElevation: Double?
    var originalCity: String?
    var originalState: String?
    var originalCountry: String?
    var originalCountryCode: String?

    // true if image location, elevation, or timestamp have changed
    var changed: Bool {
        isValid
            && (dateTimeCreated != originalDateTimeCreated
                || location != originalLocation
                || elevation != originalElevation)
    }

    // The thumbnail image displayed when and image is selected for editing
    var thumbnail: Image?

    // MARK: Initialization

    // initialization of image data given its URL.
    init(imageURL: URL, forPreview: Bool = false) throws {
        // Self.logger.trace("image \(imageURL) created")
        fileURL = imageURL
        sidecarURL = fileURL.deletingPathExtension()
            .appendingPathExtension(xmpExtension)
        let hasSidecar =
            fileURL != sidecarURL
            && FileManager.default.fileExists(atPath: sidecarURL.path)
        sidecarExists = hasSidecar
        // xmpPresenter = XmpPresenter(for: fileURL)
        name = imageURL.lastPathComponent + (hasSidecar ? "*" : "")

        // shortcut initialization when creating an image for preview
        // or if the file type is not writable by Exiftool
        guard !forPreview && Exiftool.helper.fileTypeIsWritable(for: fileURL)
        else {
            return
        }

        // Load image metadata. If not an image file note that the image
        // is inValid.  If the image is valid but there is no metadata or the
        // metadata can't be read note that, too.
        do {
            isValid = try loadImageMetadata()
        } catch ImageError.noMetadataError {
            isValid = true
            noMetadata = true
        }

        // If a sidecar file exists read metadata from it as sidecar files
        // take precidence.
        // if isValid && sidecarExists {
        //     loadXmpMetadata()
        // }
    }

    // initialization of image data from images stored in the Photos Library.
    init(libraryEntry: PhotoLibrary.LibraryEntry) {
        // synthesize a URL from the entries item.itemIdentifier
        fileURL = libraryEntry.url
        sidecarURL = fileURL.appendingPathExtension(xmpExtension)
        sidecarExists = false
        // xmpPresenter = XmpPresenter(for: fileURL)
        pickerItem = libraryEntry.item
        if let asset = libraryEntry.asset {
            isValid = true
            let assetResources = PHAssetResource.assetResources(for: asset)
            name = assetResources.first?.originalFilename ?? "unknown"
            let logName = name
            Self.logger.info("Photo Lib Image: \(logName, privacy: .public)")
            loadLibraryMetadata(asset: libraryEntry.asset)
        } else {
            isValid = false
            if let id = libraryEntry.item.itemIdentifier {
                name = String(id.prefix(13))
            } else {
                name = "unknown"
            }
            asset = nil
        }
    }
}

// MARK: ImageModel public functions

extension ImageModel {

    // reset the timestamp and location to their initial values.  Initial
    // values are updated whenever an image is saved.
    mutating func revert() {
        dateTimeCreated = originalDateTimeCreated
        location = originalLocation
        elevation = originalElevation
        city = originalCity
        state = originalState
        country = originalCountry
        countryCode = originalCountryCode
    }

    // an invalid location read from metadata (corrupted file) will crash
    // the program. Validate coords and return valid data or nil
    func validCoords(latitude: Double, longitude: Double) -> Coords? {
        var coords: Coords?

        if (0 ... 90).contains(latitude.magnitude)
            && (0 ... 180).contains(longitude.magnitude)
        {
            coords = Coords(latitude: latitude, longitude: longitude)
        }
        return coords
    }

}

extension ImageModel {

    // create a model for SwiftUI preview
    init(
        imageURL: URL,
        validImage: Bool,
        dateTimeCreated: String,
        latitude: Double?,
        longitude: Double?
    ) {
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

extension ImageModel {
    private static let logger =
        Logger(subsystem: Bundle.main.bundleIdentifier ?? "GeoTag",
               category: "ImageModel")
}

// MARK: ImageModel instances are compared and hashed on id

extension ImageModel: Equatable, Hashable {
    public static func == (lhs: ImageModel, rhs: ImageModel) -> Bool {
        return lhs.id == rhs.id
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// URLs in this program can be compared

extension URL: @retroactive Comparable {
    public static func < (lhs: URL, rhs: URL) -> Bool {
        lhs.path < rhs.path
    }
}

// ImageModel conforms to Locatable

// extension ImageModel: Locatable {}
