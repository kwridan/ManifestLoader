import Basic
import Foundation
import SPMUtility

enum LoaderError: Error, LocalizedError {
    case pathNotSet
    
    var errorDescription: String? {
        switch self {
        case .pathNotSet:
            return "Path was not specified"
        }
    }
}

public class Loader {
    public init() {
        
    }
    
    public func run(arguments: [String]) throws -> String {
        let path = try extractPath(from: arguments)
        
        let parser = Parser()
        let incldues = try parser.extractIncludes(from: path)
        
        let swiftLoader = SwiftLoader(modules: ["Definitions"])
        let additionalFiles = incldues.map { path.parentDirectory.appending(RelativePath($0)) }
        let result = try swiftLoader.run(mainFile: path,
                                         additionalFiles: additionalFiles,
                                         arguments: ["--dump"])
        return result
    }
    
    private func extractPath(from arguments: [String]) throws -> AbsolutePath {
        guard let path = arguments.first else {
            throw LoaderError.pathNotSet
        }
        
        return AbsolutePath(path)
    }
}
