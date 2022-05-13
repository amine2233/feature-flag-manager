import Foundation
import FeatureFlag

// MARK: - DelegateProviderProtocol
public protocol DelegateProviderProtocol: AnyObject {

    /// Get the value for a specified key.
    ///
    /// - Parameter key: key
    func valueForFlag<Value>(key: FeatureFlagKeyPath) -> Value? where Value: FeatureFlagProtocol

    /// Set value for specified key.
    ///
    /// - Parameters:
    ///   - value: value.
    ///   - key: key.
    func setValue<Value>(_ value: Value?, forFlag key: FeatureFlagKeyPath) throws -> Bool where Value: FeatureFlagProtocol

    /// Reset the value for a specified key.
    func resetValueForFlag(_ key: FeatureFlagKeyPath) throws

}

// MARK: - DelegateProvider
public class DelegateProvider: FeatureFlagsProvider, Identifiable {

    // MARK: - Public Properties

    /// Delegate of the messages.
    public weak var delegate: DelegateProviderProtocol?

    /// Name of the provider.
    public var name: String

    /// Short description of the provider
    public var shortDescription: String? = "Delegate Provider"

    /// Supports writable data?
    public var isWritable: Bool = true

    // MARK: - Initialization

    public init(name: String = UUID().uuidString) {
        self.name = name
    }

    // MARK: - Required Methods

    public func valueForFlag<Value>(key: FeatureFlagKeyPath) -> Value? where Value: FeatureFlagProtocol {
        delegate?.valueForFlag(key: key)
    }

    public func setValue<Value>(_ value: Value?, forFlag key: FeatureFlagKeyPath) throws -> Bool where Value: FeatureFlagProtocol {
        guard isWritable else {
            return false
        }

        return try delegate?.setValue(value, forFlag: key) ?? false
    }

    public func resetValueForFlag(key: FeatureFlagKeyPath) throws {
        try delegate?.resetValueForFlag(key)
    }

}
