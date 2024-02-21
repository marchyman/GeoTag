//
//  LatLonSectionView.swift
//  GeoTag
//
//  Created by Marco S Hyman on 7/12/23.
//

import SwiftUI
import CoreLocation

struct LatLonSectionView: View {
    var image: ImageModel
    @Environment(AppState.self) var state
    @FocusState private var isFocused: Bool

    @State private var latitude: Double?
    @State private var longitude: Double?

    var body: some View {
        VStack {
            LabeledContent("Latitude:") {
                TextField("Latitude", value: $latitude, format: .latitude)
                    .frame(width: 200)
                    .labelsHidden()
                    .padding()
                    .focused($isFocused)
                    .focusedValue(\.textfieldBinding, $latitude)
            }

            LabeledContent("Longitude:") {
                TextField("Longitude", value: $longitude, format: .longitude)
                    .frame(width: 200)
                    .labelsHidden()
                    .padding()
                    .focused($isFocused)
                    .focusedValue(\.textfieldBinding, $longitude)
            }
        }
        .textFieldStyle(.roundedBorder)
        .onExitCommand {
            loadCoordinates()
            isFocused = false
        }
        .onSubmit {
            if validateLocation() {
                updateLocation()
                isFocused = false
            }
        }
        .onChange(of: image.location) {
            loadCoordinates()
        }
    }

    // set state variables from image location

    private func loadCoordinates() {
        if let location = image.location {
            latitude = location.latitude
            longitude = location.longitude
        } else {
            latitude = nil
            longitude = nil
        }
    }

    // check that latitude and longitude are non-nil and in appropriate range

    private func validateLocation() -> Bool {
        if let latitude,
           let longitude,
           (0...90).contains(latitude.magnitude),
           (0...180).contains(longitude.magnitude) {
            return true
        }
        return false
    }

    // update all selected images with the location specified by the
    // state variables.

    private func updateLocation() {
        // function won't be called if lat/lon are nil.
        // guard used to convert to non-optional values
        guard let latitude, let longitude else { return }
        let newLocation = Coords(latitude: latitude,
                                 longitude: longitude)

        state.undoManager.beginUndoGrouping()
        for image in state.tvm.selected where image.location != newLocation {
            state.update(image, location: newLocation)
        }
        state.undoManager.endUndoGrouping()
        state.undoManager.setActionName("modify location")
    }
}

#Preview {
    let image = ImageModel(imageURL: URL(fileURLWithPath: "/test/path/to/image1.jpg"),
                           validImage: true,
                           dateTimeCreated: "2022:12:12 11:22:33",
                           latitude: 33.123,
                           longitude: 123.456)
    return LatLonSectionView(image: image)
        .environment(AppState())
}
