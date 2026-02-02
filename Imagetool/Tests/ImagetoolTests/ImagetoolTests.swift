import Foundation
import Metadata
import Testing
@testable import Imagetool

struct ImagetoolTests {
    @Test func imageSourceCreateFailure() async throws {
        let url = URL(string: "bad url")!
        #expect(throws: Imagetool.ImageError.cgSourceError.self) {
            try Imagetool.metadata(from: url)
        }
    }

    // this test used to fail. It looks like Apple can now handle compressed
    // RAW Fuji files.  I'll need to find another file that fails.

    @Test(.disabled()) func imageSourceNoMetadata() async throws {
        let url = try #require(
            Bundle.module.url(forResource: "nometadata",
                              withExtension: "RAF")
        )
        #expect(throws: Imagetool.ImageError.noMetadataError.self) {
            try Imagetool.metadata(from: url)
        }
    }
}
