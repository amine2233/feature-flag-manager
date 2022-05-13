import Foundation

// MARK: - EncodedFlagValue
/// Defines all the types you can encode/decode as flag value.
/// Custom type you conform to `FeatureFlagProtocol` must be able to be represented with one of the following types.
public enum EncodedFlagValue: Equatable {
    case array([EncodedFlagValue])
    case bool(Bool)
    case dictionary([String: EncodedFlagValue])
    case data(Data)
    case double(Double)
    case float(Float)
    case integer(Int)
    case none
    case string(String)
    case json(NSDictionary)
}

// MARK: - String Literal Support
/// It's used to initialize a new flag metadata directly with only the description string instead of
/// creating the `FeatureFlagMetadata` object.
extension FeatureFlagMetadata: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self.init(description: value, isInternal: false)
    }
}
