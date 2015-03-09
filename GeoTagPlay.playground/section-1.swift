// Playground - noun: a place where people can play

import Cocoa

var str = "Hello, playground"


/* The following works here but crashes when I change the AppDelegate
   code.  Will look at the crash, later */

   // storage for stored class variable
struct Statics {
    static var staticFoo: String!
}

class SomeClass {
    // stored class variables not supported, do this trick
    class var staticFoo: String! {
        get {
            return Statics.staticFoo
        }
        set {
            Statics.staticFoo = newValue
        }
    }
    init(foo: String) {
        SomeClass.staticFoo = foo
    }
}

var someClass = SomeClass(foo: "static foo value")
SomeClass.staticFoo

// -------------

class AnotherClass {
    static var staticBar: String!

    init(bar: String) {
        AnotherClass.staticBar = bar
    }

}

var anotherClass = AnotherClass(bar: "static bar value")
AnotherClass.staticBar
