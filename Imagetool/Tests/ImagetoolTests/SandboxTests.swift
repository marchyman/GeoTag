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

    @Test func backupFile() async throws {
        // Copy test image to test folder
        let url = try #require(
            Bundle.module.url(forResource: "alldata",
                              withExtension: "jpg"))
        let testFolder = try makeTestFolder(andCopy: url)
        defer {
            try? FileManager.default.removeItem(at: testFolder)
        }

        // make a sandbox entry for the copied test image
        let name = url.lastPathComponent
        let testImage = testFolder.appending(component: name)
        let sandbox = try Sandbox(for: testImage)

        // make a backup folder
        let backupFolder = testFolder.appending(component: "backup/")
        try FileManager.default.createDirectory(at: backupFolder,
                                                withIntermediateDirectories: true)

        // make a backup file twice to verify backup naming
        try await sandbox.makeBackupFile(backupFolder: backupFolder)
        try await sandbox.makeBackupFile(backupFolder: backupFolder)

        // verify the backup folder contains both copies
        let contents =
            try FileManager.default.contentsOfDirectory(at: backupFolder,
                                                        includingPropertiesForKeys: nil)
        #expect(contents.contains { $0.lastPathComponent == name })
        #expect(contents.count == 2)

        // clean up
        sandbox.removeSandboxFolder()
    }

    @Test func backupSidecar() async throws {
        // Copy test image to test folder
        let url = try #require(
            Bundle.module.url(forResource: "262M1559",
                              withExtension: "DNG"))
        let testFolder = try makeTestFolder(andCopy: url)
        defer {
            try? FileManager.default.removeItem(at: testFolder)
        }

        // Copy the Sidecar file, too.
        let xmp = try #require(
            Bundle.module.url(forResource: "262M1559",
                              withExtension: "xmp"))
        let xmpName = xmp.lastPathComponent
        let xmpCopy = testFolder.appending(component: xmpName)
        try FileManager.default.copyItem(at: url, to: xmpCopy)

        // make a sandbox for the image and sidecar
        let name = url.lastPathComponent
        let testImage = testFolder.appending(component: name)
        let sandbox = try Sandbox(for: testImage)

        // make a backup folder
        let backupFolder = testFolder.appending(component: "backup/")
        try FileManager.default.createDirectory(at: backupFolder,
                                                withIntermediateDirectories: true)
        // make a backup file twice to verify backup naming
        try await sandbox.makeBackupFile(backupFolder: backupFolder)
        try await sandbox.makeBackupFile(backupFolder: backupFolder)

        // verify the backup folder contains both copies of the XMP file
        let contents =
            try FileManager.default.contentsOfDirectory(at: backupFolder,
                                                        includingPropertiesForKeys: nil)
        #expect(contents.contains { $0.lastPathComponent == xmpName })
        #expect(contents.count == 2)

        // clean up
        sandbox.removeSandboxFolder()
    }
}
