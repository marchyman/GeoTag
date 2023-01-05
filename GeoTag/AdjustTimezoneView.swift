//
//  AdjustTimezoneView.swift
//  GeoTag
//
//  Created by Marco S Hyman on 1/2/23.
//

import SwiftUI

struct AdjustTimezoneView: View {
    @EnvironmentObject var vm: ViewModel
    @State private var currentZone: TimeZoneName = .zero
    @State private var selectedZone: TimeZoneName = .zero

    var body: some View {
        VStack {
            Text("Specify Camera Time Zone")
                .font(.largeTitle)
            Text("""
                 When matching images to a GPS track log GeoTag assumes the
                 Time Zone of image timestamps to be the same as the
                 local-to-this-computer Time Zone. If the camera was set to
                 the local time in some other Time Zone or the Time Zone has
                 changed since you took the pictures select the appropriate
                 Time Zone here before matching image timestamps to a track
                 log.
                 """)
                .padding()

            Divider()

            Form {
                LabeledContent("Current Camera Time Zone:") {
                    VStack (alignment: .leading){
                        Text(currentZone.rawValue)
                        Text(currentZone.timeZone.identifier)
                    }
                }
                .padding(.bottom)

                LabeledContent("Desired Camera Time Zone:") {
                    VStack( alignment: .leading) {
                        Picker("Desired Camera Time Zone",
                               selection: $selectedZone) {
                            ForEach (TimeZoneName.allCases) { zone in
                                Text(zone.rawValue)

                            }
                        }
                        .labelsHidden()
                        .frame(width: 100)
                        Text(selectedZone.timeZone.identifier)
                    }
                }

            }
            .padding(30)

            Divider()

            HStack {
                Spacer()
                Button("Cancel") {
                    NSApplication.shared.keyWindow?.close()
                }
                .keyboardShortcut(.cancelAction)

                Button("Change") {
                    if currentZone != selectedZone {
                        vm.timeZone = selectedZone.timeZone
                    }
                    NSApplication.shared.keyWindow?.close()
                }
                .keyboardShortcut(.defaultAction)
            }
            .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .frame(width: 600.0, height: 500.0)
        .onAppear {
            currentZone = TimeZoneName.timeZoneCase(zone: vm.timeZone)
            selectedZone = currentZone
        }
    }
}

struct AdjustTimezoneView_Previews: PreviewProvider {
    static var previews: some View {
        AdjustTimezoneView()
            .environmentObject(ViewModel())
    }
}
