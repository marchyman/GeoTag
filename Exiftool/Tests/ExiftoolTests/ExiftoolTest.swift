// Exiftool package tests

import SwiftUI
import Testing

@testable import Exiftool

struct ExiftoolTests {
    @Test func exiftootTest() async throws {
        let version = try #require(try Exiftool.helper.version())
        print("Using Exiftool version: \(version)")
    }
}
