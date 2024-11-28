package org.swift.examples

import swift_java_examples.GreetingService
import  swift_java_examples.Arrays

fun main() {
    System.loadLibrary("swift-java-examples")

    //callbacks()
    arrays()
}

fun callbacks() {
    val greetings = GreetingService()

    greetings.greetAsync("Kotlin", 2) {
        println(it.message)
    }

    println("Wait for a greeting...")

    Thread.sleep(5_000)

    println("Done !!!")
}

fun arrays() {
    val arr = longArrayOf(1, 2, 3)

    Arrays.printArray(arr)

    Arrays.reverseArray(arr).forEach {
        println(it)
    }
}