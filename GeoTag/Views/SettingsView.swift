import Coords
import SwiftUI
import UDF

struct SettingsView: View {
    @Environment(Store<GeoTagState, GeoTagEvent>.self) var store

    @AppStorage(GeoTagApp.doNotBackupKey) var doNotBackup = false
    @AppStorage(Self.createSidecarFilesKey) var createSidecarFiles = false
    @AppStorage(Coords.coordFormatKey) var coordFormat: CoordFormat = .deg
    @AppStorage(Self.trackWidthKey) var trackWidth = 0.0
    @AppStorage(Self.trackColorKey) var trackColor = Color.black
    @AppStorage(Self.extendedTimeKey) var extendedTime = 120.0
    @AppStorage(Self.disablePairedJpegsKey) var disablePairedJpegs = false
    @AppStorage(Self.updateFileModificationTimesKey) var updateFileModificationTimes = false
    @AppStorage(Self.updateGPSTimestampsKey) var updateGPSTimestamps = false
    @AppStorage(Self.addTagsKey) var addTags = false
    @AppStorage(Self.finderTagKey) var finderTag = "GeoTag"

    @State private var backupURL: URL?

    private let testIDs = TestIDs.SettingsView.self

    var body: some View {
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
                        PathView(url: $backupURL)
                            .frame(width: 320)
                            .padding(.horizontal)
                            .help("""
                            Click on the disclosure indicator to choose a \
                            folder where GeoTag will place copies of images \
                            before performing any updates.
                            """)
                    }

                    Toggle("Disable image backups", isOn: $doNotBackup)
                        .padding([.bottom, .horizontal])
                        .help("""
                        GeoTag will not place a copy of updated files in your \
                        selected backup folder if this box is checked. If \
                        there are issues while updates are in progress it \
                        is possible that image files could be corrupted. \
                        Allowing GeoTag to make a backup before updates \
                        occur is recommended.
                        """)
                }

                Section("Sidecar file support") {
                    Toggle("Create Sidecar (XMP) files", isOn: $createSidecarFiles)
                        .padding()
                        .help("""
                        Checking this box will result in creation of a sidecar \
                        (XMP) file for updated image files if one does not exist. \
                        Updates are then written to the sidecar file.
                        """)
                }

                Section("Coordinate format") {
                    Picker("Choose a coordinate format:",
                           selection: $coordFormat) {
                        Text("dd.dddddd")
                            .tag(CoordFormat.deg)
                        Text("dd° mm.mmmmmm'")
                            .tag(CoordFormat.degMin)
                        Text("dd° mm' ss.ss\"")
                            .tag(CoordFormat.degMinSec)
                    }
                    .pickerStyle(.radioGroup)
                    .labelsHidden()
                    .padding()
                    .help("""
                    Select a format for latitude and longitude display.
                    """)
                }

                Section("Track Log Options") {
                    HStack {
                        ColorPicker("Track Color",
                                    selection: $trackColor)
                            .labelsHidden()
                            .padding(.leading)
                            .help("""
                            Select the color used to display GPS tracks on \
                            the map.
                            """)

                        Text("Track color")
                    }

                    VStack(alignment: .leading){
                        HStack {
                            TextField("Track width",
                                      value: $trackWidth, format: .number)
                                .frame(maxWidth: 48)
                                .padding(.leading)
                                .help("""
                                Select the width of line used to display \
                                GPS tracks on the map. Use 0 for the \
                                system default width.
                                """)

                            Text("Track width")
                        }

                        HStack {
                            TextField("Extend track timestamps",
                                      value: $extendedTime, format: .number)
                                .frame(maxWidth: 48)
                                .padding(.leading)
                                .help("""
                                When matching image timestamps to a GPS track \
                                log GeoTag will assign locations to images \
                                taken this many minutes before and after the \
                                log endpoints. The first or last location \
                                will be used as appropriate.
                                """)

                            Text("Extend timestamps")
                        }
                    }
                }

                Section("Miscellaneous") {
                    Toggle("Disable paired jpegs", isOn: $disablePairedJpegs)
                        .padding()
                        .help("""
                        When this box is checked jpeg files that are part \
                        of a raw/jpeg pair can not not be updated. The \
                        jpeg image name is displayed in the table using \
                        a gray color.
                        """)

                    Toggle("Set File Modification Time",
                           isOn: $updateFileModificationTimes)
                        .padding([.bottom, .horizontal])
                        .help("""
                        Checking this box will set file modification time to \
                        be the same as the image creation date/time whenever \
                        GeoTag updates image metadata with location changes. \
                        If the box is not checked file modification times \
                        will be controlled by the system.
                        """)

                    Toggle("Update GPS Date/Time",
                           isOn: $updateGPSTimestamps)
                        .padding([.bottom, .horizontal])
                        .help(
                        """
                        GeoTag can set/update the GPS time and date stamps \
                        when updating locations. These timestamps are the \
                        same as the image create date and time but \
                        relative to GMP/UTC, not the local time. When \
                        setting this option it is important that the \
                        TimeZone (edit menu) is correct for the images \
                        being saved.  Please see the GeoTag help pages \
                        for more information on setting the time zone.
                        """)

                    Toggle("Tag updated files", isOn: $addTags)
                        .padding(.horizontal)
                        .help("""
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
                                .help("""
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
                .accessibilityIdentifier(testIDs.closeID)
                .keyboardShortcut(.defaultAction)
                .padding()
            }
            .padding(.bottom)
        }
        .onChange(of: backupURL) {
            if backupURL != store.backupURL {
                store.send(.backupURLChanged(backupURL))
            }
        }
        .task {
            backupURL = store.backupURL
        }
    }
}

