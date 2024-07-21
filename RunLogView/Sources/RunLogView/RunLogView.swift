import OSLog
import SwiftUI

public struct RunLogView: View {
    @State private var logEntries: [String] = []
    @State private var fetchingLog = false

    public init() {}

    public var body: some View {
        VStack {
            Button {
                Task {
                    fetchingLog = true
                    logEntries = await getLogEntries()
                    fetchingLog = false
                }
            } label: {
                Text("Refresh list")
            }
            .padding()
            .disabled(fetchingLog)

            List(logEntries, id: \.self) { entry in
                Text(entry)
            }
            .padding()
        }
        .task {
            fetchingLog = true
            logEntries = await getLogEntries()
            fetchingLog = false
        }
    }
}

extension RunLogView {

    nonisolated private func getLogEntries() async -> [String] {
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
