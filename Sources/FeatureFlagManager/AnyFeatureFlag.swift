//
//  File.swift
//  
//
//  Created by Amine Bensalah on 13/05/2022.
//

import Foundation

public protocol AnyFeatureFlag: AnyFeature {
    /// Name of the flag
    var name: String { get }

    /// Description of the flag.
    var description: String { get }

    /// Return the key for flag.
    var keyPath: FeatureFlagKeyPath { get }

    /// Description of data type represented.
    var readableDataType: String { get }

    /// Data type for flag.
    var dataType: Any.Type { get }

    /// Metadata for flag.
    var metadata: FeatureFlagMetadata { get }

    /// Associated providers.
    var providers: [FeatureFlagsProvider] { get }

    /// Allowed provider.
    var excludedProviders: [FeatureFlagsProvider.Type]? { get }

    /// Has an associated writable provider.
    var hasWritableProvider: Bool { get }

    /// Description of the flag.
    var defaultFallbackValue: Any? { get }

    /// Return the value of the flag.
    ///
    /// - Parameter providerType: you can specify a particular provider to query; otherwise standard's flag behaviour is applied.
    func getValueForFlag(from providerType: FeatureFlagsProvider.Type?) -> Any?

    /// Get a readable description of the value.
    ///
    /// - Parameter providerType: you can specify a particular provider to query; otherwise standard's flag behaviour is applied.
    func getValueDescriptionForFlag(from providerType: FeatureFlagsProvider.Type?) -> (value: String, sourceProvider: FeatureFlagsProvider?)

    /// Save a value to a provider (if supported).
    ///
    /// - Parameter provider: provider to use.
    func setValueToProvider(_ provider: FeatureFlagsProvider) throws

    /// Change the default fallback value.
    /// Value must be of the same type of the FeatureFlag inner implementation.
    func setDefaultValue(_ value: Any) throws
}

extension AnyFeatureFlag {

    var readableDefaultFallbackValue: String {
        guard let val = defaultFallbackValue else {
            return "<null>"
        }

        return String(describing: val)
    }
}

// MARK: - AnyFeatureFlag (Flag Conformance)
extension FeatureFlag: AnyFeatureFlag {
    public func hierarchyfeatureFlags() -> [AnyFeature] {
        []
    }

    public func setDefaultValue(_ value: Any) throws {
        guard let value = value as? Value else {
            fatalError("Error is not of the same type as expected: \(String(describing: value))")
        }

        setDefault(value)
    }

    public var defaultFallbackValue: Any? {
        defaultValue
    }

    public var hasWritableProvider: Bool {
        guard !isUILocked else { return false }

        return providers.first(where: { $0.isWritable }) != nil
    }

    public var isUILocked: Bool {
        metadata.isLocked
    }

    public func hierarchyFeatureFlags() -> [AnyFeature] {
        []
    }

    public var dataType: Any.Type {

        func isOptional(_ instance: Any) -> Bool {
            let mirror = Mirror(reflecting: instance)
            let style = mirror.displayStyle
            return style == .optional
        }

        if isOptional(wrappedValue) {
            // swiftlint:disable force_unwrapping
            return wrappedTypeFromOptionalType(type(of: wrappedValue.self))!
        } else {
            return type(of: wrappedValue.self)
        }
    }

    public var providers: [FeatureFlagsProvider] {
        loader.instance?.providers ?? []
    }

    public var readableDataType: String {
        String(describing: dataType)
    }

    public func getValueForFlag(from providerType: FeatureFlagsProvider.Type? = nil) -> Any? {
        flagValue(from: providerType).value
    }

    public func getValueDescriptionForFlag(from providerType: FeatureFlagsProvider.Type? = nil) -> (value: String, sourceProvider: FeatureFlagsProvider?) {

        let result = flagValue(from: providerType)
        guard let value = result.value else {
            return (readableDefaultFallbackValue, nil)
        }

        return (String(describing: value), result.source)
    }

    public var name: String {
        metadata.name ?? loader.propertyName
    }

    public var description: String {
        metadata.description
    }

    public func setValueToProvider(_ provider: FeatureFlagsProvider) throws {
        try provider.setValue(self.wrappedValue, forFlag: keyPath)
    }

}
