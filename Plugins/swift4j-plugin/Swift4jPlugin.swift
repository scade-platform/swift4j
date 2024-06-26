import Foundation
import PackagePlugin

@main
struct Swift4jPlugin: BuildToolPlugin {
  func createBuildCommands(context: PluginContext, target: Target) throws -> [Command] {
    guard let target = target.sourceModule else { return [] }
    
    let outputDir = context.pluginWorkDirectory.appending("GeneratedFiles")
    
    let inputFiles = target.sourceFiles.filter{ $0.path.extension == "swift" }.map{ $0.path }
    let outputFiles = [outputDir.appending(target.name + "_module.java")]

    let args = ["--outdir", outputDir.string, "--package", target.name] + inputFiles.map{ $0.string }

    return [.buildCommand (
      displayName: "Generating Java proxies for \(target.name)",
      executable: try context.tool(named: "swift4j").path,
      arguments: args,
      inputFiles: inputFiles,
      outputFiles: outputFiles
    )]
  }
}

