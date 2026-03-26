import SwiftUI
import UDF

struct AdjustTimezoneView: View {
    @Environment(Store<GeoTagState, GeoTagEvent>.self) var store

    @State private var timeZone: TimeZone = TimeZone.current
    @State private var currentZone: TimeZoneName = .zero
    @State private var selectedZone: TimeZoneName = .zero

    var body: some View {
        VStack {
            Text("Specify Camera Time Zone")
                .font(.largeTitle)
                .padding(.top)

            Text("""
                When matching images to a GPS track log GeoTag assumes
                the time zone of image timestamps to be the same as the
                local-to-this-computer time zone. If the camera was set to
                the local time in some other time tone or the time zone has
                changed since you took the pictures select the appropriate
                value here before matching image timestamps to a track log.

                The time zone is also used to calculate the GPS Date/Time
                value when saving images (if enabled in GeoTag settings).
                GPS Date/Time is always saved using GMT/UTC. The time
                zone of the image timestamp is required to calculate the
                proper value.  When no Time Zone is specified the
                local-to-this-computer Time Zone is used.
                """)
            .fixedSize(horizontal: false, vertical: true)
            .padding()

            Divider()

            Form {
                LabeledContent("Current Camera Time Zone:") {
                    VStack(alignment: .leading) {
                        Text(currentZone.rawValue)
                        Text(currentZone.timeZone.identifier)
                    }
                }
                .padding(.bottom)

                LabeledContent("Desired Camera Time Zone:") {
                    VStack(alignment: .leading) {
                        Picker("Desired Camera Time Zone",
                               selection: $selectedZone) {
                            ForEach(TimeZoneName.allCases) { zone in
                                Text(zone.rawValue)
                            }
                        }
                        .labelsHidden()
                        .frame(width: 100)
                        .accessibilityIdentifier(TestIDs.AdjustTimeZoneView.cameraTimeZoneID)
                        Text(selectedZone.timeZone.identifier)
                    }
                }

            }
            .padding(30)

            Divider()

            HStack(alignment: .bottom) {
                Spacer()
                Button("Cancel") {
                    NSApplication.shared.keyWindow?.close()
                }
                .keyboardShortcut(.cancelAction)

                Button("Change") {
                    if currentZone != selectedZone {
                        currentZone = selectedZone
                        timeZone = selectedZone.timeZone
                        store.send(.timeZoneChanged(timeZone),
                                   description: "time zone change")
                    }
                    NSApplication.shared.keyWindow?.close()
                }
                .keyboardShortcut(.defaultAction)
            }
            .padding()
        }
        .onAppear {
            timeZone = store.timeZone
            currentZone = TimeZoneName.timeZoneCase(zone: timeZone)
            selectedZone = currentZone
        }
    }
}

#Preview(traits: .store) {
    AdjustTimezoneView()
        .frame(height: 570)
}
