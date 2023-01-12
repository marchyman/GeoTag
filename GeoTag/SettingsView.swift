//
//  SettingsView.swift
//  GeoTag
//
//  Created by Marco S Hyman on 12/17/22.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var vm: ViewModel
    @StateObject var appSettings = AppSettings()

    @AppStorage(AppSettings.doNotBackupKey) var doNotBackup = false
    @AppStorage(AppSettings.coordFormatKey) var coordFormat: AppSettings.CoordFormat = .deg
    @AppStorage(AppSettings.fileModificationTimeKey) var updateFileModTime = false
    @AppStorage(AppSettings.gpsTimestampKey) var updateGPSTimestamp = false
    @AppStorage(AppSettings.trackWidthKey) var trackWidth: Double = 0.0
    @AppStorage(AppSettings.trackColorKey) var trackColor: Color = .blue

    @State private var backupURL: URL?

    var body: some View {
        VStack {
            Text("GeoTag Saved Settings")
                .font(.largeTitle)
                .padding()
            Form {
                LabeledContent("Disable Image Backups:") {
                    Toggle("Disable image backups", isOn: $doNotBackup.animation())
                        .labelsHidden()
                }
                if doNotBackup {
                    Text("Enabling image backups is strongly recommended")
                        .font(.footnote)
                        .padding(.bottom)
                } else {
                    LabeledContent("Backup folder:") {
                        PathView(appSettings: appSettings)
                            .frame(width: 280)
                            .padding(.bottom)
                    }
                }

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
        .alert("Delete old backup files?",
               isPresented: $appSettings.removeOldFiles) { deleteOldFileView }
    }

    var deleteOldFileView: some View {
        VStack {
            Text("""
                 Your current backup/save folder

                     \(backupURL != nil ? backupURL!.path : "unknown")

                 is using \(appSettings.folderSize / 1_000_000) MB to store backup files.
                 \(appSettings.oldFiles.count) files using \(appSettings.deletedSize / 1_000_000) MB of storage were placed in the folder more than 7 days ago.

                 Shall images that have been in the folder more than 7 days be deleted?
                 """)

            Button("Delete", role: .destructive,
                   action: appSettings.deleteOldFiles)
            Button("Cancel", role: .cancel) {
                appSettings.removeOldFiles = false
            }
                .keyboardShortcut(.defaultAction)
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
            .environmentObject(ViewModel())
    }
}
