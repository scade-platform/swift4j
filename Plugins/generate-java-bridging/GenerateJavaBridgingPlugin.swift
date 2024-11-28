import PackagePlugin
import Foundation



@main
struct GenerateJavaBridgingPlugin: CommandPlugin {
  func performCommand(context: PluginContext, arguments: [String]) throws {
    let toolPath = try URL(filePath: context.tool(named: "swift4j").path.string)
    let outputDir = context.pluginWorkDirectory

    var argExtractor = ArgumentExtractor(arguments)
    let prodNames = argExtractor.extractOption(named: "product")

    let products = prodNames.isEmpty
    ? context.package.products
    : try context.package.products(named: prodNames)

    for prod in products  {
      try sourceModules(from: prod).forEach {
        print("Generating bridging for '\($0.moduleName)'...")
        try generate(for: $0, 
                     with: toolPath,
                     to: outputDir.appending(prod.name),
                     forwardArgs: argExtractor.remainingArguments)
      }
    }
  }

  private func generate(for sourceModule: any SourceModuleTarget, 
                        with toolPath: URL,
                        to outputDir: PackagePlugin.Path,
                        forwardArgs args: [String]) throws {

    let pkgName = sourceModule.name.replacingOccurrences(of: "-", with: "_")
    let outPath = outputDir.appending(["main", "java"]).string

    if FileManager.default.fileExists(atPath: outPath) {
      try FileManager.default.removeItem(atPath: outPath)
    }

    try FileManager.default.createDirectory(at: URL(filePath: outPath), withIntermediateDirectories: true)
    
    let arguments = args
      + ["-o", outPath, "--package", pkgName]
      + sourceModule.sourceFiles.map{ $0.path.string }.filter{$0.hasSuffix(".swift")}

    try Process.run(toolPath, arguments: arguments)
  }

  private func sourceModules(from product: any Product) -> [any SourceModuleTarget] {
    func traverseSourceModules(_ target: any SourceModuleTarget, modules: inout [any SourceModuleTarget], processed: inout Set<String>) {
      guard !processed.contains(target.id) else { return }

      modules.append(target)
      processed.insert(target.id)

      target.dependencies.forEach {
        switch $0 {
        case .target(let t):
          if let sm = t.sourceModule {
            traverseSourceModules(sm, modules: &modules, processed: &processed)
          }
        default:
          return
        }
      }
    }

    var modules = [any SourceModuleTarget]()
    var processed = Set<String>()

    product.sourceModules.forEach {
      traverseSourceModules($0, modules: &modules, processed: &processed)
    }

    return modules

  }
}
