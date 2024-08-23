//
//  AppStateLogger.swift
//  GeoTag
//
//  Created by Marco S Hyman on 4/15/24.
//

import OSLog

extension AppState {
    static let logger = Logger(subsystem: Bundle.main.bundleIdentifier!,
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
}
