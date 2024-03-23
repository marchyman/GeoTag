//
//  SearchPlace.swift
//  SMap
//
//  Created by Marco S Hyman on 3/20/24.
//

import MapKit
import SwiftUI

// MARK: SearchPlace
// SearchPlace is an MKPlacemark less extraneous data, i.e. data not
// needed for this app. A SearchPlace is Codeable, Equatable, and Hashable

struct SearchPlace: Identifiable, Codable {
    var name: String
    var coordinate: Coordinate
    var id: String { return name }

    init(from item: MKMapItem) {
        self.name = item.name ?? "unknown"
        if let locality = item.placemark.locality,
           locality != item.name {
            self.name += ", \(locality)"
        }
        if let area = item.placemark.administrativeArea,
           area != item.name {
            self.name += ", \(area)"
        }
        if let country = item.placemark.country,
           country != "United States" {
            self.name += ", \(country)"
        }
        self.coordinate = .init(item.placemark.coordinate)
    }

    private enum CodingKeys: String, CodingKey {
        case name
        case coordinate
    }
}

extension SearchPlace: Equatable, Hashable {
    public static func == (lhs: SearchPlace, rhs: SearchPlace) -> Bool {
        lhs.id == rhs.id
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(name)
        hasher.combine(coordinate.latitude)
        hasher.combine(coordinate.longitude)
    }
}
