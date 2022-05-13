//
//  File.swift
//  
//
//  Created by Amine Bensalah on 13/05/2022.
//

import Foundation


// MARK: - FeatureFlagsLoaderProtocol
/// Identify the basic properties of a `FeatureFlagLoader` instance.
public protocol FeatureFlagsLoaderProtocol: AnyObject {

    /// Ordered list of providers for data.
    var providers: [FeatureFlagsProvider]? { get }

    /// Defines how the automatic keypath for property is produced.
    var keyConfiguration: KeyConfiguration { get }

}

// MARK: - FeatureFlagConfigurableProtocol
public typealias KeyPathAndConfig = (path: String, keyConfiguration: KeyConfiguration?)

/// This is just an internal protocol used to initialize the contents of a collection or a flag
/// with a specific `FeatureFlagLoader` instance.
/// You should never use it.
public protocol FeatureFlagConfigurableProtocol {

    /// Configure class with specific loader.
    ///
    /// - Parameters:
    ///   - loader: loader instance.
    ///   - propertyName: property name.
    ///   - keyPath: keyPath components.
    func configureWithLoader(_ loader: FeatureFlagsLoaderProtocol, propertyName: String, keyPath: [KeyPathAndConfig])

}

/// `FeatureFlagsLoader` is used to fetch data for certain group of feature flags.
/// You will initialize a new loader with a certain type of group and an ordered
/// list of providers to query. Then you can fetch feature flag's values directly
/// by accessing to the relative properties from this instance via dynamic member lookup.
@dynamicMemberLookup
public class FeatureFlagsLoader<Collection: FeatureFlagCollectionProtocol>: FeatureFlagsLoaderProtocol, CustomDebugStringConvertible {

    // MARK: - Public Properties

    /// Collection of feature flag loaded.
    public private(set) var loadedCollection: Collection

    /// Providers where we'll get the data.
    public var providers: [FeatureFlagsProvider]?

    /// How to build automatically keys for each property of the group.
    public let keyConfiguration: KeyConfiguration

    /// Metadata associated with loaded flag collection.
    public var metadata: FeatureFlagMetadata?

    // MARK: - Initialization

    /// Initiali
    /// - Parameters:
    ///   - collection: type of collection to load. a new instance is made.
    ///   - metadata: optional metadata associated with the flag loader.
    ///   - providers: providers to use to fetch values. Providers are fetched in order.
    ///   - keysConfiguration: configuration
    public init (_ collectionType: Collection.Type,
                 description: FeatureFlagMetadata? = nil,
                 providers: [FeatureFlagsProvider]? = nil,
                 keyConfiguration: KeyConfiguration = .init()) {
        self.loadedCollection = collectionType.init()
        self.providers = providers
        self.keyConfiguration = keyConfiguration
        self.metadata = description
        initializeCollectionObjects()
    }

    // MARK: - Public Functions

    public var debugDescription: String {
        return "FlagLoader<\(String(describing: Collection.self))>("
        + Mirror(reflecting: loadedCollection).children
            .map { _, value -> String in
                (value as? CustomDebugStringConvertible)?.debugDescription
                ?? (value as? CustomStringConvertible)?.description
                ?? String(describing: value)
            }
            .joined(separator: "; ")
        + ")"
    }

    public lazy var featureFlags: [AnyFeatureFlag] = {
        return Mirror(reflecting: loadedCollection)
            .children
            .lazy
            .map { $0.value }
            .featureFlags()
    }()

    public lazy var hierarcyFeatureFlags: [AnyFeature] = {
        return Mirror(reflecting: loadedCollection)
            .children
            .lazy
            .map { $0.value }
            .hierarchyFeatureFlags()
    }()

    // MARK: - dynamicMemberLookup Support

    public subscript<Value>(dynamicMember dynamicMember: KeyPath<Collection, Value>) -> Value {
        return loadedCollection[keyPath: dynamicMember]
    }

    // MARK: - Private Methods

    private func initializeCollectionObjects() {
        let fFlagsProperties = Mirror(reflecting: loadedCollection).children.lazy.featureFlagsConfigurableProperties()
        for property in fFlagsProperties {
            property.value.configureWithLoader(self, propertyName: property.label, keyPath: [])
        }
    }

}

// MARK: - KeyConfiguration
public struct KeyConfiguration {

    /// Global prefix to append at the beginning of a key.
    public let globalPrefix: String?

    /// Transformation to apply for each path component.
    public let keyTransform: String.Transform

    /// Path separator, by default is `/`
    public let pathSeparator: String

    public init(prefix: String? = nil, pathSeparator: String = FeatureFlagKeyPath.DefaultPathSeparator, keyTransform: String.Transform = .snakeCase) {
        self.globalPrefix = prefix
        self.keyTransform = keyTransform
        self.pathSeparator = pathSeparator
    }

}
