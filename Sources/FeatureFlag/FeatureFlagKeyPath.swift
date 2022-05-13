import Foundation

public struct FeatureFlagKeyPath: Equatable, Hashable {

    public static let DefaultPathSeparator = "/"

    // MARK: - Public Properties

    /// Components of the key to retrive.
    public var pathComponents: [String]

    /// Separator set.
    public let pathSeparator: String

    public var fullPath: String {
        pathComponents.joined(separator: pathSeparator)
    }

    var key: String {
        pathComponents.last ?? ""
    }

    public var count: Int {
        pathComponents.count
    }

    public var first: String? {
        pathComponents.first
    }

    public var last: String? {
        pathComponents.last
    }

    public subscript(_ index: Int) -> String? {
        guard index >= 0, index < pathComponents.count else {
            return nil
        }

        return pathComponents[index]
    }

    @discardableResult
    public func dropFirst() -> FeatureFlagKeyPath {
        return FeatureFlagKeyPath(components: Array(pathComponents.dropFirst()), separator: pathSeparator)
    }

    public var isEmpty: Bool {
        pathComponents.isEmpty
    }

    // MARK: - Initialization

    internal init(components: [String], separator: String) {
        self.pathComponents = components
        self.pathSeparator = separator
    }

}
