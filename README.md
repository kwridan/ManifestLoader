# Manifest Loader

A proof of concept Swift manifest loader that allows inclusion of additional Swift files that provide helper methods.

A manifest in this context is a standalone Swift file that allows defining properties or settings that can be loaded by command line tools. 

Examples:

- `Package.swift` in Swift PM
- `Project.swift` in Tuist
- `Dangerfile.swift` in Danger Swift

# Usage

This is a proof of concept as such isn't designed to be used by other tools just yet. 
It may contain redundant non-optimized code. 

# Testing

A few examples have been placed within the `Fixtures` directory

```swift
swift build
swift run loader $(pwd)/Fixtures/Sample/Project.swift
swift run loader $(pwd)/Fixtures/SampleWithHelper/Project.swift
```

Notes: You will need to have Swift 5 runtime installed (comes pre-installed on macOS 10.14.14+)

# How it usually works

The DSL of the manifest is hosted within a definition module (e.g. `PackageDescription` for Swift PM) which can be imported in a standalone file (e.g. `Package.swift`). The standalone file can then reference and use any public methods or types declared within the definitions module.

The loading process in command line tools is commonly achieved by the following steps:

- Compile & run the manifest file (including the appropriate search paths to the definitions module)
- Capture / Parse the output as needed

A neat technique to simplify the parsing step is by making all definitions `Codable`. This allows the first step to dump out a serialized version of the manifest (in JSON for example) which can then be deserialzied in the second step back to the same concrete types within the command line tool.

# Supporting includes

Importing single files isn't supported by Swift (e.g. `import MyHelper.swift`), as such a few additional steps are needed to add some level of support for it.

To ensure the manifest file is syntactically and semantically correct, in this proof of concept, a new top-level function `include` is introduced to the `Definitions` module. 

```swift
import Definitions

include("Helpers.swift")

// ...
```

The goal is be able to reference any code within `Helpers.swift` as one would when compiling a module that contains both files (the manifest and `Helpers.swift`).

The manifest loading process can then take the following steps:

- Parse the manifest file to extract all files references in `include` statements
- Create a temporary directory
- Copy all referenced include files to it
- Copy the manifest file to the temporary directory as `main.swift`
- Compile all the files within the temporary directory (including the appropriate search paths to the definitions module)
- Run the generated executable
- Capture / Parse the output as needed

In the event errors occur during this process, replace the temporary paths with the original ones within the error message.

Note: For this proof of concept, the extraction of includes was achieved via regex. A more reliable technique would be to use [`SwiftSyntax`](https://github.com/apple/swift-syntax).

# Thoughts

This is an interesting concept however comes with added complexity and possibly a performance penalty due to the extra steps needed.

For Swift PM for example, such a technique is an overkill especially as there is only one `Package.swift` manifest and as such there wouldn't be a need to share helpers between manifests. In Tuist however (an Xcode project generator tool) a workspace can contain several projects each with their own `Project.swift` manifest and having helpers to reduce certain repetitive boilerplate can be appealing.

That said, even for the cases where it might be useful, it does introduce new challenges that would require even more complexity to solve. 

For example, in Tuist, one of the features which could benefit from including helpers is sharing configuration settings. These settings can include paths to xcconfig files. Paths are always relative in Tuist, as such having them declared in a helper file which is shared between several projects in different directory structures wouldn't achieve the desired results.

```
- Applications
  - AppA
  - AppB
- Frameworks
  - Subdirectory
    - FrameworkA
    - FrameworkB
  - FrameworkC 
- Configurations
  - ConfigA.xcconfig
  - ConfigB.xcconfig
- Configurations.swift
```

```swift
import ProjectDescription

let sharedConfigurations = [
    // This path is only valid from the perspective of `Configurations.swift`
    // but not any other manifest that includes it
    .debug(xcconfig: "Configruations/ConfigA.xcconfig")  
]
```

# Credit

This proof of concept is based on the techniques used by [Swift PM](https://github.com/apple/swift-package-manager), [swift-sh](https://github.com/mxcl/swift-sh), [Tuist](https://github.com/tuist/tuist) and others. It simply builds on top of those existing concepts to explore the idea of including local standalone Swift files. 

Thanks to [@marciniwanicki](https://github.com/marciniwanicki) for collaborating on the prototyping of this concept.
