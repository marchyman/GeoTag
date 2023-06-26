//
//  ModifyDateTimeView.swift
//  GeoTag
//
//  Created by Marco S Hyman on 1/2/23.
//

import SwiftUI

struct ChangeDateTimeView: View {
    @Environment(\.dismiss) private var dismiss

    @EnvironmentObject var avm: AppViewModel
    let id: ImageModel.ID

    @State private var oldDate = Date()
    @State private var newDate = Date()

    var body: some View {
        VStack {
            Text("Change Date/Time")
                .font(.largeTitle)
                .padding()
            Form {
                LabeledContent("New Date/Time:") {
                    DatePicker("New Date/Time", selection: $newDate,
                               displayedComponents: .init(rawValue: 1234521450295224572))
                    .labelsHidden()
                    .frame(width: 200)
                                    }
                .padding([.horizontal, .bottom])
                .help("Set this to the new date/time. " +
                      "If one image is selected it will be set to this value. " +
                      "If multiple images are selected the difference between " +
                      "the original date/time and the updated value will be " +
                      "applied to each image.")
            }

            Spacer()

            HStack(alignment: .bottom) {
                Spacer()

                Button("Change") {
                    if oldDate != newDate {
                        updateTimestamps()
                    }
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
            }
            .padding()
        }
        .onAppear {
            oldDate = date()
            newDate = oldDate
        }
    }

    // return a data from an image DateTimeCreated.  If the field is nil
    // return the current date.

    private func date() -> Date {
        if let date = avm[id].timestamp(for: avm.timeZone) {
            return date
        }
        return Date()
    }

    // update the dateTimeCreated value for all selected images

    private func updateTimestamps() {
        // calclulate the adjustment to make to selected images
        let adjustment = newDate.timeIntervalSince1970 - oldDate.timeIntervalSince1970

        // prepare for date to string conversions.
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = ImageModel.dateFormat
        dateFormatter.timeZone = avm.timeZone

        // apply adjustment to each selected image in an undo group
        avm.undoManager.beginUndoGrouping()
        for id in avm.selection where avm[id].isValid {
            var updatedDate: Date
            if let originalDate = avm[id].timestamp(for: avm.timeZone) {
                updatedDate = Date(timeInterval: adjustment,
                                   since: originalDate)
            } else {
                updatedDate = newDate
            }
            avm.update(id: id, timestamp: dateFormatter.string(from: updatedDate))
        }
        avm.undoManager.endUndoGrouping()
        avm.undoManager.setActionName("modify date/time")
    }

}

struct ModifyDateTimeView_Previews: PreviewProvider {
    static var image =
        ImageModel(imageURL: URL(fileURLWithPath: "/test/path/to/image1"),
                   validImage: true,
                   dateTimeCreated: "2022:12:12 11:22:33",
                   latitude: 33.123,
                   longitude: 123.456)

    static var previews: some View {
        let avm = AppViewModel(images: [image])
        ChangeDateTimeView(id: image.id)
            .environmentObject(avm)
    }
}
