import Testing
@testable import Coords

struct CoordsValidTests {
    struct Args {
        let lat: Double
        let lon: Double
        init(_ lat: Double, _ lon: Double) {
            self.lat = lat
            self.lon = lon
        }
    }
    @Test(arguments: [
        Args(0, 0),
        Args(0, 180),
        Args(0, -180),
        Args(90, 0),
        Args(90, 180),
        Args(90, -180),
        Args(-90, 0),
        Args(-90, 180),
        Args(-90, -180)
    ])
    func goodCoordsTest(args: Args) async throws {
        let coords = try #require(Coords.ifValid(latitude: args.lat,
                                                 longitude: args.lon))
        #expect(coords.latitude == args.lat)
        #expect(coords.longitude == args.lon)
    }

    @Test(arguments: [
        Args(90.001, 0),
        Args(-90.001, 0),
        Args(0, 180.001),
        Args(0, -180.001)
    ])
    func badCoordsTest(args: Args) async throws {
        #expect(Coords.ifValid(latitude: args.lat,
                               longitude: args.lon) == nil)
    }
}
