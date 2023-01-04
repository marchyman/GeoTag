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
                    .onChange(of: trackColor.rawValue) { color in
                        vm.refreshTracks = true
                    }
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
