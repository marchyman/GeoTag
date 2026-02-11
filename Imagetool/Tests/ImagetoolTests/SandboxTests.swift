import Foundation
import Metadata
import Testing
@testable import Imagetool

struct SandboxTests {
    @Test func initSandbox() async throws {
        let url = try #require(URL(string: "file:///a/path/to/a/file.img"))
        let xmp = try #require(URL(string: "file:///a/path/to/a/file.xmp"))
        var dir: URL?

        if let sandbox = try? Sandbox(for: url, sidecar: xmp) {
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
 
        let sandbox = try Sandbox(for: url, sidecar: xmp)
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
}

