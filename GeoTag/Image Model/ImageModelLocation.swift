import CoreLocation
import OSLog

// return a CLLocation for the image based upon its coordinates and elevation

extension ImageModel {
    func fullLocation(_ timeZone: TimeZone?) -> CLLocation? {
        if let location {
            let altitude: Double
            let verticalAccuracy: Double
            if let elevation {
                altitude = elevation
                verticalAccuracy = 20  // a number picked out of the air
            } else {
                altitude = 0
                verticalAccuracy = 0
            }
            let timeStamp = gmtTimeStamp(timeZone)
            return CLLocation(
                coordinate: location,
                altitude: altitude,
                horizontalAccuracy: 10,
                verticalAccuracy: verticalAccuracy,
                timestamp: timeStamp)
        }
        return nil
    }
}

// actor to ensure only one reverse geocode can be active at a time

actor ReverseLocationFinder {
    private var activeTask: Task<CLPlacemark?, Error>?
    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier!,
        category: "ReverseLocationFinder")

    // Only 1 shared instance

    static let shared: ReverseLocationFinder = .init()
    private init() {}

    func get(_ location: CLLocation) async throws -> CLPlacemark? {
        while let task = activeTask {
            // wait until the current task ends
            if let placemark = try? await task.value {
                // if we happen to be requesting a placemark for the same
                // coordinates there is no need to do another reverse lookup
                if placemark.location?.coordinate == location.coordinate {
                    logger.info("Duplicate placemark")
                    return placemark
                }
            }
        }

        // Creat a task to fetch reverse location
        let task = Task<CLPlacemark?, Error> {
            let geoCoder = CLGeocoder()
            let placemarks = try? await geoCoder.reverseGeocodeLocation(location)
            activeTask = nil
            if let placemark = placemarks?.first {
                logger.info("""
                    Placemark:
                      \(placemark.subLocality ?? "unknown sub locality", privacy: .public)
                      \(placemark.locality ?? "unknown locality", privacy: .public)
                      \(placemark.administrativeArea ?? "unknown administrative area", privacy: .public)
                      \(placemark.country ?? "unknown country", privacy: .public)
                      \(placemark.isoCountryCode ?? "unknown country code", privacy: .public)
                    """)
                return placemark
            }
            return nil
        }

        // save it as the active task and wait for the result
        activeTask = task
        return try await task.value
    }
}
