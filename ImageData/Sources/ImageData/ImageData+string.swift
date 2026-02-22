import Coords
import Foundation

extension ImageData {
    public var stringRepresentation: String {
        var stringRep = ""
        if metadata.location != nil {
            stringRep = "\(metadata.formattedLatitude), \(metadata.formattedLongitude)"
            if let elevation = metadata.elevation {
                stringRep += ", \(elevation)"
            }
        }
        return stringRep
    }

    // decode the above string representation into a tuple containing
    // coordinates and optional elevation.

    public static func decodeStringRep(value: String) -> (Coords, Double?)? {
        // accept "| " as a separator for backwards compatibility
        let separator = /[,|]\s+/
        let components = value.split(separator: separator)
        if components.count == 2 || components.count == 3 {
            var coords: Coords

            if let latitude = String(components[0]).validateLatitude(),
                let longitude = String(components[1]).validateLongitude()
            {
                coords = Coords(latitude: latitude, longitude: longitude)
                if components.count == 3 {
                    let eleVal = components[2].trimmingCharacters(
                        in: .whitespaces)
                    if let elevation = Double(eleVal) {
                        return (coords, elevation)
                    }
                } else {
                    return (coords, nil)
                }
            }
        }
        return nil
    }
}
