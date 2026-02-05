import Foundation
import OSLog
import UDF

enum GeoTagEvents: Equatable {
    case firstEvent
}

struct GeoTagReducer: Reducer {
    let logger = Logger(subsystem: "org.snafu", category: "reducer")

    func reduce(_ state: GeoTagState,
                _ event: GeoTagEvents) -> GeoTagState {
        var newState = state

        switch event {
        case .firstEvent:
            break
        }

        return newState
    }
}
