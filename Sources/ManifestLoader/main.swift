import Foundation
import SwiftLoader

print("> ManifestLoader <")

let loader = Loader()

do {
    let result = try loader.run(arguments: Array(CommandLine.arguments.dropFirst()))
    print(result)
} catch {
    print("Error: \(error.localizedDescription)")
    exit(1)
}



