import OSLog
import SwiftUI

// clone part of the main app TestIDs here. The values need to be in
// sync for automated user interface testing
enum TestIDs {
    enum RunLogView {
        static let refreshID = "RunLogView.button.refresh"
        static let copyID = "RunLogView.button.copy"
    }
}

public struct RunLogView: View {
    @State private var logEntries: [String] = []
    @State private var fetchingLog = false
    @State private var copyLog = true

    let testIDs = TestIDs.RunLogView.self

    public init() {}

    public var body: some View {
        VStack {
            List {
                HStack {
                    Button {
                        Task {
                            fetchingLog = true
                            logEntries = await getLogEntries()
                            fetchingLog = false
                            copyLog = true
                        }
                    } label: {
                        Text("Refresh list")
                            .padding(.horizontal)
                    }
                    .accessibilityIdentifier(testIDs.refreshID)
                    .disabled(fetchingLog)
                    Button {
                        let pb = NSPasteboard.general
                        pb.clearContents()
                        pb.setString(
                            logEntries.reduce("") { $0 + $1 + "\n" },
                            forType: .string)
                        copyLog = false
                    } label: {
                        Text("\(copyLog ? "Copy" : "Copied!")")
                            .padding(.horizontal)
                    }
                    .accessibilityIdentifier(testIDs.copyID)
                    .disabled(!copyLog || logEntries.isEmpty)
                }

                ForEach(logEntries, id: \.self) { entry in
                    Text(entry)
                    .font(Font.system(size: 13).monospaced())
                }
            }
        }
        .task {
            fetchingLog = true
            logEntries = await getLogEntries()
            fetchingLog = false
        }
    }
}

extension RunLogView {
    @concurrent nonisolated private
    func getLogEntries() async -> [String] {
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
                let formatedEntry = """
                    \(formattedTime):  \(entry.category) | \
                    \(entry.composedMessage)
                    """
                loggedMessages.append(formatedEntry)
            }
        } catch {
            let formattedTime = timeFormatter.string(from: Date.now)
            loggedMessages.append(
                """
                \(formattedTime): failed to access log store: \
                \(error.localizedDescription)
                """)
        }
        return loggedMessages
    }
}

#Preview {
    RunLogView()
}
