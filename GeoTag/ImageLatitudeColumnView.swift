//
//  ImageLatitudeColumnView.swift
//  GeoTag
//
//  Created by Marco S Hyman on 12/17/22.
//

import SwiftUI
import CoreLocation

struct ImageLatitudeColumnView: View {
    let location: CLLocationCoordinate2D?
    let id: ImageModel.ID
    @State private var coordinate: Double?
    @EnvironmentObject var avm: AppViewModel

    var body: some View {
        TextField("", value: $coordinate, format: .latitude())
            .labelsHidden()
            .frame(maxWidth: 250)
//            .help(image.elevationAsString)
            .onSubmit {
                validateAndUpdate()
            }
            .onAppear {
                loadCoordinate()
            }
            .onChange(of: location) { _ in
                loadCoordinate()
            }
    }

    private func loadCoordinate() {
        if let location {
            coordinate = location.latitude
        } else {
            coordinate = nil
        }
    }

    // validate TextField input. Update if there are changes.

    private func validateAndUpdate() {
        var newLocation: CLLocationCoordinate2D?
        if let latitude = coordinate {
            if (0...90).contains(latitude.magnitude) {
                // latitude is in range.  Now see if it changed.
                if let location {
                    newLocation = location
                } else {
                    newLocation = CLLocationCoordinate2D()
                }
                if newLocation?.latitude != latitude {
                    newLocation?.latitude = latitude
                    avm.update(id: id, location: newLocation)
                }
            } else {
                // I don't think this can happen
            }
        } else {
            // See if an existing entry was deleted.
            if location != nil {
                avm.update(id: id, location: newLocation)
            }
        }
    }
}

//struct ImageLatitudeColumnView_Previews: PreviewProvider {
//    static var image =
//        ImageModel(imageURL: URL(fileURLWithPath: "/test/path/to/image1"),
//                   validImage: true,
//                   dateTimeCreated: "2022:12:12 11:22:33",
//                   latitude: 33.123,
//                   longitude: 123.456)
//
//    static var previews: some View {
//        ImageLatitudeColumnView(image: image)
//    }
//}
