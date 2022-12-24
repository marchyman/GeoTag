//
//  SettingsView.swift
//  GeoTag
//
//  Created by Marco S Hyman on 12/17/22.
//

import SwiftUI

struct SettingsView: View {
    @AppStorage(AppSettings.coordFormatKey) var coordFormat: AppSettings.CoordFormat = .deg

    var body: some View {
        VStack {
            Text("GeoTag Saved Settings")
                .font(.largeTitle)
                .padding()
            Form {
                Section {
                    LabeledContent("Choose your coordinate format") {
                        Picker("", selection: $coordFormat) {
                            Text("dd.dddddd")
                                .tag(AppSettings.CoordFormat.deg)
                            Text("dd mm.mmmmmm'")
                                .tag(AppSettings.CoordFormat.degMin)
                            Text("dd° mm' ss.ss\"")
                                .tag(AppSettings.CoordFormat.degMinSec)
                        }
                        .pickerStyle(RadioGroupPickerStyle())
                    }
                }
            }
            Spacer()
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
