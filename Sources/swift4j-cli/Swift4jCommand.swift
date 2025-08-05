import Foundation
import ArgumentParser

@main
struct Swift4jCommand: ParsableCommand {
  @Option(name: .shortAndLong,
          help: "Output directory")
  var outdir: String?

  @Option(name: .long,
          help: "Java package name")
  var package: String
  
  @Option(name: .long,
          help: "Java version")
  var javaVersion: Int = 11

  @Argument(help: "Input filenames.")
  var paths: [String] = []
  

  mutating func validate() throws {
    if paths.isEmpty {
      throw ValidationError("Input is empty.")
    }

    var isDir: ObjCBool = false

    for p in paths {
      if !FileManager.default.fileExists(atPath: p, isDirectory: &isDir) {
        throw ValidationError("\(p) does not exist.")
      }

      if isDir.boolValue {
        throw ValidationError("\(p) is a path to a directory, not a Swift source file.")
      }
    }

    if let outdir = outdir {
      if !FileManager.default.fileExists(atPath: outdir, isDirectory: &isDir) {
        throw ValidationError("\(outdir) does not exist.")
      }

      if !isDir.boolValue {
        throw ValidationError("\(outdir) is a path to a file, not a directory.")
      }
    }
  }


  mutating func run() throws {
    let generator = ProxyGenerator(package: package, javaVersion: javaVersion)

    for p in paths {
      for res in try generator.run(path: p) {
        if let outdir = outdir {

          let pkgDir: URL
          if #available(macOS 13.0, *) {
            pkgDir = URL(filePath: "\(outdir)/\(package)")
          } else {
            pkgDir = URL(fileURLWithPath: "\(outdir)/\(package)")
          }

          let pkgDirPath: String
          if #available(macOS 13.0, *) {
            pkgDirPath = pkgDir.path()
          } else {
            pkgDirPath = pkgDir.path
          }

          var isDirectory: ObjCBool = false
          if !FileManager.default.fileExists(atPath: pkgDirPath, isDirectory: &isDirectory) {
            try FileManager.default.createDirectory(at: pkgDir, withIntermediateDirectories: true)
          }

          let dest: URL
          if #available(macOS 13.0, *) {
            dest = pkgDir.appending(path: "\(res.classname).java")
          } else {
            dest = pkgDir.appendingPathComponent("\(res.classname).java")
          }

          try res.content.write(to: dest, atomically: true, encoding: .utf8)
          
        } else {
          print(res.content, "\n")
        }
      }
    }

    // let packageClass = generator.generatePackageClass()
    // try packageClass.write(to: filename(for: "\(package)_module"), atomically: true, encoding: .utf8)
  }
}
