import Foundation

public protocol AnyFeatureFlagCollection: AnyFeature {
    /// Return the list of all feature flags of the collection.
    func featureFlags() -> [AnyFeatureFlag]

    /// Name of the collection.
    var name: String { get }

    /// Description of the flag collection.
    var description: String { get }
}

extension FeatureFlagCollection: AnyFeatureFlagCollection {
    public func hierarchyfeatureFlags() -> [AnyFeature] {
        []
    }


    public var name: String {
        metadata.name ?? loader.propertyName
    }

    public var description: String {
        metadata.description
    }

    public func featureFlags () -> [AnyFeatureFlag] {
        Mirror(reflecting: wrappedValue)
            .children
            .lazy
            .map { $0.value }
            .compactMap { element -> [AnyFeatureFlag]? in
                if let flag = element as? AnyFeatureFlag {
                    return [flag]
                } else if let group = element as? AnyFeatureFlagCollection {
                    return group.featureFlags()
                } else {
                    return nil
                }
            }
            .flatMap { $0 }
    }

    public func hierarchyFeatureFlags() -> [AnyFeature] {
        Mirror(reflecting: wrappedValue)
            .children
            .lazy
            .map { $0.value }
            .compactMap { element -> [AnyFeature]? in
                if let flag = element as? AnyFeatureFlag {
                    return [flag]
                } else if let group = element as? AnyFeatureFlagCollection {
                    return group.hierarchyfeatureFlags()
                } else {
                    return nil
                }
            }
            .flatMap { $0 }
    }

}

internal extension Sequence {

    func hierarchyFeatureFlags() -> [AnyFeature] {
        self.compactMap { element -> [AnyFeature]? in
            if let flag = element as? AnyFeatureFlag {
                return [flag]
            } else if let group = element as? AnyFeatureFlagCollection {
                return [group]
            } else {
                return nil
            }
        }
        .flatMap { $0 }
    }

    func featureFlags() -> [AnyFeatureFlag] {
        self.compactMap { element -> [AnyFeatureFlag]? in
            if let flag = element as? AnyFeatureFlag {
                return [flag]
            } else if let group = element as? AnyFeatureFlagCollection {
                return group.featureFlags()
            } else {
                return nil
            }
        }
        .flatMap { $0 }
    }

}
