//
//  DateTimeSectionView.swift
//  GeoTag
//
//  Created by Marco S Hyman on 7/12/23.
//

import SwiftUI

struct DateTimeSectionView: View {
    @Bindable var image: ImageModel
    @Environment(AppState.self) var state
    @FocusState private var isFocused: Bool

    @State private var oldDate = Date()
    @State private var newDate = Date()

    var body: some View {
        VStack {
            DatePicker(
                "Old Date/Time", selection: $oldDate,
                displayedComponents: .init(rawValue: 1_234_521_450_295_224_572)
            )
            .disabled(true)
            .padding([.horizontal, .bottom])

            DatePicker(
                "New Date/Time", selection: $newDate,
                displayedComponents: .init(rawValue: 1_234_521_450_295_224_572)
            )
            .accessibilityValue("newDatePicker")
            .focused($isFocused)
            .padding([.horizontal, .bottom])
            .help(
                """
                If one image is selected it is set to this value. \
                If multiple images are selected the difference between \
                the original date/time and the updated value is \
                applied to each image.
                """
            )
        }
        .onChange(of: newDate) {
            if oldDate != newDate {
                updateTimestamps()
                oldDate = newDate
            }
        }
        .task(id: image) {
            oldDate = date()
            newDate = oldDate
        }
    }

    private func date() -> Date {
        if let date = image.timestamp(for: state.timeZone) {
            return date
        }
        return Date()
    }

    private func updateTimestamps() {
        // calclulate the adjustment to make to selected images
        let adjustment = newDate.timeIntervalSince1970 - oldDate.timeIntervalSince1970

        // prepare for date to string conversions.
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = ImageModel.dateFormat
        dateFormatter.timeZone = state.timeZone

        // apply adjustment to each selected image in an undo group
        state.undoManager.beginUndoGrouping()
        for image in state.tvm.selected {
            var updatedDate: Date
            if let originalDate = image.timestamp(for: state.timeZone) {
                updatedDate = Date(
                    timeInterval: adjustment,
                    since: originalDate)
            } else {
                updatedDate = newDate
            }
            state.update(image, timestamp: dateFormatter.string(from: updatedDate))

        }
        state.undoManager.endUndoGrouping()
        state.undoManager.setActionName("modify date/time")
    }
}

#Preview {
    let image = ImageModel(
        imageURL: URL(fileURLWithPath: "/test/path/to/image1.jpg"),
        validImage: true,
        dateTimeCreated: "2022:12:12 11:22:33",
        latitude: 33.123,
        longitude: 123.456)
    return DateTimeSectionView(image: image)
        .environment(AppState())
}
