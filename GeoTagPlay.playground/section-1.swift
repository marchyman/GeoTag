// Playground - noun: a place where people can play

import Cocoa

var str = "Hello, playground"

let pb = NSPasteboard.generalPasteboard()

if let val = pb.stringForType(NSPasteboardTypeString) {
    val
}
