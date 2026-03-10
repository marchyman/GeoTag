import Testing
@testable import Phototool

// The functions in Phototool require either a PhotosPickerItem or a PHAsset,
// both of which come from a user selecting an image from the library.
// I'm not aware of a programatic way to get the needed info.

struct PhototoolTests {
    @Test func phototool() async throws {
        print("There are no Phototool tests")
    }
}
