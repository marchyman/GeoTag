// A concurrency safe source of monotonically increasing identifiers
// for NewImageModels

import Synchronization

extension NewImageModel {
    private static let idMutex = Mutex(0)

    private static var id: Int {
        get {
            return idMutex.withLock { id in
                return id
            }
        }
        set {
            idMutex.withLock { id in
                id = newValue
            }
        }
    }

    static func nextId() -> Int {
        return idMutex.withLock { id in
            id += 1
            return id
        }
    }
}
