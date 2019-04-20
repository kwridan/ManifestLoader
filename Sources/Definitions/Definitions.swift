
public struct Project: Codable {
    public var name: String
    public init(name: String) {
        self.name = name
        register(self)
    }
}
