import Foundation
import Testing
@testable import Metadata

struct MetadataDateTests {
    @Test func timestampNoDate() async throws {
        let metadata = Metadata(source: .image(imageURL))
        #expect(metadata.dateTimeCreated == nil)
        #expect(metadata.timestamp == "")
    }

    @Test func timestampWithDate() async throws {
        let value = "2026:02:01 12:34:56"
        var metadata = Metadata(source: .image(imageURL))
        metadata.dateTimeCreated = value
        #expect(metadata.timestamp == value)
    }

    @Test func noTimestampAsDate() async throws {
        let metadata = Metadata(source: .image(imageURL))
        let date = Date.now
        #expect(metadata.date() >= date)
        #expect(metadata.date() <= Date.now)
    }

    // Daylight savings caused the following tests to fail.
    // That's a little bit too fragile. Throw in a DST adjustment.

    @Test func timestampAsDate() async throws {
        var metadata = Metadata(source: .image(imageURL))
        let referenceDateString = "2001:01:01 00:00:00"
        metadata.dateTimeCreated = referenceDateString

        // with timezone
        let utc = try #require(TimeZone(secondsFromGMT: 0))
        let referenceUTCDate = Date(timeIntervalSinceReferenceDate: 0)
        #expect(metadata.date(timeZone: utc) == referenceUTCDate)

        // without timezone (adjust for DST)
        let timeZone = TimeZone.current
        let dstOffset = timeZone.daylightSavingTimeOffset()
        let interval = TimeInterval(-Double(TimeZone.current.secondsFromGMT()) + dstOffset)
        let referenceDate = Date(timeIntervalSinceReferenceDate: interval)
        #expect(metadata.date() == referenceDate)
    }

    @Test func createTimestampFromDate() async throws {
        let timeZone = TimeZone.current
        let dstOffset = timeZone.daylightSavingTimeOffset()
        let interval = TimeInterval(-Double(TimeZone.current.secondsFromGMT()) + dstOffset)
        let date = Date(timeIntervalSinceReferenceDate: interval)
        let timestamp = Metadata.timestamp(from: date)
        #expect(timestamp == "2001:01:01 00:00:00")
    }
}
