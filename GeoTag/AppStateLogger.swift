//
//  AppStateLogger.swift
//  GeoTag
//
//  Created by Marco S Hyman on 4/15/24.
//

import OSLog

extension AppState {
    static var logger = Logger(subsystem: Bundle.main.bundleIdentifier!,
                               category: "AppState")
    private static let signposter = OSSignposter(logger: logger)

    func withInterval<T>(_ desc: StaticString,
                         around task: () throws -> T) rethrows -> T {
        try Self.signposter.withIntervalSignpost(desc) {
            try task()
        }
    }

    func markStart(_ desc: StaticString) -> OSSignpostIntervalState {
        let signpostID = Self.signposter.makeSignpostID()
        let interval = Self.signposter.beginInterval(desc, id: signpostID)
        return interval
    }

    func markEnd(_ desc: StaticString, interval: OSSignpostIntervalState) {
        Self.signposter.endInterval(desc, interval)
    }

    func getLogEntries() -> [String] {
        var loggedMessages: [String] = []

        do {
            let subsystem = Bundle.main.bundleIdentifier!
            let logStore = try OSLogStore(scope: .currentProcessIdentifier)
            let myEntries = try logStore.getEntries()
                                        .compactMap { $0 as? OSLogEntryLog }
                                        .filter { $0.subsystem == subsystem }
            for entry in myEntries {
                let formattedDate = entry.date
                    .formatted(.dateTime.hour().minute().second())
                let formatedEntry = "\(formattedDate) \(entry.category) \(entry.composedMessage)"
                loggedMessages.append(formatedEntry)
            }
        } catch {
            // log an error!
        }
        return loggedMessages
    }
}
