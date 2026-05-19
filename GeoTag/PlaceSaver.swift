import Foundation
import OSLog

actor PlaceSaver {
    private var busy = false
    static let shared: PlaceSaver = .init()
    private init() {}

    // return the URL of "Places" in the app support folder

    private func appSupportURL() -> URL {
        let name = "Places"
        let placesURL = URL.applicationSupportDirectory.appendingPathComponent(name)
        return placesURL
    }

    // read places from a file in the application support folder

    func read() -> [Place] {
        let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "GeoTag",
                            category: "Read Places")

        let url = appSupportURL()
        if let places = try? Data(contentsOf: url) {
            do {
                let decoder = JSONDecoder()
                let decoded = try decoder.decode([Place].self,
                                                 from: places)
                return decoded
            } catch let DecodingError.dataCorrupted(context) {
                logger.error("corrupted \(context.debugDescription, privacy: .public)")
            } catch let DecodingError.keyNotFound(key, context) {
                logger.error(
                    """
                    Key '\(key.stringValue, privacy: .public)' not found: \
                    \(context.debugDescription, privacy: .public)
                    """)
            } catch let DecodingError.valueNotFound(value, context) {
                logger.error(
                    """
                    Value '\(value, privacy: .public)' not found: \
                    \(context.debugDescription, privacy: .public)
                    """)
            } catch let DecodingError.typeMismatch(type, context) {
                logger.error(
                    """
                    Type '\(type, privacy: .public)' mismatch: \
                    \(context.debugDescription, privacy: .public)
                    """)
            } catch {
                logger.error("\(error.localizedDescription, privacy: .public)")
            }
            fatalError("JSON Decoding Error for \(url)")
        }

        return []
    }

    // Encode and write places.  Only one save can be active at a
    // time. Calls to save while a save is in progress are ignored.

    func write(places: [Place]) throws {
        if !busy {
            busy = true
            let url = appSupportURL()
            let encoder = JSONEncoder()
            let encoded = try encoder.encode(places)
            try encoded.write(to: url)
            busy = false
        }
    }
}
