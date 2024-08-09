import PackagePlugin
import Foundation

@main
struct GenerateJavaBridgingPlugin: CommandPlugin {
  func performCommand(context: PluginContext, arguments: [String]) throws {
    let toolPath = try URL(filePath: context.tool(named: "swift4j").path.string)
    let outputDir = context.pluginWorkDirectory

    
    for prod in context.package.products {
      let prodOutputDir = outputDir.appending(prod.name).string

      var isDirectory: ObjCBool = false
      if !FileManager.default.fileExists(atPath: prodOutputDir, isDirectory: &isDirectory) {
        try FileManager.default.createDirectory(at: URL(filePath: prodOutputDir), withIntermediateDirectories: false)
      }

      let prodSrcMods = prod.sourceModules.flatMap {
        [$0] + $0.recursiveTargetDependencies.compactMap{ dep in dep.sourceModule }
      }

      var processed = Set<String>()
      
      for srcMod in prodSrcMods {
        guard !processed.contains(srcMod.id) else { continue }
        try generate(for: srcMod, with: toolPath, to: prodOutputDir)
        processed.insert(srcMod.id)
      }
    }
  }
  
  private func generate(for sourceModule: any SourceModuleTarget, with toolPath: URL, to outputDir: String) throws {
    try Process.run(toolPath, arguments: [
      "-o", outputDir,
      "--package", sourceModule.name
    ] + sourceModule.sourceFiles.map{ $0.path.string }.filter{$0.hasSuffix(".swift")})
  }
}
