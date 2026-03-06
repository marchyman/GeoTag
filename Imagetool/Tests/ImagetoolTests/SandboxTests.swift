import Foundation
import Metadata
import Testing
@testable import Imagetool

struct SandboxTests {

    // return the url of a folder in the standard temporaryDirectory
    // used to hold files that will be modified by tests
    // if an image url is passed to the function copy the image
    // into the folder before returning

    func makeTestFolder(andCopy url: URL? = nil) throws -> URL {
        let testFolder =
            URL.temporaryDirectory.appending(components: UUID().uuidString)

        try FileManager.default.createDirectory(at: testFolder,
                                                withIntermediateDirectories: true)
        if let url {
            let name = url.lastPathComponent
            let copy = testFolder.appending(component: name)
            try FileManager.default.copyItem(at: url, to: copy)
        }
        return testFolder
    }

    @Test func initSandbox() async throws {
        let url = try #require(URL(string: "file:///a/path/to/a/file.img"))
        var dir: URL?

        if let sandbox = try? Sandbox(for: url) {
            defer {
                sandbox.removeSandboxFolder()
            }
            dir = sandbox.imgDir
        }
        #expect(dir != nil)
        #expect(!FileManager.default.fileExists(atPath: dir!.path))
    }

    @Test func sandboxContents() async throws {
        let url = try #require(
            Bundle.module.url(forResource: "262M1559",
                              withExtension: "DNG"))
        let xmp = try #require(
            Bundle.module.url(forResource: "262M1559",
                              withExtension: "xmp"))

        let sandbox = try Sandbox(for: url)
        let contents =
            try FileManager.default.contentsOfDirectory(at: sandbox.imgDir,
                                                        includingPropertiesForKeys: [.isSymbolicLinkKey])
        for link in contents {
            let wrapper = try FileWrapper(url: link)
            #expect(wrapper.isSymbolicLink)
            let original = link.resolvingSymlinksInPath()
            if link.pathExtension == xmpExtension {
                #expect(xmp == original)
            } else {
                #expect(url == original)
            }
        }
        sandbox.removeSandboxFolder()
    }

    @Test func makeSidecar() async throws {
        let url = try #require(
            Bundle.module.url(forResource: "alldata",
                              withExtension: "jpg"))
        let testFolder = try makeTestFolder(andCopy: url)
        defer {
            try? FileManager.default.removeItem(at: testFolder)
        }
        let name = url.lastPathComponent
        let testImage = testFolder.appending(component: name)
        let testXmp = testImage.deletingPathExtension()
                               .appendingPathExtension(xmpExtension)

        let sandbox = try Sandbox(for: testImage)
        try sandbox.makeSidecarFile()
        let contents =
            try FileManager.default.contentsOfDirectory(at: sandbox.imgDir,
                                                        includingPropertiesForKeys: [.isSymbolicLinkKey])
        for link in contents {
            let wrapper = try FileWrapper(url: link)
            #expect(wrapper.isSymbolicLink)
            let original = link.resolvingSymlinksInPath()
            if link.pathExtension == xmpExtension {
                #expect(testXmp == original)
            } else {
                #expect(testImage == original)
            }
        }
        sandbox.removeSandboxFolder()
    }
}
