//
//  AdjustTimezoneView.swift
//  GeoTag
//
//  Created by Marco S Hyman on 1/2/23.
//

import SwiftUI

public struct AdjustTimezoneView: View {
    @Binding var timeZone: TimeZone?
    @State private var currentZone: TimeZoneName = .zero
    @State private var selectedZone: TimeZoneName = .zero

    public init(timeZone: Binding<TimeZone?>) {
        self._timeZone = timeZone
    }

    public var body: some View {
        VStack {
            Text("Specify Camera Time Zone")
                .font(.largeTitle)
                .padding(.top)

            Text(
                """
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
                """
            )
            .fixedSize(horizontal: false, vertical: true)
            .padding()

            Divider()

            Form {
                LabeledContent("Current Camera Time Zone:") {
                    VStack(alignment: .leading) {
                        Text(currentZone.rawValue)
                            .accessibilityIdentifier("currentTimeZone")
                        Text(currentZone.timeZone.identifier)
                    }
                }
                .padding(.bottom)

                LabeledContent("Desired Camera Time Zone:") {
                    VStack(alignment: .leading) {
                        Picker(
                            "Desired Camera Time Zone",
                            selection: $selectedZone
                        ) {
                            ForEach(TimeZoneName.allCases) { zone in
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
                    }
                    NSApplication.shared.keyWindow?.close()
                }
                .keyboardShortcut(.defaultAction)
            }
            .padding()
        }
        .onAppear {
            currentZone = TimeZoneName.timeZoneCase(zone: timeZone)
            selectedZone = currentZone
        }
    }
}

#Preview {
    @Previewable @State var timeZone: TimeZone?
    AdjustTimezoneView(timeZone: $timeZone)
        .frame(height: 570)
}
