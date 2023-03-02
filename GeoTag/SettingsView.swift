//
//  SettingsView.swift
//  GeoTag
//
//  Created by Marco S Hyman on 12/17/22.
//

import SwiftUI

// swiftlint:disable line_length

struct SettingsView: View {
    @EnvironmentObject var avm: AppViewModel
    @ObservedObject var mvm = MapViewModel.shared
    @ObservedObject var itvm = ImageTableViewModel.shared

    // used when creating an ImageModel
    @AppStorage(AppSettings.createSidecarFileKey) var createSidecarFile = false

    // Only used in prepareForEdits
    @AppStorage(AppSettings.disablePairedJpegsKey) var disablePairedJpegs = false

    // Used in Exiftool
    @AppStorage(AppSettings.fileModificationTimeKey) var updateFileModTime = false
    @AppStorage(AppSettings.gpsTimestampKey) var updateGPSTimestamp = false

    @State private var backupURL: URL?

    init(backupURL: URL?) {
        _backupURL = State(initialValue: backupURL)
    }

    var body: some View {
        VStack {
            Text("GeoTag Saved Settings")
                .font(.largeTitle)
                .padding()
            Form {
                // Image backup configuration
                Group {
                    LabeledContent("Disable Image Backups:") {
                        Toggle("Disable image backups", isOn: $avm.doNotBackup)
                            .labelsHidden()
                    }
                    .help("GeoTag will not place a copy of updated files in your selected backup folder if this box is checked. If there are issues while updates are in progress it is possible that image files could be corrupted. Allowing GeoTag to make a backup before updates occur is recommended.")

                    if avm.doNotBackup {
                        Text("Enabling image backups is strongly recommended")
                            .font(.footnote)
                            .padding(.bottom)
                    } else {
                        LabeledContent("Backup folder:") {
                            PathView(url: $backupURL)
                                .frame(width: 280)
                                .padding(.bottom)
                                .onChange(of: backupURL) { url in
                                    avm.backupURL = url
                                }
                        }
                        .help("Click on the disclosure indicator to choose a folder where GeoTag will place copies of images before performing any updates.")
                    }
                }

                // Create Sidecar (XMP) files
                LabeledContent("Create Sidecar (XMP) files:") {
                    Toggle("Create Sidecar (XMP) files", isOn: $createSidecarFile)
                        .labelsHidden()
                }
                .padding([.bottom, .horizontal])
                .help("Checking this box will result in creation of a sidecar (XMP) file for updated image files if one does not exist.  Updates are then written to the sidecar file.")

                // Coordinate display configuration
                Picker("Choose a coordinate format:",
                       selection: $itvm.coordFormat) {
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

                // Track log display configuration
                Group {
                    ColorPicker("GPS Track Color:",
                                selection: $mvm.trackColor)
                        .onChange(of: mvm.trackColor.rawValue) { _ in
                            mvm.refreshTracks = true
                        }
                        .padding(.horizontal)
                        .help("Select the color used to display GPS tracks on the map.")

                    TextField("GPS Track width:",
                              value: $mvm.trackWidth, format: .number)
                        .onSubmit { mvm.refreshTracks = true }
                        .padding([.horizontal, .bottom])
                        .frame(maxWidth: 190)
                        .help("Select the width of line used to display GPS tracks on the map. Use 0 for the system default width.")
                }

                LabeledContent("Disable paired jpegs:") {
                    Toggle("Disable paired jpegs", isOn: $disablePairedJpegs)
                        .labelsHidden()
                }
                .padding([.bottom, .horizontal] )
                .help("When this box is checked jpeg files that are part of a raw/jpeg pair can not not be updated.  The jpeg image name is displayed in the table using a gray color.")

                // Image save option configuratio
                Group {
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

                    LabeledContent("Tag updated files:") {
                        Toggle("Tag updated files", isOn: $avm.addTag)
                            .labelsHidden()
                    }
                    .padding(.horizontal)
                    .help("If this option is enabled a finder tag will be added to updated images. The tag is alway added to the main image file even when a GPX sidecar file exists.")

                    if avm.addTag {
                        TextField("With tag:", text: $avm.tag)
                            .frame(maxWidth: 250)
                            .padding(.horizontal)
                            .onSubmit {
                                if avm.tag.isEmpty {
                                    avm.tag = "GeoTag"
                                }
                            }
                            .help("This tag will be added to files when Tag updated files is checked.  If the tag is empty \"GeoTag\" will be used.")
                    }
                }

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
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView(backupURL: nil)
            .environmentObject(AppViewModel())
    }
}
