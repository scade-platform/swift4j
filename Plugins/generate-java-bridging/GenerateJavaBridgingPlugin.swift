import PackagePlugin
import Foundation



@main
struct GenerateJavaBridgingPlugin: CommandPlugin {

  func performCommand(context: PluginContext, arguments: [String]) throws {
    let toolPath = try URL(filePath: context.tool(named: "swift4j-cli").path.string)
    let outputDir = context.pluginWorkDirectory

    var argExtractor = ArgumentExtractor(arguments)
    let prodNames = argExtractor.extractOption(named: "product")
    let copyJavaSources = argExtractor.extractFlag(named: "copy-java-sources") > 0

    let products = prodNames.isEmpty
      ? context.package.products
      : try context.package.products(named: prodNames)
    
    for prod in products  {
      try prod.targets.flatMap{$0.recursiveTargetSourceModules()}.forEach {
        print("Generating bridging for '\($0.moduleName)'...")
        try generate(for: $0, 
                     with: toolPath,
                     to: outputDir.appending(prod.name),
                     forwardArgs: argExtractor.remainingArguments,
                     copyJavaSources: copyJavaSources)

      }
    }
  }

  private func generate(for sourceModule: any SourceModuleTarget, 
                        with toolPath: URL,
                        to outputDir: PackagePlugin.Path,
                        forwardArgs args: [String],
                        copyJavaSources: Bool = false) throws {

    let pkgsOutDir = outputDir.appending(["main", "java"])

    let pkgName = sourceModule.name.replacingOccurrences(of: "-", with: "_")
    let pkgOutPath = pkgsOutDir.string

    if FileManager.default.fileExists(atPath: pkgOutPath) {
      try FileManager.default.removeItem(atPath: pkgOutPath)
    }

    try FileManager.default.createDirectory(at: URL(filePath: pkgOutPath), withIntermediateDirectories: true)

    let arguments = args
      + ["-o", pkgOutPath, "--package", pkgName]
      + sourceModule.sourceFiles.map{ $0.path.string }.filter{$0.hasSuffix(".swift")}

    try Process.run(toolPath, arguments: arguments)

    if copyJavaSources {
      try self.copyJavaSources(from: sourceModule, to: pkgsOutDir)
    }
  }

  private func copyJavaSources(from sourceModule: any SourceModuleTarget,
                               to outputDir: PackagePlugin.Path) throws {

    let javaSources = sourceModule.recursiveTargetSourceModules(followProducts: true).flatMap {
      $0.sourceFiles.filter { srcFile in
        srcFile.type == .resource && srcFile.path.string.hasSuffix(".java")
      }
    }
    
    try javaSources.forEach {
      if let pkgName = try? javaPackageName(from: $0.path) {
        let outPath = outputDir.appending(pkgName.split(separator: ".").map(String.init))

        try FileManager.default.createDirectory(at: URL(filePath: outPath.string), withIntermediateDirectories: true)
        try FileManager.default.copyItem(atPath: $0.path.string, toPath: outPath.appending($0.path.lastComponent).string)
      }
    }

  }

  private func javaPackageName(from path: Path) throws -> String? {
    let fileURL = URL(fileURLWithPath: path.string)
    let fileContents = try String(contentsOf: fileURL, encoding: .utf8)

    let pattern = #"package\s+([a-zA-Z_][\w]*(?:\.[a-zA-Z_][\w]*)*);"#

    guard let regex = try? Regex(pattern),
          let match = fileContents.firstMatch(of: regex),
          let packageName = match.output[1].substring else { return nil }

    return String(packageName)
  }

}


extension Target {
  func recursiveTargetSourceModules(followProducts: Bool = false) -> [any SourceModuleTarget] {
    var modules = [any SourceModuleTarget]()
    var processed = Set<String>()

    func process(_ target: any Target) {
      guard !processed.contains(target.id) else { return }

      if let sm = target.sourceModule {
        modules.append(sm)
        processed.insert(target.id)

        sm.dependencies.forEach(traverse)
      }
    }

    func traverse(_ dep: TargetDependency) {
      switch dep {
      case .target(let target):
        // print("Target: \(target.name)")
        process(target)

      case .product(let prod):
        guard followProducts else { return }
        // print("Product: \(prod.name)")
        prod.targets.forEach(process)
        
      default:
        return
      }
    }
    
    process(self)

    return modules
  }
}
