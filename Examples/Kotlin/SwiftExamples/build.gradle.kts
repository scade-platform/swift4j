plugins {
    java
    application
    kotlin("jvm") version "2.0.10"
    id("io.scade.gradle.plugins.swiftpm") version "1.0.2"
}

group = "org.swift.examples.kotlin"
version = "1.0-SNAPSHOT"

repositories {
    mavenCentral()
}

dependencies {
    testImplementation(kotlin("test"))
}

tasks.test {
    useJUnitPlatform()
}

kotlin {
    jvmToolchain(21)
}

application {
    mainClass = "org.swift.examples.MainKt"
}

swiftpm {
    path = file("../../Packages/swift-java-examples")
    product = "swift-java-examples"
}