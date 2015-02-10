// Playground - noun: a place where people can play

import Cocoa

var str = "Hello, playground"

class Foo {
    var variable: Int = 42
}

var foo: Foo? = Foo()

if let bar = foo?.variable {
    println("foo.variable is \(bar)")
}