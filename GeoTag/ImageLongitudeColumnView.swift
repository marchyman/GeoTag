//
//  ImageLongitudeColumnView.swift
//  GeoTag
//
//  Created by Marco S Hyman on 12/17/22.
//

import SwiftUI
import CoreLocation

struct ImageLongitudeColumnView: View {
    let id: ImageModel.ID
    @State private var coordinate: Double?
    @EnvironmentObject var avm: AppViewModel

    var body: some View {
        TextField("", value: $coordinate, format: .longitude())
            .labelsHidden()
            .frame(maxWidth: 250)
            .help(avm[id].elevationAsString)
            .onSubmit {
                validateAndUpdate()
            }
            .onAppear {
                loadCoordinate()
            }
            .onChange(of: avm[id].location) { _ in
                loadCoordinate()
            }
    }

    private func loadCoordinate() {
        if let location = avm[id].location {
            coordinate = location.longitude
        } else {
            coordinate = nil
        }
    }

    // validate TextField input. Update if there are changes.

    private func validateAndUpdate() {
        var newLocation: CLLocationCoordinate2D?
        if let longitude = coordinate {
            if (0...180).contains(longitude.magnitude) {
                // longitude is in range.  Now see if it changed.
                if let location = avm[id].location {
                    newLocation = location
                } else {
                    newLocation = CLLocationCoordinate2D()
                }
                if newLocation?.longitude != longitude {
                    newLocation?.longitude = longitude
                    avm.update(id: id, location: newLocation)
                }
            } else {
                // I don't think this can happen
            }
        } else {
            // See if an existing entry was deleted.
            if avm[id].location != nil {
                avm.update(id: id, location: newLocation)
            }
        }
    }
}

// struct ImageLongitudeColumnView_Previews: PreviewProvider {
//    static var image =
//        ImageModel(imageURL: URL(fileURLWithPath: "/test/path/to/image1"),
//                   validImage: true,
//                   dateTimeCreated: "2022:12:12 11:22:33",
//                   latitude: 33.123,
//                   longitude: 123.456)
//
//    static var previews: some View {
//        ImageLongitudeColumnView(image: image)
//    }
// }
