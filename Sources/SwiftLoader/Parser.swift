import Basic
import Foundation
import SPMUtility

class Parser {
    let fileSystem: FileSystem
    init(fileSystem: FileSystem = localFileSystem) {
        self.fileSystem = fileSystem
    }
    
    func extractIncludes(from path: AbsolutePath) throws -> [String] {
        guard let contents = try fileSystem.readFileContents(path).validDescription else {
            return []
        }
        
        let pattern = #"""
        include\(\"(?<file>.+?)\"\)
        """#
        
        let regex = try NSRegularExpression(pattern: pattern, options: [])
        let range = NSRange(contents.startIndex..<contents.endIndex,
                            in: contents)
        let matches = regex.matches(in: contents, options: [], range: range)
        
        var foundIncludes = [String]()
        for match in matches {
            if match.numberOfRanges > 1,
               let matchRange = Range(match.range(at: 1), in: contents) {
                let include = contents[matchRange]
                foundIncludes.append(String(include))
            }
        }
        
        return foundIncludes
    }
}