// needed AppStorage keys

extension SettingsView {
    static let createSidecarFilesKey = "CreateSidecarFiles"
    static let trackWidthKey = "TrackWidth"
    static let trackColorKey = "TrackColor"
    static let extendedTimeKey = "ExtendedTime"
    static let disablePairedJpegsKey = "DisablePairedJpegs"
    static let updateFileModificationTimesKey = "UpdateFileModificationTimes"
    static let updateGPSTimestampsKey = "UpdateGPSTimestamps"
    static let addTagsKey = "AddTags"
    static let finderTagKey = "FinderTag"
}

// Clear all settings for UI testing

extension SettingsView {
    static func clearAllSettings() {
        @AppStorage(GeoTagApp.doNotBackupKey) var doNotBackup = false
        @AppStorage(GeoTagApp.savedBookmarkKey) var savedBookmark = Data()
        @AppStorage(Self.createSidecarFilesKey) var createSidecarFiles = false
        @AppStorage(Coords.coordFormatKey) var coordFormat: CoordFormat = .deg
        @AppStorage(Self.trackWidthKey) var trackWidth = 0.0
        @AppStorage(Self.trackColorKey) var trackColor = Color.black
        @AppStorage(Self.extendedTimeKey) var extendedTime = 120.0
        @AppStorage(Self.disablePairedJpegsKey) var disablePairedJpegs = false
        @AppStorage(Self.updateFileModificationTimesKey) var updateFileModificationTimes = false
        @AppStorage(Self.updateGPSTimestampsKey) var updateGPSTimestamps = false
        @AppStorage(Self.addTagsKey) var addTags = false
        @AppStorage(Self.finderTagKey) var finderTag = "GeoTag"

        doNotBackup = false
        savedBookmark = Data()
        createSidecarFiles = false
        coordFormat = .deg
        trackWidth = 0.0
        trackColor = Color.black
        extendedTime = 120.0
        disablePairedJpegs = false
        updateFileModificationTimes = false
        updateGPSTimestamps = false
        addTags = false
        finderTag = "GeoTag"
    }
}

// Allow color to be saved in AppDefaults

extension Color: @retroactive RawRepresentable {
    public init?(rawValue: String) {
        guard let data = Data(base64Encoded: rawValue) else {
            self = .black
            return
        }

        do {
            if let color =
                try NSKeyedUnarchiver.unarchivedObject(ofClass: NSColor.self,
                                                       from: data) {
                self = Color(color)
            } else {
                self = .black
            }
        } catch {
            self = .black
        }
    }

    public var rawValue: String {
        do {
            let data =
                try NSKeyedArchiver.archivedData(withRootObject: NSColor(self),
                                                 requiringSecureCoding: false) as Data
            return data.base64EncodedString()
        } catch {
            return ""
        }
    }
}

#Preview(traits: .store) {
    SettingsView()
        .frame(height: 650)
        .padding()
}
