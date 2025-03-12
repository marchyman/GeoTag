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
