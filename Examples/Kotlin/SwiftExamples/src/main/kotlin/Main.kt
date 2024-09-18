package org.swift.examples

import swift_java_examples.Service

fun main() {
    System.loadLibrary("swift-java-examples")

    val srv = Service()
    srv.request {
        println(it.message)
    }

    println("Done !!!")
}