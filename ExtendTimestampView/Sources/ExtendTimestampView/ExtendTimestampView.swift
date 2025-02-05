//

import SwiftUI

public struct ExtendTimestampView: View {
    @Binding var extendAmount: Double

    public init(extendAmount: Binding<Double>) {
        self._extendAmount = extendAmount
    }

    public var body: some View {
        VStack {
            Text("Track log timestamp extension")
                .font(.largeTitle)
                .padding(.top)

            Text(
                """
                When matching image timestamps to a track log GeoTag can
                include images taken before and after the duration of the log.
                Unless the value is changed below GeoTag includes images taken
                within two hours (120 minutes) of the start and end times of
                a track.
                """
                )
            .fixedSize(horizontal: false, vertical: true)
            .padding()

            Divider()

            HStack(alignment: .bottom) {
                Spacer()
                Button("Cancel") {
                    NSApplication.shared.keyWindow?.close()
                }
                .keyboardShortcut(.cancelAction)

                Button("Change") {
                    extendAmount = 60
//                    if currentZone != selectedZone {
//                        currentZone = selectedZone
//                        timeZone = selectedZone.timeZone
//                    }
                    NSApplication.shared.keyWindow?.close()
                }
                .keyboardShortcut(.defaultAction)
            }
            .padding()
        }
    }
}
