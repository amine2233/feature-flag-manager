import Foundation

public protocol AnyFeature {
    /// Childs
    func hierarchyfeatureFlags() -> [AnyFeature]

    /// Metadata associated.
    var metadata: FeatureFlagMetadata { get }
}
