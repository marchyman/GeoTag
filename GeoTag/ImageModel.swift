//
//  ImageModel.swift
//  GeoTag
//
//  Created by Marco S Hyman on 12/13/22.
//

import Foundation

struct ImageModel: Identifiable {
    var id = UUID()
    var fileURL: URL
    var dateTimeCreated: String
    var timeZone: TimeZone?
    var location: Coord
    var elevation: Double?
}

extension ImageModel {
    static var sample = ImageModel(
        fileURL: URL(fileURLWithPath: "/path/to/image/file/name"),
        dateTimeCreated: "2022:12:13 15:26:32",
        location: Coord(latitude: 37.7244, longitude: -122.4381))
}
