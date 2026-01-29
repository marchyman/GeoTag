// Tests for NewImageModel

import Testing

@testable import GeoTag

struct NewImageModelTests {
    @Test func simpleIdTest() async throws {
        let id1 = NewImageModel.nextId()
        #expect(id1 == 1)
        let id2 = NewImageModel.nextId()
        #expect(id2 == 2)
    }

    @Test func concurentIdTest() async throws {
        let low = 1
        let high = 500
        var ids: [Int] = []

        // generate a bunch of ids, each in its own task
        await withTaskGroup(of: Int.self) { group in
            for _ in low...high {
                group.addTask {
                    return NewImageModel.nextId()
                }
            }
            for await id in group {
                ids.append(id)
            }
        }

        // verify no duplicate ids were generated
        for id in ids {
            let thisIndex = ids.firstIndex(of: id)
            for index in ids.indices where index != thisIndex {
                #expect(id != ids[index],
                        "id index: \(thisIndex), index: \(index)")
            }
        }
    }
}
