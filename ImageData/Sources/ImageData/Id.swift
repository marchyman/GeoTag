// A concurrency safe source of monotonically increasing identifiers

import Synchronization

extension ImageData {
    private static let idMutex = Mutex(0)

    static func nextId() -> Int {
        return idMutex.withLock { id in
            id += 1
            return id
        }
    }
}
