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
    let generator = ProxyGenerator(package: package)

    for p in paths {
      for res in try generator.run(path: p) {
        try res.content.write(to: filename(for: res.classname), atomically: true, encoding: .utf8)
      }
    }

    let packageClass = generator.generatePackageClass()
    try packageClass.write(to: filename(for: "\(package)_module"), atomically: true, encoding: .utf8)
  }

  func filename(for classname: String) -> URL {
    var outpath: String
    if let outdir = outdir {
      outpath = outdir
    } else {
      outpath = FileManager.default.currentDirectoryPath
    }
    return URL(fileURLWithPath: "\(outpath)/\(classname).java" )
  }

}
