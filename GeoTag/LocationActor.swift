import CoreLocation
import ImageData
import MapKit
import OSLog
import UDF

// actor to ensure only one reverse geocode can be active at a time

struct FullAddress: Equatable {
    let location: CLLocationCoordinate2D
    let city: String?
    let state: String?
    let country: String?
    let countryCode: String?
}

actor ReverseLocationFinder {
    private var activeTask: Task<FullAddress?, Error>?
    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier!,
        category: "ReverseLocationFinder")

    // Only 1 shared instance

    static let shared: ReverseLocationFinder = .init()
    private init() {}

    func get(_ location: CLLocation) async throws -> FullAddress? {
        while let task = activeTask {
            // wait until the current task ends
            if let fullAddress = try? await task.value {
                // if we happen to be requesting a placemark for the same
                // coordinates there is no need to do another reverse lookup
                if fullAddress.location == location.coordinate {
                    logger.info("Duplicate placemark")
                    return fullAddress
                }
            }
            activeTask = nil
        }

        // Creat a task to fetch reverse location
        let task = requestTask(location) // Task<MKPlacemark?, Error> {

        // save it as the active task and wait for the result
        activeTask = task
        return try await task.value
    }

    nonisolated func requestTask(_ location: CLLocation) -> Task<FullAddress?, Error> {
        return Task {
            if let request = MKReverseGeocodingRequest(location: location) {
                let mapItems = try await request.mapItems
                // MKPlacemarks have been deprecated but I've not yet found
                // something to replace them
                if let address = mapItems.first?.placemark {
                    // logger.info("""
                    //     Placemark:
                    //       \(address.subLocality ?? "unknown sub locality", privacy: .public)
                    //       \(address.locality ?? "unknown locality", privacy: .public)
                    //       \(address.administrativeArea ?? "unknown administrative area", privacy: .public)
                    //       \(address.country ?? "unknown country", privacy: .public)
                    //       \(address.isoCountryCode ?? "unknown country code", privacy: .public)
                    //     """)
                    return FullAddress(location: location.coordinate,
                                       city: address.locality,
                                       state: address.administrativeArea,
                                       country: address.country,
                                       countryCode: address.isoCountryCode)
                }
            }
            return nil
        }
    }

    @MainActor
    public static func reverseGeocode(store: Store<GeoTagState, GeoTagEvent>,
                                      id: ImageData.ID) async -> FullAddress? {
        if let location = store[id].location(store.timeZone) {
           return try? await ReverseLocationFinder.shared.get(location)
        }
        return nil
    }
}
