//
//  AdjustTimezoneView.swift
//  GeoTag
//
//  Created by Marco S Hyman on 1/2/23.
//

import SwiftUI

struct AdjustTimezoneView: View {
    @EnvironmentObject var vm: ViewModel

    var body: some View {
        VStack {
            Text("Specify Camera Time Zone")
                .font(.largeTitle)
                .padding()
            Text("""
                 When matching images to a GPS track log GeoTag assumes image
                 Time Zones are the local-to-this-computer Time Zone. If the
                 camera was set to the local time in some other time zone
                 select the appropriate time zone here.
                 """)
                .padding()
            Divider()
            Text("Current Camera Time Zone")
                .padding()
            Divider()
            Text("New Camera Time Zone")
                .padding()
            Divider()
            HStack {
                Spacer()
                Button("Cancel") {
                    NSApplication.shared.keyWindow?.close()
                }
                .keyboardShortcut(.cancelAction)
                Button("Change") {
                    // update ViewModel here
                    NSApplication.shared.keyWindow?.close()
                }
                .keyboardShortcut(.defaultAction)
            }
            .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .frame(width: 500.0, height: 400.0)
    }
}

struct AdjustTimezoneView_Previews: PreviewProvider {
    static var previews: some View {
        AdjustTimezoneView()
            .environmentObject(ViewModel())
    }
}
