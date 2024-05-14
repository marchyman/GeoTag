//
//  ShowLogView.swift
//  GeoTag
//
//  Created by Marco S Hyman on 4/15/24.
//

import SwiftUI

struct ShowLogView: View {
    @Environment(AppState.self) var state
    @State private var logEntries: [String] = []

    var body: some View {
        VStack {
            Button {
                logEntries = state.getLogEntries()
            } label: {
                Text("Refresh list")
            }
            .padding()

            List(logEntries, id: \.self) { entry in
                Text(entry)
            }
            .padding()
        }
        .onAppear {
            logEntries = state.getLogEntries()
        }
    }
}

#Preview {
    ShowLogView()
        .environment(AppState())
}
