//
//  ModifyDateTimeView.swift
//  GeoTag
//
//  Created by Marco S Hyman on 1/2/23.
//

import SwiftUI

struct ModifyDateTimeView: View {
    @EnvironmentObject var vm: ViewModel

    var body: some View {
        VStack {
            Text("Modify Date/Time")
                .font(.largeTitle)
                .padding(.top)
            if let context = vm.menuContext {
                DateTimePickerView(id: context, allSelected: false)
            } else if let selected = vm.mostSelected {
                DateTimePickerView(id: selected, allSelected: true)
            }
        }
    }
}

struct DateTimePickerView: View {
    @EnvironmentObject var vm: ViewModel
    var id: ImageModel.ID
    var allSelected: Bool
    @State private var oldDate = Date()
    @State private var newDate = Date()

    var body: some View {
        VStack {
            Form {
                LabeledContent("Image Date/Time:") {
                    DatePicker("Image Date/Time", selection: $oldDate,
                               displayedComponents: .init(rawValue: 1234521450295224572))
                    .labelsHidden()
                    .frame(width: 200)
                    .disabled(true)
                }
                .padding([.horizontal, .bottom])
                .help("This is the date/time of the image file unless one was not present in which case the current date/time is shown.")

                LabeledContent("Updated Date/Time:") {
                    DatePicker("Updated Date/Time", selection: $newDate,
                               displayedComponents: .init(rawValue: 1234521450295224572))
                    .labelsHidden()
                    .frame(width: 200)
                                    }
                .padding([.horizontal, .bottom])
                .help("Set this to the new date/time. If one image is selected it will be set to this value.  If multiple images are selected the difference between the original date/time and the updated value will be applied to each image.")
            }

            Spacer()

            HStack(alignment: .bottom) {
                Spacer()
                Button("Cancel") {
                    NSApplication.shared.keyWindow?.close()
                }
                .keyboardShortcut(.cancelAction)

                Button("Change") {
                    if oldDate != newDate {
                        updateTimestamps()
                    }
                    NSApplication.shared.keyWindow?.close()
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
    func date() -> Date {
        if let date = vm[id].timestamp(for: vm.timeZone) {
            return date
        }
        return Date()
    }

    // update the dateTimeCreated value for all selected images
    func updateTimestamps() {
        // calclulate the adjustment to make to selected images
        let adjustment = newDate.timeIntervalSince1970 - oldDate.timeIntervalSince1970

        // prepare for date to string conversions.
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = ImageModel.dateFormat
        dateFormatter.timeZone = vm.timeZone

        let imagesToUpdate: Set<ImageModel.ID> = allSelected ? vm.selection : [id]

        // apply adjustment to each selected image in an undo group
        vm.undoManager.beginUndoGrouping()
        for id in imagesToUpdate {
            if vm[id].isValid {
                var updatedDate: Date
                if let originalDate = vm[id].timestamp(for: vm.timeZone) {
                    updatedDate = Date(timeInterval: adjustment,
                                           since: originalDate)
                } else {
                    updatedDate = newDate
                }
                vm.update(id: id, timestamp: dateFormatter.string(from: updatedDate))
            }
        }
        vm.undoManager.endUndoGrouping()
        vm.undoManager.setActionName("modify date/time")
    }

}

struct ModifyDateTimeView_Previews: PreviewProvider {
    static var previews: some View {
        ModifyDateTimeView()
            .environmentObject(ViewModel())
    }
}
