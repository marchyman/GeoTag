import CoreLocation

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

    // Only 1 shared instance

    static var shared: ReverseLocationFinder = .init()
    private init() {}

    func get(_ location: CLLocation) async throws -> CLPlacemark? {
        while let task = activeTask {
            // wait until the current task ends
            _ = try? await task.value
        }

        // Creat a task to fetch reverse location
        let task = Task<CLPlacemark?, Error> {
            let geoCoder = CLGeocoder()
            let placeMarks = try? await geoCoder.reverseGeocodeLocation(location)
            activeTask = nil
            return placeMarks?.first
        }

        // save it as the active task and wait for the result
        activeTask = task
        return try await task.value
    }
}
