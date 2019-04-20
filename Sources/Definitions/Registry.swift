import Foundation

public func register<T: Encodable>(_ item: T) {
    if CommandLine.arguments.contains("--dump") {
        dump(item)
    }
}

private func dump<T: Encodable>(_ item: T) {
    guard let data = try? JSONEncoder().encode(item),
        let string = String(data: data, encoding: .utf8) else {
            return
    }
    print(string)
}

