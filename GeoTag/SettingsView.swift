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
    @AppStorage(AppSettings.fileModificationTimeKey) var fileModTime = false
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

                LabeledContent("Preserve File Modification Times:") {
                    Toggle("Preserve File Modification Time", isOn: $fileModTime)
                        .labelsHidden()
                }
                .padding()
                .help("Checking this box will preserve file modification times when GeoTag updates image metadata with location changes.  If the box is not checked image files modification times will be set to the time the image was last updated.")

                ColorPicker("GPS Track Color:", selection: $trackColor)
                    .onChange(of: trackColor.rawValue) { color in
                        vm.refreshTracks = true
                    }
                    .padding(.horizontal)
                    .help("Select the color used to display GPS tracks on the map.")

                TextField("GPS Track width:", value: $trackWidth, format: .number)
                    .onSubmit { vm.refreshTracks = true }
                    .padding(.horizontal)
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
        .frame(minWidth: 500, minHeight: 500)
        .padding()
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
