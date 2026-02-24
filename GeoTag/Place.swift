import MapKit
import OSLog
import SwiftUI

// TODO: combine this with FullAddress from LocationActor as they both
// hold roughly the same data

struct Place: Identifiable, Codable {
    var name: String
    var coordinate: Coordinate
    var id = UUID()

    init(from item: MKMapItem) {
        self.name = item.name ?? "unknown"
        if let locality = item.placemark.locality, locality != item.name {
            self.name += ", \(locality)"
        }
        if let area = item.placemark.administrativeArea, area != item.name {
            self.name += ", \(area)"
        }
        if let country = item.placemark.country, country != "United States" {
            self.name += ", \(country)"
        }
        self.coordinate = .init(item.location.coordinate)
    }

    private enum CodingKeys: String, CodingKey {
        case name
        case coordinate
    }
}

// Equatable and Hashable conformance

extension Place: Equatable, Hashable {
    public static func == (lhs: Place, rhs: Place) -> Bool {
        lhs.id == rhs.id
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(name)
        hasher.combine(coordinate.latitude)
        hasher.combine(coordinate.longitude)
    }
}

// a codable struct to hold the same data as a CLLocationCoordiante2D

struct Coordinate: Codable, Hashable {
    var latitude: Double
    var longitude: Double
    var coord2D: CLLocationCoordinate2D {
        .init(self)
    }
}

// conversions between Coordinate and CLLocationCoordinate2d

extension CLLocationCoordinate2D {
    init(_ coordinate: Coordinate) {
        self = .init(
            latitude: coordinate.latitude,
            longitude: coordinate.longitude)
    }
}

extension Coordinate {
    init(_ coordinate: CLLocationCoordinate2D) {
        self = .init(
            latitude: coordinate.latitude,
            longitude: coordinate.longitude)
    }
}

actor PlaceSaver {
    private var busy = false
    static let shared: PlaceSaver = .init()
    private init() {}

    // return the URL of "Places" in the app support folder

    private func appSupportURL() -> URL {
        let name = "Places"
        let placesURL = URL.applicationSupportDirectory.appendingPathComponent(name)
        return placesURL
    }

    // read places from a file in the application support folder

    func read() -> [Place] {
        let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "GeoTag",
                            category: "Read Places")

        let url = appSupportURL()
        if let places = try? Data(contentsOf: url) {
            do {
                let decoder = JSONDecoder()
                let decoded = try decoder.decode([Place].self,
                                                 from: places)
                return decoded
            } catch let DecodingError.dataCorrupted(context) {
                logger.error("corrupted \(context.debugDescription, privacy: .public)")
            } catch let DecodingError.keyNotFound(key, context) {
                logger.error(
                    """
                    Key '\(key.stringValue, privacy: .public)' not found: \
                    \(context.debugDescription, privacy: .public)
                    """)
            } catch let DecodingError.valueNotFound(value, context) {
                logger.error(
                    """
                    Value '\(value, privacy: .public)' not found: \
                    \(context.debugDescription, privacy: .public)
                    """)
            } catch let DecodingError.typeMismatch(type, context) {
                logger.error(
                    """
                    Type '\(type, privacy: .public)' mismatch: \
                    \(context.debugDescription, privacy: .public)
                    """)
            } catch {
                logger.error("\(error.localizedDescription, privacy: .public)")
            }
            fatalError("JSON Decoding Error for \(url)")
        }

        return []
    }

    // Encode and write places.  Only one save can be active at a
    // time. Calls to save while a save is in progress are ignored.

    func write(places: [Place]) throws {
        if !busy {
            busy = true
            let url = appSupportURL()
            let encoder = JSONEncoder()
            let encoded = try encoder.encode(places)
            try encoded.write(to: url)
            busy = false
        }
    }
}
