import Testing
@testable import Metadata

struct MetadataIdTests {
    @Test func simpleIdTest() async throws {
        let id1 = Metadata.nextId()
        let id2 = Metadata.nextId()
        #expect(id2 != id1)
    }

    @Test func concurentIdTest() async throws {
        let low = 1
        let high = 500
        var ids: [Int] = []

        // generate a bunch of ids, each in its own task
        await withTaskGroup(of: Int.self) { group in
            for _ in low...high {
                group.addTask {
                    return Metadata.nextId()
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
