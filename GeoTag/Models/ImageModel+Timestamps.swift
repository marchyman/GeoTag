//
// Copyright 2024 Marco S Hyman
// See LICENSE file for info
// https://www.snafu.org/
//

import Foundation

// Date formatter used to put timestamps in the form used by exiftool when
// editing timestamps and calculating the date in GMT.

extension ImageModel {
    static let dateFormat = "yyyy:MM:dd HH:mm:ss"

    func timestamp(for timeZone: TimeZone?) -> Date? {
        let dateFormatter = DateFormatter()

        if let dateTime = dateTimeCreated {
            dateFormatter.dateFormat = ImageModel.dateFormat
            dateFormatter.timeZone = timeZone
            if let date = dateFormatter.date(from: dateTime) {
                return date
            }
        }
        return nil
    }

    // return a Date object set to the creation date adjusted by an optional
    // timeZone relative to GMT
    func gmtTimeStamp(_ timeZone: TimeZone? = nil) -> Date {
        let tz = timeZone ?? .current
        let date = timestamp(for: tz) ?? Date.now
        let offset = Double(tz.secondsFromGMT(for: date))
        let gmtDate = Date(timeInterval: offset, since: date)
        return gmtDate
    }
}
