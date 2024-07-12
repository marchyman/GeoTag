//
//  RunLogView.swift
//  GeoTag
//
//  Created by Marco S Hyman on 4/15/24.
//

import OSLog
import SwiftUI

struct RunLogView: View {
    @State private var logEntries: [String] = []

    var body: some View {
        VStack {
            Button {
                logEntries = getLogEntries()
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
            logEntries = getLogEntries()
        }
    }
}

extension RunLogView {
    private func getLogEntries() -> [String] {
        var loggedMessages: [String] = []
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm:ss.SSS"
        do {
            let subsystem = Bundle.main.bundleIdentifier!
            let logStore = try OSLogStore(scope: .currentProcessIdentifier)
            let myEntries = try logStore.getEntries()
                                        .compactMap { $0 as? OSLogEntryLog }
                                        .filter { $0.subsystem == subsystem }
            for entry in myEntries {
                let formattedTime = timeFormatter.string(from: entry.date)
                let formatedEntry = "\(formattedTime):  \(entry.category)  \(entry.composedMessage)"
                loggedMessages.append(formatedEntry)
            }
        } catch {
            let formattedTime = timeFormatter.string(from: Date.now)
            loggedMessages.append("\(formattedTime): failed to access log store: \(error.localizedDescription)")
        }
        return loggedMessages
    }

}
#Preview {
    RunLogView()
}
