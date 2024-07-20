import SwiftUI

// AppStorage equivalents, but part of the @Observable object
extension MapAndSearchData {

    var initialMapLatitudeKey: String { "InitialMapLatitude" }
    var initialMapLatitude: Double {
        get {
            access(keyPath: \.initialMapLatitude)
            if let val = UserDefaults.standard.object(forKey: initialMapLatitudeKey) as? Double {
                return val
            }
            return 37.7244
        }
        set {
            withMutation (keyPath: \.initialMapLatitude) {
                UserDefaults.standard.set(newValue, forKey: initialMapLatitudeKey)
            }
        }
    }

    var initialMapLongitudeKey: String { "InitialMapLongitude" }
    var initialMapLongitude: Double {
        get {
            access(keyPath: \.initialMapLongitude)
            if let val = UserDefaults.standard.object(forKey: initialMapLongitudeKey) as? Double {
                return val
            }
            return -122.4381
        }
        set {
            withMutation(keyPath: \.initialMapLongitude) {
                UserDefaults.standard.set(newValue, forKey: initialMapLongitudeKey)
            }
        }
    }

    var initialMapDistanceKey: String { "InitialMapDistance" }
    var initialMapDistance: Double {
        get {
            access(keyPath: \.initialMapDistance)
            if let val = UserDefaults.standard.object(forKey: initialMapDistanceKey) as? Double {
                return val
            }
            return 50_000.0
        }
        set {
            withMutation (keyPath: \.initialMapDistance) {
                UserDefaults.standard.set(newValue, forKey: initialMapDistanceKey)
            }
        }
    }

    var savedMapStyleKey: String { "SavedMapStyle" }
    var savedMapStyle: String {
        get {
            access(keyPath: \.savedMapStyle)
            return UserDefaults.standard.string(forKey: savedMapStyleKey) ??
                MapStyleName.standard.rawValue
        }
        set {
            withMutation (keyPath: \.savedMapStyle) {
                UserDefaults.standard.set(newValue, forKey: savedMapStyleKey)
            }
        }
    }

    var trackColorKey: String { "TrackColor" }
    public var trackColor: Color {
        get {
            access(keyPath: \.trackColor)
            if let val = UserDefaults.standard.object(forKey: trackColorKey) as? Data {
                do {
                    let color = try NSKeyedUnarchiver.unarchivedObject(
                        ofClass: NSColor.self, from: val)
                        ?? .systemBlue
                    return Color(color)
                } catch {
                    logger.error("\(#function) cannot decode track color")
                    logger.error("\(error.localizedDescription, privacy: .public)")
                }
            }
            return .blue
        }
        set {
            withMutation(keyPath: \.trackColorKey) {
                do {
                    let savedColor = NSColor(newValue)
                    let data = try NSKeyedArchiver.archivedData(
                        withRootObject: savedColor,
                        requiringSecureCoding: false)
                    UserDefaults.standard.set(data, forKey: trackColorKey)
                } catch {
                    logger.error("\(#function) cannot save track color \(newValue, privacy: .public)")
                    logger.error("\(error.localizedDescription, privacy: .public)")
                }
            }
        }
    }

    var trackWidthKey: String { "TrackWidthKey" }
    public var trackWidth: Double {
        get {
            access(keyPath: \.trackWidth)
            // if the key doesn't exist 0 is returned which is the default
            // value for this variable
            return UserDefaults.standard.double(forKey: trackWidthKey)
        }
        set {
            withMutation(keyPath: \.trackWidth) {
                UserDefaults.standard.set(newValue, forKey: trackWidthKey)
            }
        }
    }
}

