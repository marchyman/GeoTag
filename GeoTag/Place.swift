import MapKit
import SwiftUI

struct Place: Identifiable, Codable {
    var name: String
    var city: String?
    var state: String?
    var country: String?
    var countryCode: String?
    var coordinate: Coordinate
    var id = UUID()

    init(from item: MKMapItem) {
        name = item.name ?? "unknown"
        let address = item.placemark
        if let city = address.locality {
            self.city = city
            if city != name {
                name += ", \(city)"
            }
        }
        if let state = address.administrativeArea {
            self.state = state
            if state != name {
                name += ", \(state)"
            }
        }
        if let country = address.country {
            self.country = country
            if country != "United States" {
                self.name += ", \(country)"
            }
        }
        self.countryCode = address.countryCode
        self.coordinate = .init(item.location.coordinate)
    }

    private enum CodingKeys: String, CodingKey {
        case name
        case city
        case state
        case country
        case countryCode
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

// Coordinates are equitable
extension Coordinate: Equatable {
    static func == (lhs: Coordinate, rhs: Coordinate) -> Bool {
        return lhs.latitude == rhs.latitude &&
               lhs.longitude == rhs.longitude
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
