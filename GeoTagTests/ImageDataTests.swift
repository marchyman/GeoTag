//
//  ImageDataTests.swift
//  GeoTagTests
//
//  Created by Marco S Hyman on 5/24/19.
//  Copyright © 2019 Marco S Hyman. All rights reserved.
//

import XCTest
@testable import GeoTag

class ImageDataTests: XCTestCase {

    // these URLs will be replaced with an actual URL during setup
    var testUrl1 = URL(fileURLWithPath: "foo")
    var sandboxUrl1 = URL(fileURLWithPath: "foo")
    var testUrl2 = URL(fileURLWithPath: "bar")
    var sandboxUrl2 = URL(fileURLWithPath: "bar")

    let testImageName1 = "IMG_7162"
    let testImageExt1 = "CR2"
    let testImageName2 = "L1000038"
    let testImageExt2 = "DNG"
    let testImageDir = "TestPictures"

    override func setUp() {
        // Find our bundle and the document directory
        let bundle = Bundle(for: type(of: self))
        let fileManager = FileManager.default
        guard let docDir = try? fileManager.url(for: .documentDirectory,
                                                in: .userDomainMask,
                                                appropriateFor: nil,
                                                create: true) else {
            XCTFail("Cannon access Document Directory")
            return
        }

        // Find the first test image and clean any existing link in
        // the sandboxed document directory
        guard let imgUrl1 = bundle.url(forResource: testImageName1,
                                       withExtension: testImageExt1,
                                       subdirectory: testImageDir) else {
            XCTFail("Cannon create ImageData instance 1 \(testImageName1)")
            return
        }
        testUrl1 = imgUrl1
        sandboxUrl1 = docDir.appendingPathComponent(testUrl1.lastPathComponent)
        try? fileManager.removeItem(at: sandboxUrl1)
        
        // do the same thing for the second test image
        guard let imgUrl2 = bundle.url(forResource: testImageName2,
                                       withExtension: testImageExt2,
                                       subdirectory: testImageDir) else {
            XCTFail("Cannon create ImageData instance 2 \(testImageName2)")
            return
        }
        testUrl2 = imgUrl2
        sandboxUrl2 = docDir.appendingPathComponent(testUrl2.lastPathComponent)
        try? fileManager.removeItem(at: sandboxUrl2)

        // set the image backup folder to the users temp directory
        var bookmark: Data? = nil
        let url = fileManager.temporaryDirectory
        do {
            try bookmark = url.bookmarkData(options: .withSecurityScope)
        } catch let error as NSError {
            XCTFail("Cannot create security bookmark for image backup folder\n\nReason: \(error)")
        }
        let defaults = UserDefaults.standard
        defaults.set(bookmark, forKey: Preferences.saveBookmarkKey)
        Preferences.checkDirectory = true
        guard let saveFolder = Preferences.saveFolder() else {
            XCTFail("Cannot set save folder")
            return
        }
        // The returned saveFolder has symlinks resolved.
        // resolvingSymlinksInPath doesn't work for folders
        // adjust the url path (add /private as the first component) and
        // compare to the returned path
        let urlPath = "/private" + url.path
        XCTAssert(saveFolder.path == urlPath,
                  "\(saveFolder.path) should be \(urlPath)")

        // clear out any existing backups of the test files
        let backupUrl1 = url.appendingPathComponent(testUrl1.lastPathComponent)
        try? fileManager.removeItem(at: backupUrl1)
        let backupXmp = backupUrl1.deletingPathExtension()
                                  .appendingPathExtension(xmpExtension)
        try? fileManager.removeItem(at: backupXmp)
        let backupUrl2 = url.appendingPathComponent(testUrl2.lastPathComponent)
        try? fileManager.removeItem(at: backupUrl2)

    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    /// test ImageData init of an image where an XMP sidecar also exists
    func testInit1() {
        let fileManager = FileManager.default
        let img = ImageData(url: testUrl1)
        XCTAssert(img.url == testUrl1, "Incorrect URL for image")
        let xmpUrl = testUrl1.deletingPathExtension().appendingPathExtension(xmpExtension)
        XCTAssert(img.xmpUrl == xmpUrl)
        XCTAssert(img.sandboxUrl == sandboxUrl1)
        guard let sandboxXmp = img.sandboxXmp else {
            XCTFail("sandboxXmp is nil")
            return
        }
        XCTAssert(fileManager.fileExists(atPath: (sandboxXmp.path)),
                  "\(sandboxXmp.path) does not exist in sandbox")
        XCTAssert(img.dateTime == "2015:11:12 13:08:23",
                  "Wrong time stamp: \(img.dateTime)")
        XCTAssert(img.dateTime == img.originalDateTime)
        XCTAssertNil(img.location, "Image Location not nil")
        XCTAssertNil(img.originalLocation, "Image originalLocation not nil")
        XCTAssert(img.validImage, "Image is not valid")
        
        // XMPFile checks
        XCTAssert(img.xmpFile.primaryPresentedItemURL == sandboxUrl1)
        let sandboxXml = sandboxUrl1.deletingPathExtension()
                                    .appendingPathExtension(xmpExtension)
        XCTAssert(img.xmpFile.presentedItemURL == sandboxXml)
    }

    /// test ImageData init of an image where an XMP sidecar does not
    func testInit2() {
        let fileManager = FileManager.default
        let img = ImageData(url: testUrl2)
        XCTAssert(img.url == testUrl2)
        let xmpUrl = testUrl2.deletingPathExtension().appendingPathExtension(xmpExtension)
        XCTAssert(img.xmpUrl == xmpUrl)
        XCTAssert(img.sandboxUrl == sandboxUrl2)
        XCTAssert(fileManager.fileExists(atPath: (sandboxUrl2.path)),
                  "\(sandboxUrl2.path) does not exist in sandbox")
        XCTAssertNil(img.sandboxXmp)
        XCTAssert(img.dateTime == "2015:11:12 09:41:11",
                  "Wrong time stamp: \(img.dateTime)")
        XCTAssert(img.dateTime == img.originalDateTime)
        XCTAssertNil(img.location, "Image Location not nil")
        XCTAssertNil(img.originalLocation, "Image originalLocation not nil")
        XCTAssert(img.validImage, "Image is not valid")
        
        // XMPFile checks
        XCTAssert(img.xmpFile.primaryPresentedItemURL == sandboxUrl2)
        let sandboxXml = sandboxUrl2.deletingPathExtension()
            .appendingPathExtension(xmpExtension)
        XCTAssert(img.xmpFile.presentedItemURL == sandboxXml)
    }
    
    /// When an ImageData instance is deleted the link to the image should
    /// be removed from the application sandbox.
    func testDeinit() {
        do {
            let img1 = ImageData(url: testUrl1)
            let img2 = ImageData(url: testUrl2)
            let _ = img1    // silence compiler about img1 never used
            let _ = img2    // silence compiler about img2 never used
        }

        let fileManager = FileManager.default

        // Verify that link to image1 xml file is no longer in the sandbox
        let sandboxXml = sandboxUrl1.deletingPathExtension()
                                    .appendingPathExtension(xmpExtension)
        XCTAssert(!fileManager.fileExists(atPath: (sandboxXml.path)),
                  "\(sandboxXml.path) still exists in sandbox")

        // Verify that link to image2 file is no longer in the sandbox
        XCTAssert(!fileManager.fileExists(atPath: (sandboxUrl2.path)),
                  "\(sandboxUrl2.path) still exists in sandbox")

    }

    /// Test setting and clearing locations
    
    func testLocation() {
        let testLoc = Coord(latitude: 35.1234, longitude: -120.9876)
        let img = ImageData(url: testUrl2)
        img.location = testLoc
        XCTAssertNotNil(img.location)
        XCTAssert(img.stringRepresentation == "35.1234 -120.9876",
                  "stringRepresentation \(img.stringRepresentation) not as expected")
        img.revert()
        XCTAssertNil(img.location)
    }

    func testDateTime() {
        let img = ImageData(url: testUrl2)
        if var dateValue = img.dateValue {
            dateValue.addTimeInterval(3600)
            img.dateValue = dateValue
            XCTAssert(img.dateTime == "2015:11:12 10:41:11",
                      "dateTime \(img.dateTime), expected 2015:11:12 18:41:11")
        } else {
            XCTFail("dateValue is nil")
        }
        img.dateValue = nil
        XCTAssert(img.dateTime == "", "dateTime not nil")
        img.revert()
        XCTAssert(img.dateTime == "2015:11:12 09:41:11",
                  "dateTime \(img.dateTime), expected 2015:11:12 09:41:11")
        XCTAssert(img.dateFromEpoch == 1447350071.0,
                  "dateFromEpoch \(img.dateFromEpoch), expected 1447350071.0")
    }

    /// Test creating a back of the original file for images with and
    /// without a sidecar file.
    func testBackup() {
        let img1 = ImageData(url: testUrl1)
        XCTAssert(img1.url == testUrl1)
        XCTAssert(img1.testBackup(),
                  "Cannot backup image file with sidecar")

        let img2 = ImageData(url: testUrl2)
        XCTAssert(img2.url == testUrl2)
        XCTAssert(img2.testBackup(),
                  "Cannot backup image file without sidecar")

        let fileManager = FileManager.default
        var backupUrl = fileManager.temporaryDirectory

        // img1 backup: Only the xmp file should be backed up
        backupUrl.appendPathComponent(img1.url.lastPathComponent)
        XCTAssert(!fileManager.fileExists(atPath: backupUrl.path),
                  "Backup file \(backupUrl.path) found")
        backupUrl.deletePathExtension()
        backupUrl.appendPathExtension(xmpExtension)
        XCTAssert(fileManager.fileExists(atPath: backupUrl.path),
                  "Backup file \(backupUrl.path) not found")

        // img2 backup: No xmp file should be backed up
        backupUrl.deleteLastPathComponent()
        backupUrl.appendPathComponent(img2.url.lastPathComponent)
        XCTAssert(fileManager.fileExists(atPath: backupUrl.path),
                  "Backup file \(backupUrl.path) not found")
        backupUrl.deletePathExtension()
        backupUrl.appendPathExtension(xmpExtension)
        XCTAssert(!fileManager.fileExists(atPath: backupUrl.path),
                  "Backup file \(backupUrl.path) found")
    }
//    func testPerformanceExample() {
//        // This is an example of a performance test case.
//        self.measure {
//            // Put the code you want to measure the time of here.
//        }
//    }

}


