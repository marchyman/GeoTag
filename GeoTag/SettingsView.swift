//
//  SettingsView.swift
//  GeoTag
//
//  Created by Marco S Hyman on 12/17/22.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var vm: AppState

    @AppStorage(AppSettings.coordFormatKey) var coordFormat: AppSettings.CoordFormat = .deg
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

                ColorPicker("GPS Track Color:", selection: $trackColor)
                    .padding(.horizontal)

                TextField("GPS Track width:", value: $trackWidth, format: .number)
                    .onSubmit { vm.refreshTracks = true }
                    .padding(.horizontal)
                    .help("Use 0 for the system default width")

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

// Color extension to allow storage in AppStorage
// Code taken from:
// https://gist.github.com/vibrazy/b105e3138105f604ab1ee4cfcdb67075

extension Color: RawRepresentable {
    public init?(rawValue: Int) {
        let red =   Double((rawValue & 0xFF0000) >> 16) / 0xFF
        let green = Double((rawValue & 0x00FF00) >> 8) / 0xFF
        let blue =  Double(rawValue & 0x0000FF) / 0xFF
        self = Color(red: red, green: green, blue: blue)
    }

    public var rawValue: Int {
        guard let coreImageColor = coreImageColor else {
            return 0
        }
        let red = Int(coreImageColor.red * 255 + 0.5)
        let green = Int(coreImageColor.green * 255 + 0.5)
        let blue = Int(coreImageColor.blue * 255 + 0.5)
        return (red << 16) | (green << 8) | blue
    }

    private var coreImageColor: CIColor? {
        return CIColor(color: NSColor(self))
    }
}
