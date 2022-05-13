import Foundation

/// Consider `FeatureFlagsManager` as an object used to contain all the laoders of feature flag.
/// It's an optional object you can use at your convenience (you can still instantiate and store your own
/// `FeatureFlagsLoader` instances without needing of this object).
public class FeatureFlagsManager {

    // MARK: - Public Properties

    /// Default providers for flags loader
    public let providers: [FeatureFlagsProvider]

    /// Default key configuration.
    public let keyConfiguration: KeyConfiguration

    /// Currently loaders.
    public private(set) var loaders = [String: AnyFeatureFlagsLoader]()

    // MARK: - Initialization

    /// Initialize a new flags manager with a specified ordered list of providers and configuration.
    ///
    /// - Parameters:
    ///   - providers: providers to use. This value is used for each new loader created via this manager.
    ///                You can still get values only for certain provider only with the custom methods in `FeatureFlags` instance.
    ///   - keyConfiguration: key configuration.
    public init(providers: [FeatureFlagsProvider], keyConfiguration: KeyConfiguration = .init()) {
        self.providers = providers
        self.keyConfiguration = keyConfiguration
    }

    // MARK: - Public Functions

    /// Load a collection of feature flag and keep inside.
    /// NOTE: If you have already a loader for this kind of data it will be replaced!
    ///
    /// - Parameter type: type of `FeatureFlagCollectionProtocol` conform object to instantiate.
    /// - Returns: the relative loader.
    @discardableResult
    public func addCollection<Collection: FeatureFlagCollectionProtocol>(_ type: Collection.Type) -> FeatureFlagsLoader<Collection> {
        let flagLoader = FeatureFlagsLoader(type, providers: providers, keyConfiguration: keyConfiguration)
        let id = String(describing: type)
        loaders[id] = flagLoader
        return flagLoader
    }

    /// Remove the loader instance for certain type of object.
    ///
    /// - Parameter type: type of collection.
    public func removeCollection<Collection: FeatureFlagCollectionProtocol>(forType type: Collection.Type) {
        let id = String(describing: type)
        loaders.removeValue(forKey: id)
    }

    /// Get the loader for certain type of collection.
    ///
    /// - Parameter type: type of collection.
    /// - Returns: FeatureFlagsLoader<Collection>
    public func loader<Collection: FeatureFlagCollectionProtocol>(forType type: Collection.Type) -> FeatureFlagsLoader<Collection>? {
        let id = String(describing: type)
        guard let loader = loaders[id] as? FeatureFlagsLoader<Collection> else {
            return nil
        }

        return loader
    }
}
