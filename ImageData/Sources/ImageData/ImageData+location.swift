import CoreLocation
import Metadata

extension ImageData {
    public func location(_ timeZone: TimeZone?) -> CLLocation? {
        if let coords = metadata.location {
            let altitude: Double
            let verticalAccuracy: Double
            if let elevation = metadata.elevation {
                altitude = elevation
                verticalAccuracy = 20 // a number picked out of the air
            } else {
                altitude = 0
                verticalAccuracy = 0
            }
            let timestamp = metadata.date(timeZone: timeZone)
            return CLLocation(coordinate: coords,
                              altitude: altitude,
                              horizontalAccuracy: 10,
                              verticalAccuracy: verticalAccuracy,
                              timestamp: timestamp)
        }
        return nil
    }
}
