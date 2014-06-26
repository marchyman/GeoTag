// Playground - noun: a place where people can play

import Cocoa

var str = "Hello, playground"

struct RelatedThings {
    var count: Int
}
struct Thing {
    var relatedThings: RelatedThings
}
var optionalThing : Thing? // = Thing(relatedThings: RelatedThings(count:5))


func numberOfRelatedThings() -> Int {
    if let count = optionalThing?.relatedThings.count {
        return count
    }
    return 0
}

numberOfRelatedThings()
