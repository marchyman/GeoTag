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
                LabeledContent("Disable Image Backups:") {
                    Toggle("Disable image backups", isOn: vm.$doNotBackup.animation())
                        .labelsHidden()
                }
                .help("GeoTag will not place a copy of updated files in your selected backup folder if this box is checked. If there are issues while updates are in progress it is possible that image files could be corrupted. Allowing GeoTag to make a backup before updates occur is recommended.")
                if vm.doNotBackup {
                    Text("Enabling image backups is strongly recommended")
                        .font(.footnote)
                        .padding(.bottom)
                } else {
                    LabeledContent("Backup folder:") {
                        PathView()
                            .frame(width: 280)
                            .padding(.bottom)
                            .onChange(of: vm.backupURL) { url in
                                if let url {
                                    vm.saveBookmark = vm.getBookmark(from: url)
                                    vm.checkSaveFolder(url)
                                }
                            }
                    }
                    .help("Click on the disclosure indicator to choose a folder where GeoTag will place copies of images before performing any updates.")
                }

                LabeledContent("Tag updated files:") {
                    Toggle("Tag updated files", isOn: vm.$addTag)
                        .labelsHidden()
                }
                .padding([.bottom, .horizontal] )
                .help("If this option is enabled the finder tag \"GeoTag\" will be added to updated images.")

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
                .padding([.bottom, .horizontal])
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
            .environmentObject(ViewModel())
    }
}
