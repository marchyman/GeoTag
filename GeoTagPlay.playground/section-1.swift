// Playground - noun: a place where people can play

import Cocoa

var str = "Hello, playground"


var opts: Dictionary<String, AnyObject> = [kCGImageSourceCreateThumbnailWithTransform : kCFBooleanTrue as AnyObject,
    kCGImageSourceCreateThumbnailFromImageAlways : kCFBooleanTrue as AnyObject]

opts[kCGImageSourceThumbnailMaxPixelSize] = NSNumber.numberWithInt(512)

Void