import CoreLocation
import ImageData
import MapKit
import OSLog
import UDF

// actor to ensure only one reverse geocode can be active at a time

actor ReverseLocationFinder {
    private var activeTask: Task<Place?, Error>?
    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier!,
        category: "ReverseLocationFinder")

    // Only 1 shared instance

    static let shared: ReverseLocationFinder = .init()
    private init() {}

    func get(_ location: CLLocation) async throws -> Place? {
        while let task = activeTask {
            // wait until the current task ends
            if let place = try? await task.value {
                // if we happen to be requesting a placemark for the same
                // coordinates there is no need to do another reverse lookup
                if place.coordinate == Coordinate(location.coordinate) {
                    logger.info("Duplicate placemark")
                    return place
                }
            }
            activeTask = nil
        }

        // Creat a task to fetch reverse location
        activeTask = requestTask(location)

        // wait for the task to return a value
        return try await activeTask?.value
    }

    nonisolated func requestTask(_ location: CLLocation) -> Task<Place?, Error> {
        return Task {
            if let request = MKReverseGeocodingRequest(location: location) {
                let mapItems = try await request.mapItems
                // MKPlacemarks have been deprecated but I've not yet found
                // something to replace them
                if let item = mapItems.first {
                    return Place(from: item)
                }
            }
            return nil
        }
    }

    @MainActor
    public static func reverseGeocode(store: Store<GeoTagState, GeoTagEvent>,
                                      id: ImageData.ID) async -> Place? {
        if let location = store[id].metadata.clLocation(store.timeZone) {
           return try? await ReverseLocationFinder.shared.get(location)
        }
        return nil
    }
}
