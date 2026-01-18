//
// Copyright 2023 Marco S Hyman
// See LICENSE file for info
// https://www.snafu.org/
//

import CoreLocation
import SwiftUI

struct LatLonSectionView: View {
    var image: ImageModel
    @Environment(AppState.self) var state
    @FocusState private var isFocused: Bool

    @State private var latitude: Double?
    @State private var longitude: Double?

    @AppStorage(AppSettings.coordFormatKey)
    var coordFormat: AppSettings.CoordFormat = .deg

    // notice the bogus "focused" value given to .focusedValue. I need a non
    // empty string to enable cut/copy/paste/select all and this was an
    // easy way to do it with a side effect of the menu commands being
    // enabled even when the fields are empty.

    var body: some View {
        VStack {
            LabeledContent("Latitude:") {
                TextField("Latitude", value: $latitude, format: .latitude)
                    .frame(width: 200)
                    .labelsHidden()
                    .padding()
                    .focused($isFocused)
                    .focusedValue(\.textfieldFocused, "focused")
            }

            LabeledContent("Longitude:") {
                TextField("Longitude", value: $longitude, format: .longitude)
                    .frame(width: 200)
                    .labelsHidden()
                    .padding()
                    .focused($isFocused)
                    .focusedValue(\.textfieldFocused, "focused")
            }

            LabeledContent("City:") {
                Text(image.city ?? "?")
                    .frame(width: 200, alignment: .leading)
            }

            LabeledContent("State:") {
                Text(image.state ?? "?")
                    .frame(width: 200, alignment: .leading)
            }

            LabeledContent("Country:") {
                Text(image.country ?? "?")
                    .frame(width: 200, alignment: .leading)
            }

            LabeledContent("Country Code:") {
                Text(image.countryCode ?? "?")
                    .frame(width: 200, alignment: .leading)
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
        .onChange(of: coordFormat) {
            loadCoordinates()
        }
        .task(id: image.location) {
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
            (0 ... 90).contains(latitude.magnitude),
            (0 ... 180).contains(longitude.magnitude)
        {
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
        let newLocation = Coords(
            latitude: latitude,
            longitude: longitude)

        state.undoManager.beginUndoGrouping()
        for image in state.tvm.selected where image.location != newLocation {
            state.update(image, location: newLocation)
        }
        state.undoManager.endUndoGrouping()
        state.undoManager.setActionName("modify location")
    }
}

// I want my labels in line with the text field.

struct InlineLabeledContentStyle: LabeledContentStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.label
            configuration.content
        }
    }
}

extension LabeledContentStyle where Self == InlineLabeledContentStyle {
    static var inline: InlineLabeledContentStyle { InlineLabeledContentStyle() }
}

#Preview {
    let image = ImageModel(
        imageURL: URL(fileURLWithPath: "/test/path/to/image1.jpg"),
        validImage: true,
        dateTimeCreated: "2022:12:12 11:22:33",
        latitude: 33.123,
        longitude: 123.456)
    return Form {
        Section("Location") {
            LatLonSectionView(image: image)
        }
    }
    .environment(AppState())
    .frame(width: 500, height: 700)
}
