//
// Copyright 2022 Marco S Hyman
// See LICENSE file for info
// https://www.snafu.org/
//

import MapAndSearchViews
import SwiftUI

struct SettingsView: View {
    @Environment(AppState.self) var state

    // values stored in AppStorage
    @AppStorage(AppSettings.addTagsKey)
    var addTags = false
    @AppStorage(AppSettings.coordFormatKey)
    var coordFormat: AppSettings.CoordFormat = .deg
    @AppStorage(AppSettings.doNotBackupKey)
    var doNotBackup = false
    @AppStorage(AppSettings.createSidecarFilesKey)
    var createSidecarFiles = false
    @AppStorage(AppSettings.disablePairedJpegsKey)
    var disablePairedJpegs = false
    @AppStorage(AppSettings.extendedTimeKey)
    var extendedTime = 120.0
    @AppStorage(AppSettings.updateFileModificationTimesKey)
    var updateFileModificationTimes = false
    @AppStorage(AppSettings.updateGPSTimestampsKey)
    var updateGPSTimestamps = false
    @AppStorage(AppSettings.finderTagKey)
    var finderTag = "GeoTag"

    var body: some View {
        @Bindable var state = state
        VStack {
            Text("GeoTag Saved Settings")
                .font(.largeTitle)
                .padding()
            Form {
                Section("Backup File Location") {
                    if doNotBackup {
                        Text("Enabling image backups is strongly recommended")
                            .font(.footnote)
                            .padding(.horizontal)
                            .frame(width: 320)
                    } else {
                        PathView(url: $state.backupURL)
                            .frame(width: 320)
                            .padding(.horizontal)
                            .help(
                            """
                            Click on the disclosure indicator to choose a \
                            folder where GeoTag will place copies of images \
                            before performing any updates.
                            """)
                    }

                    Toggle("Disable image backups", isOn: $doNotBackup)
                        .padding([.bottom, .horizontal])
                        .help(
                        """
                        GeoTag will not place a copy of updated files in your \
                        selected backup folder if this box is checked. If \
                        there are issues while updates are in progress it \
                        is possible that image files could be corrupted. \
                        Allowing GeoTag to make a backup before updates \
                        occur is recommended.
                        """)
                }

                Section("Sidecar file support") {
                    // Create Sidecar (XMP) files
                    Toggle("Create Sidecar (XMP) files", isOn: $createSidecarFiles)
                        .padding()
                        .help(
                        """
                        Checking this box will result in creation of a sidecar \
                        (XMP) file for updated image files if one does not exist. \
                        Updates are then written to the sidecar file.
                        """)
                }

                // Coordinate display configuration
                Section("Coordinate format") {
                    Picker(
                        "Choose a coordinate format:",
                        selection: $coordFormat
                    ) {
                        Text("dd.dddddd")
                            .tag(AppSettings.CoordFormat.deg)
                        Text("dd° mm.mmmmmm'")
                            .tag(AppSettings.CoordFormat.degMin)
                        Text("dd° mm' ss.ss\"")
                            .tag(AppSettings.CoordFormat.degMinSec)
                    }
                    .pickerStyle(.radioGroup)
                    .labelsHidden()
                    .padding()
                    .help("Select a format for latitude and longitude display")
                }

                // Track log display configuration
                Section("Track Log Options") {
                    HStack {
                        ColorPicker(
                            "Track Color",
                            selection: $state.masData.trackColor
                        )
                        .labelsHidden()
                        .padding(.leading)
                        .help("Select the color used to display GPS tracks on the map.")

                        Text("Track color")
                    }

                    VStack(alignment: .leading){
                        HStack {
                            TextField(
                                "Track width",
                                value: $state.masData.trackWidth, format: .number
                            )
                            .frame(maxWidth: 48)
                            .padding(.leading)
                            .help(
                            """
                            Select the width of line used to display GPS \
                            tracks on the map. Use 0 for the system default width.
                            """)

                            Text("Track width")
                        }

                        HStack {
                            TextField(
                                "Extend track timestamps",
                                value: $extendedTime, format: .number
                            )
                            .frame(maxWidth: 48)
                            .padding(.leading)
                            .help(
                            """
                            When matching image timestamps to a GPS track log \
                            GeoTag will assign locations to images taken this \
                            many minutes before and after the log endpoints. \
                            The first or last location will be used as \
                            appropriate. Set this value to zero to disable \
                            assigning locations to images \
                            that are outside the range of the track log.
                            """)

                            Text("Extend timestamps")
                        }
                    }
                }

                Section("Miscellaneous") {
                    Toggle("Disable paired jpegs", isOn: $disablePairedJpegs)
                        .padding()
                        .help(
                        """
                        When this box is checked jpeg files that are part of a \
                        raw/jpeg pair can not not be updated.  The jpeg image \
                        name is displayed in the table using a gray color.
                        """)

                    // Image save option configuration
                    Toggle("Set File Modification Time",
                        isOn: $updateFileModificationTimes)
                        .padding([.bottom, .horizontal])
                        .help(
                        """
                        Checking this box will set file modification time to \
                        be the same as the image creation date/time whenever \
                        GeoTag updates image metadata with location changes. \
                        If the box is not checked file modification times \
                        will be controlled by the system.
                        """)

                    Toggle("Update GPS Date/Time",
                        isOn: $updateGPSTimestamps )
                        .padding([.bottom, .horizontal])
                        .help(
                        """
                        GeoTag can set/update the GPS time and date stamps \
                        when updating locations.  These timestamps are the \
                        same as the image create date and time but relative \
                        to GMP/UTC, not the local time.  When setting this \
                        option it is important that the TimeZone (edit menu) \
                        is correct for the images being saved.  Please see \
                        the GeoTag help pages for more information on setting \
                        the time zone.
                        """)

                    Toggle("Tag updated files", isOn: $addTags)
                        .padding(.horizontal)
                        .help(
                        """
                        If this option is enabled a finder tag will be added \
                        to updated images. The tag is alway added to the main \
                        image file even when a GPX sidecar file exists.
                        """)

                    if addTags {
                        HStack {
                            Text("with tag")
                                .padding(.leading, 38)
                            TextField("With tag:", text: $finderTag)
                                .frame(maxWidth: 200)
                                .padding(.horizontal)
                                .onSubmit {
                                    if finderTag.isEmpty {
                                        finderTag = "GeoTag"
                                    }
                                }
                                .help(
                                """
                                This tag will be added to files when Tag \
                                updated files is checked. If the tag is empty \
                                \"GeoTag\" will be used.
                                """)
                        }
                    }
                }
            }
            .formStyle(SettingsFormStyle())

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

#Preview {
    SettingsView()
        .environment(AppState())
}
