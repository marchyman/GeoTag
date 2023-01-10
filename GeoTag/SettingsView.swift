//
//  SettingsView.swift
//  GeoTag
//
//  Created by Marco S Hyman on 12/17/22.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var vm: ViewModel

    @AppStorage(AppSettings.coordFormatKey) var coordFormat: AppSettings.CoordFormat = .deg
    @AppStorage(AppSettings.fileModificationTimeKey) var updateFileModTime = false
    @AppStorage(AppSettings.gpsTimestampKey) var updateGPSTimestamp = false
    @AppStorage(AppSettings.trackWidthKey) var trackWidth: Double = 0.0
    @AppStorage(AppSettings.trackColorKey) var trackColor: Color = .blue

    var body: some View {
        VStack {
            Text("GeoTag Saved Settings")
                .font(.largeTitle)
                .padding()
            Form {

                Picker("Choose a coordinate format:", selection: $coordFormat) {
                    Text("dd.dddddd")
                        .tag(AppSettings.CoordFormat.deg)
                    Text("dd mm.mmmmmm'")
                        .tag(AppSettings.CoordFormat.degMin)
                    Text("dd° mm' ss.ss\"")
                        .tag(AppSettings.CoordFormat.degMinSec)
                }
                .pickerStyle(.inline)
                .padding([.bottom, .horizontal] )
                .help("Select a format for latitude and longitude display")

                LabeledContent("Set File Modification Times:") {
                    Toggle("Set File Modification Time", isOn: $updateFileModTime)
                        .labelsHidden()
                }
                .padding([.bottom, .horizontal] )
                .help("Checking this box will set file modification time to be the same as the image creation date/time whenever GeoTag updates image metadata with location changes.  If the box is not checked file modification times will be controlled by the system.")

                LabeledContent("Update GPS Date/Time:") {
                    Toggle("Update GPS Date/Time", isOn: $updateGPSTimestamp)
                        .labelsHidden()
                }
                .padding([.bottom, .horizontal] )
                .help("GeoTag can set/update the GPS time and date stamps when updating locations.  These timestamps are the same as the image create date and time but relative to GMP/UTC, not the local time.  When setting this option it is important that the TimeZone (edit menu) is correct for the images being saved.  Please see the GeoTag help pages for more information on setting the time zone.")

                ColorPicker("GPS Track Color:", selection: $trackColor)
                    .onChange(of: trackColor.rawValue) { color in
                        vm.refreshTracks = true
                    }
                    .padding(.horizontal)
                    .help("Select the color used to display GPS tracks on the map.")

                TextField("GPS Track width:", value: $trackWidth, format: .number)
                    .onSubmit { vm.refreshTracks = true }
                    .padding(.horizontal)
                    .frame(maxWidth: 190)
                    .help("Select the width of line used to display GPS tracks on the map. Use 0 for the system default width.")

                Spacer()
                HStack {
                    Spacer()
                    Button("Close") {
                        NSApplication.shared.keyWindow?.close()
                    }
                    .keyboardShortcut(.defaultAction)
                }
                .padding()
            }
        }
        .padding()
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
