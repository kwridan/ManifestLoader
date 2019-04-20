import Basic
import Foundation
import SPMUtility

public enum SwiftLoaderError: Error, LocalizedError {
    case faildToLoad(String)
    public var errorDescription: String? {
        switch self {
        case let .faildToLoad(error):
            return error
        }
    }
}

public class SwiftLoader {
    private let fileSystem: FileSystem
    private let modules: [String]
    private let searchPaths: [String]
    
    public init(modules: [String],
                searchPaths: [String] = [],
                fileSystem: FileSystem = localFileSystem) {
        self.modules = modules
        self.searchPaths = searchPaths
        self.fileSystem = fileSystem
    }
    
    public func run(mainFile: AbsolutePath,
                    additionalFiles: [AbsolutePath],
                    arguments: [String]) throws -> String {
        let temporaryDirectory = try TemporaryDirectory(removeTreeOnDeinit: true)
        let temporaryPath = temporaryDirectory.path
        
        let paths = try copy(mainFile: mainFile,
                             additionalFiles: additionalFiles,
                             to: temporaryPath)
        
        let binaryPath = temporaryPath.appending(component: "temp_binary.o")
        try compile(files: paths, output: binaryPath)
        
        return try run(binaryPath: binaryPath,
                       arguments: arguments)
    }
    
    private func compile(files: [AbsolutePath: AbsolutePath], output: AbsolutePath) throws {
        let defaultSearchPath = derrivedDataPath()
        let allSearchPaths = [defaultSearchPath] + searchPaths
        var arguments: [String] = [
            "swiftc",
            "-emit-executable",
            "-suppress-warnings",
        ]
        arguments.append(contentsOf: allSearchPaths.map { "-I\($0)" })
        arguments.append(contentsOf: allSearchPaths.map { "-L\($0)" })
        arguments.append(contentsOf: allSearchPaths.map { "-F\($0)" })
        arguments.append(contentsOf: modules.flatMap {
            moduleIncludeLine(name: $0, searchPaths: allSearchPaths)
        })

        arguments.append(contentsOf: ["-o", output.pathString])
        arguments.append(contentsOf: ["-Xlinker", "-rpath"])
        arguments.append(contentsOf: allSearchPaths.flatMap { ["-Xlinker", $0] })
        arguments.append(contentsOf: files.keys.map { $0.pathString })
        
        let process = Process(arguments: arguments)
        try process.launch()
        let result = try process.waitUntilExit()
        
        guard result.exitStatus == .terminated(code: 0) else {
            let error = try result.utf8stderrOutput()
            let correctedError = replaceTemporaryPathsWithOriginal(paths: files,
                                                                   in: error)
            throw SwiftLoaderError.faildToLoad(correctedError)
        }
    }
    
    private func run(binaryPath: AbsolutePath, arguments: [String]) throws -> String {
        return try Process.checkNonZeroExit(arguments: [binaryPath.pathString] + arguments)
    }
    
    private func moduleIncludeLine(name: String, searchPaths: [String]) -> [String] {
        // Search for .dylib
        let dylib = searchPaths.first(where: {
            fileSystem.exists(AbsolutePath($0).appending(component: "lib\(name).dylib"))
        })
        
        if dylib != nil {
            return ["-l\(name)"]
        }
        
        // Search for .framework
        let framework = searchPaths.first(where: {
            fileSystem.exists(AbsolutePath($0).appending(component: "\(name).framework"))
        })
        
        if framework != nil {
            return ["-framework", name]
        }
        
        return []
    }
    
    private func derrivedDataPath() -> String {
        let bundlePath = Bundle(for: SwiftLoader.self).bundleURL.path
        let path = AbsolutePath(bundlePath)
        if path.basename.hasSuffix(".framework") {
            return path.parentDirectory.pathString
        }
        return path.pathString
    }
    
    private func copy(mainFile: AbsolutePath,
                      additionalFiles: [AbsolutePath],
                      to temporaryDirectory: AbsolutePath) throws -> [AbsolutePath: AbsolutePath] {
        var pathsMapping = Dictionary(uniqueKeysWithValues: additionalFiles.map {
            (temporaryDirectory.appending(component: $0.basename), $0)
        })
        
        pathsMapping[temporaryDirectory.appending(component: "main.swift")] = mainFile
        
        try pathsMapping.forEach { temporary, original in
            try fileSystem.copy(source: original, destination: temporary)
        }
        
        return pathsMapping
    }
    
    private func replaceTemporaryPathsWithOriginal(paths: [AbsolutePath: AbsolutePath],
                                                   in error: String) -> String {
        return paths.reduce(error) { error, pathMap in
                error.replacingOccurrences(of: pathMap.key.pathString,
                                           with: pathMap.value.pathString)
        }
    }
}

extension FileSystem {
    func copy(source: AbsolutePath, destination: AbsolutePath) throws {
        let contents = try readFileContents(source)
        try writeFileContents(destination, bytes: contents)
    }
}
