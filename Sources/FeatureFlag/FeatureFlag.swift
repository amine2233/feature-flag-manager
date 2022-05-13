import Foundation

/// A type that represents the wrapped value of a `FeatureFlag`
///
/// This type exists solely so we can provide hints for boxing/unboxing or encoding/decoding
/// into various `FeatureFlagsProvider`s.
public protocol FeatureFlagProtocol {

    /// Defines the type of encoded type used to represent the flag value.
    /// For `Codable` support, a default boxed type of `Data` is assumed if you
    /// do not specify one directly.
    associatedtype EncodedValue = Data

    /// You must be able to decode your conforming object in order to unbox it.
    /// Return `nil` if you fails to decode.
    ///
    /// - Parameter encoded: encoded value.
    init?(encoded value: EncodedFlagValue)

    /// You must be able to encode a type to the relative `EncodedFlagValue` instance.
    func encoded() -> EncodedFlagValue
}

// MARK: - FeatureFlag

/// This a wrapper which represent a single Feature Flag.
/// The type that you wrap with `@Flag` must conform to `FeatureFlagProtocol`.
@propertyWrapper
public struct FeatureFlag<Value: FeatureFlagProtocol>: FeatureFlagConfigurableProtocol, Identifiable, CustomDebugStringConvertible {

    public typealias ComputedFlagClosure = (() -> Value?)

    private class DefaultValueBox<Value> {
        var value: Value?
    }

    // MARK: - Public Properties

    /// Unique identifier of the feature flag.
    public var id = UUID()

    /// The default value for this flag; this value is used when no provider can obtain the
    /// value you are requesting. Consider it as a fallback.
    public var defaultValue: Value {
        defaultValueBox.value!
    }

    /// The value associated with flag; if specified it will be get by reading the value of the provider, otherwise
    /// the `defaultValue` is used instead.
    public var wrappedValue: Value {
        flagValue().value ?? defaultValue
    }

    /// A reference to the `FeatureFlag` itself is available as a projected value
    /// so you can access to all associated informations.
    public var projectedValue: FeatureFlag<Value> {
        self
    }

    /// If specified you can attach a dynamic closure which may help you to compute the value of of the
    /// flag. This can be useful when your flags depend from other static or runtime-based values.
    /// This value is computed before any provider; if returned value is `nil` the library continue
    /// asking to the other providers; if you provide a non `nil` value no other provider are queried.
    ///
    /// DISCUSSION:
    /// This is a short example where the `computedValue` can be useful; the property `hasPublishButton`
    /// depend by the language of the app set, which is a runtime dynamic property:
    ///
    /// This is the definition of the flags:
    ///
    ///```swift
    /// public struct MiscFlags: FeatureFlagCollectionProtocol {
    ///
    ///     @Flag(default: false, computedValue: MiscFlags.computedPublishButton, description: "")
    ///     var hasPublishButton: Bool

    ///     public init() { }
    ///
    ///     private static func computedPublishButton() -> Bool? {
    ///         Language.main.code == "it"
    ///     }
    /// }
    /// ```
    ///
    /// You can create a custom private static function inside the struct in other to bloat the @Flag definition.
    public var computedValue: ComputedFlagClosure?

    /// This is the full keypath which will be send to the associated providers to get the value
    /// of the feature flag. It's composed according to the `FeatureFlagLoader`'s configuration.
    /// If you need to override the behaviour by setting your own key pass `key` to init function.
    public var keyPath: FeatureFlagKeyPath {
        // swiftlint:disable force_unwrapping
        let currentKeyPath = (fixedKey ?? loader.propertyName,
                              (fixedKey == nil ? loader.instance!.keyConfiguration : KeyConfiguration(keyTransform: .none)))
        let fullPath: [KeyPathAndConfig] = loader.propertyPath + [currentKeyPath]
        return loader.generateKeyPath(fullPath)
    }

    /// Metadata information associated with the flag.
    /// Typically is a way to associated a context to the flag in order to be fully documented.
    public var metadata: FeatureFlagMetadata

    /// You can exclude from the fetch of the loader a certain list of provider types
    /// (for example a particular property should be fetched only from UserDefaults and not from Firebase).
    /// If you need of this feature you should set their types here; if `nil` it will use the order specified
    /// by the `FeatureFlagsLoader` instance which create the instance.
    public var excludedProviders: [FeatureFlagsProvider.Type]?

    // MARK: - Private Properties

    /// The loader used to retrive the fetched value for property flags.
    /// This value is assigned when the instance of the FeatureFlag is created and it set automatically
    /// by the `configureWithLoader()` function.
    internal private(set) var loader = LoaderBox()

    /// You can force a fixed key for a property instead of using auto-evaluation.
    private var fixedKey: String?

    /// This is necessary in order to avoid mutable box.
    private var defaultValueBox = DefaultValueBox<Value>()

    // MARK: - Initialization

    /// Initialize a new feature flag property.
    ///
    /// - Parameters:
    ///   - name: name of the property. It's used only for debug/ui purpose but you can omit it.
    ///   - key: if specified this is the key used to fetch the property from providers list. If not specified the value is generated
    ///          by reading the property's name itself in format specified by the parent `FeatureFlagLoader`'s `keysConfiguration` property.
    ///   - default: the default value is used when key cannot be found in `FeatureFlagLoader`'s providers.
    ///   - allowedProviders: you can limit the providers where to get the value; if you specify a non `nil` array of types only instances
    ///                       of these types are queried to get value.
    ///   - excludedProviders: allows you to define several providers you want to exclude when flag is loaded in any `FeatureFlagProvider`.
    ///                        For example certain property should be not retrived from `FirebaseProvider` but only locally.
    ///   - computedValue: you should also set a computed provider. A computed value is evaluated before any provider; if it return a non
    ///                    `nil` value it will be the value of the flag. If `nil` is returned the provider continue asking to defined
    ///                    provider in order.
    ///   - description: description of the proprerty; you are encouraged to provide a short description of the feature flag.
    public init(name: String? = nil,
                key: String? = nil,
                default defaultValue: Value,
                excludedProviders: [FeatureFlagsProvider.Type]? = nil,
                computedValue: ComputedFlagClosure? = nil,
                description: FeatureFlagMetadata) {

        self.defaultValueBox.value = defaultValue
        self.excludedProviders = excludedProviders
        self.fixedKey = key
        self.computedValue = computedValue

        var info = description
        info.name = name
        self.metadata = info
    }

    public var debugDescription: String {
        "\(keyPath.fullPath)=\(wrappedValue)"
    }

    /// Return the value of the property by asking to the list of providers set.
    /// If a `providerType` is passed only that type is read.
    ///
    /// - Parameters:
    ///   - providerType: provider to read, `nil` to read every set provider in order.
    ///   - fallback: `true` to return the fallback value if no value were found in any provider, `false`
    ///                to return `nil` in that case.
    /// - Returns: `(value: Value?, source: FeatureFlagsProvider?)`
    public func flagValue(from providerType: FeatureFlagsProvider.Type? = nil, fallback: Bool = true) -> (value: Value?, source: FeatureFlagsProvider?) {
        if let value = computedValue?() {
            return (value, nil) // value is obtained by dynamic function.
        }

        guard loader.instance != nil else {
            return ( (fallback ? defaultValue : nil), nil) // no loader has been set, we want to get the fallback result.
        }

        let providersToQuery = providersWithTypes([providerType].compactMap({ $0 }))
        let keyPath = self.keyPath
        for provider in providersToQuery where isProviderAllowed(provider) {
            if let value: Value = provider.valueForFlag(key: keyPath) {
                // first valid result for provider is taken and returned
                return (value, provider)
            }
        }

        return ( (fallback ? defaultValue : nil), nil)
    }

    /// Change the default fallback value manually.
    ///
    /// - Parameter value: value.
    public func setDefault(_ value: Value) {
        defaultValueBox.value = value
    }

    /// Reset value stored in any writable provider assigned to this flag.
    /// Non writable provider are ignored.
    public func resetValue() throws {
        for provider in providers where provider.isWritable {
            try provider.resetValueForFlag(key: self.keyPath)
        }
    }

    /// Allows to change the value of feature flag by overwriting it to all or certain types
    /// of providers.
    ///
    /// - Parameters:
    ///   - value: new value to set.
    ///   - providers: providers where apply changes. Not all provider may support changing flags;
    ///                if you dont' specify a valid set of provider's type it will be applied to all
    ///                providers assigned to the parent's `FeatureFlagLoader`.
    /// - Returns: Return the list of provider which accepted the change.
    @discardableResult
    public func setValue(_ value: Value?, providers: [FeatureFlagsProvider.Type]? = nil) -> [FeatureFlagsProvider] {
        var alteredProviders = [FeatureFlagsProvider]()
        for provider in providersWithTypes(providers) {
            do {
                if try provider.setValue(value, forFlag: keyPath) {
                    alteredProviders.append(provider)
                }
            } catch { }
        }

        return alteredProviders
    }

    // MARK: - Internal Functions

    /// Return a filtered list of associated providers based on `types` received; if no values
    /// are specified no filter is applied and the list is complete.
    ///
    /// - Parameter types: types to filter.
    /// - Returns: [FlagsProvider]
    private func providersWithTypes(_ types: [FeatureFlagsProvider.Type]?) -> [FeatureFlagsProvider] {
        guard let filteredByTypes = types, filteredByTypes.isEmpty == false else {
            return allowedProviders() // no filter applied, return allowed providers.
        }

        // filter applied, return only providers which meet passed types ignoring allowed providers
        return loader.instance?.providers?.filter({ providerInstance in
            filteredByTypes.contains(where: { $0 == type(of: providerInstance) })
        }) ?? []
    }

    /// Allowed providers from the list of all providers of the parent `FeatureFlagsLoader`.
    ///
    /// - Returns: [FlagsProvider]
    private func allowedProviders() -> [FeatureFlagsProvider] {
        loader.instance?.providers?.filter({
            isProviderAllowed($0)
        }) ?? []
    }

    /// Return `true` if a provider is in the list of allowed providers specified in `limitProviders`.
    ///
    /// - Parameter provider: provider to check.
    /// - Returns: `true` if it's allowed, `false` otherwise.
    private func isProviderAllowed(_ provider: FeatureFlagsProvider) -> Bool {
        guard let excludedProviders = self.excludedProviders else {
            return true
        }

        return excludedProviders.contains { allowedType in
            allowedType == type(of: provider)
        } == false
    }

    /// Configure the property with the given loader which created it.
    ///
    /// - Parameters:
    ///   - loader: loader.
    ///   - keyPath: path.
    public func configureWithLoader(_ loader: FeatureFlagsLoaderProtocol, propertyName: String, keyPath: [KeyPathAndConfig]) {
        self.loader.instance = loader
        self.loader.propertyName = propertyName
        self.loader.propertyPath = keyPath
    }

}

// MARK: - FeatureFlag (Equatable)
extension FeatureFlag: Equatable where Value: Equatable {

    public static func == (lhs: FeatureFlag, rhs: FeatureFlag) -> Bool {
        return lhs.keyPath == rhs.keyPath && lhs.wrappedValue == rhs.wrappedValue
    }

}

// MARK: - FeatureFlag (Hashable)
extension FeatureFlag: Hashable where Value: Hashable {

    public func hash(into hasher: inout Hasher) {
        hasher.combine(keyPath)
        hasher.combine(wrappedValue)
    }

}

// MARK: - LoaderBox

/// This class is used only to avoid modifying the property wrapper itself which is immutable.
/// It just hold a weak reference to the loaded holder.
internal class LoaderBox {

    /// Identify the instance of the loader.
    weak var instance: FeatureFlagsLoaderProtocol?

    /// Used to store the name of the property when you have not set a fixed key in property.
    var propertyName: String = ""

    /// Path to the property.
    var propertyPath: [KeyPathAndConfig] = []

    /// Generate a `FeatureFlagKeyPath` from a concatenate list of paths coming from the structure which encapsulate the property itself.
    ///
    /// - Parameter paths: paths.
    /// - Returns: FeatureFlagKeyPath
    internal func generateKeyPath(_ paths: [KeyPathAndConfig]) -> FeatureFlagKeyPath {
        let defaultKeyTransform = instance?.keyConfiguration.keyTransform ?? .none
        let defaultPathSeparator = instance?.keyConfiguration.pathSeparator ?? FeatureFlagKeyPath.DefaultPathSeparator

        var pathComponents = paths.compactMap { key, keyConfiguration -> String? in
            guard let keyConfiguration = keyConfiguration else {
                return nil // must ignore the path component (.skip)
            }

            return key.transform(keyConfiguration.keyTransform)
        }

        if let prefix = instance?.keyConfiguration.globalPrefix {
            pathComponents.insert(prefix.transform(defaultKeyTransform), at: 0)
        }

        return FeatureFlagKeyPath(components: pathComponents, separator: defaultPathSeparator)
    }

    init() {}
}

// MARK: - Codable
public extension Decodable where Self: FeatureFlagProtocol, Self: Encodable {

    init?(encoded value: EncodedFlagValue) {
        guard case .data(let data) = value else {
            return nil
        }

        do {
            let decoder = JSONDecoder()
            self = try decoder.decode(Self.self, from: data)
        } catch {
            return nil
        }
    }

}

public extension Encodable where Self: FeatureFlagProtocol, Self: Decodable {

    func encoded() -> EncodedFlagValue {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .sortedKeys
            return .data(try encoder.encode(self))
        } catch {
            return .data(Data())
        }
    }

}

// MARK: - Array
extension Array: FeatureFlagProtocol where Element: FeatureFlagProtocol {
    public typealias EncodedValue = [Element.EncodedValue]

    public init?(encoded value: EncodedFlagValue) {
        guard case .array(let array) = value else {
            return nil
        }

        self = array.compactMap {
            Element(encoded: $0)
        }
    }

    public func encoded() -> EncodedFlagValue {
        .array(self.map({
            $0.encoded()
        }))
    }

}

// MARK: - Dictionary
extension Dictionary: FeatureFlagProtocol where Key == String, Value: FeatureFlagProtocol {
    public typealias EncodedValue = [String: Value.EncodedValue]

    public init?(encoded value: EncodedFlagValue) {
        guard case .dictionary(let dictionary) = value else {
            return nil
        }

        self = dictionary.compactMapValues {
            Value(encoded: $0)
        }
    }

    public func encoded() -> EncodedFlagValue {
        .dictionary(self.mapValues({
            $0.encoded()
        }))
    }
}

// MARK: - Date
extension Date: FeatureFlagProtocol {
    public typealias EncodedValue = Date

    private static let isoFormatter = ISO8601DateFormatter()

    public init?(encoded value: EncodedFlagValue) {
        guard case .string(let rawDate) = value,
              let date = Date.isoFormatter.date(from: rawDate) else {
            return nil
        }

        self = date
    }

    public func encoded() -> EncodedFlagValue {
        .string(Date.isoFormatter.string(from: self))
    }

}

// MARK: - URL
extension URL: FeatureFlagProtocol {
    public typealias EncodedValue = Date

    public init?(encoded value: EncodedFlagValue) {
        guard case .string(let value) = value else {
            return nil
        }

        self.init(string: value)
    }

    public func encoded() -> EncodedFlagValue {
        .string(self.absoluteString)
    }

}

// MARK: - Int
extension Int: FeatureFlagProtocol {
    public typealias EncodedValue = Int

    public init?(encoded value: EncodedFlagValue) {
        switch value {
            case .integer(let v):
                self = v
            case .string(let v):
                self = (v as NSString).integerValue
            default:
                return nil
        }
    }

    public func encoded() -> EncodedFlagValue {
        .integer(self)
    }

}

// MARK: - Int8
extension Int8: FeatureFlagProtocol {
    public typealias EncodedValue = Int

    public init?(encoded value: EncodedFlagValue) {
        guard let value = Int(encoded: value) else {
            return nil
        }

        self = Int8(value)
    }

    public func encoded() -> EncodedFlagValue {
        .integer(Int(self))
    }
}

// MARK: - Int16
extension Int16: FeatureFlagProtocol {
    public typealias EncodedValue = Int

    public init?(encoded value: EncodedFlagValue) {
        guard let value = Int(encoded: value) else {
            return nil
        }

        self = Int16(value)
    }

    public func encoded() -> EncodedFlagValue {
        .integer(Int(self))
    }
}

// MARK: - Int32
extension Int32: FeatureFlagProtocol {
    public typealias EncodedValue = Int

    public init?(encoded value: EncodedFlagValue) {
        guard let value = Int(encoded: value) else {
            return nil
        }

        self = Int32(value)
    }

    public func encoded() -> EncodedFlagValue {
        .integer(Int(self))
    }
}

// MARK: - Int64
extension Int64: FeatureFlagProtocol {
    public typealias EncodedValue = Int

    public init?(encoded value: EncodedFlagValue) {
        guard let value = Int(encoded: value) else {
            return nil
        }

        self = Int64(value)
    }

    public func encoded() -> EncodedFlagValue {
        .integer(Int(self))
    }

}

// MARK: - UInt
extension UInt: FeatureFlagProtocol {
    public typealias EncodedValue = Int

    public init?(encoded value: EncodedFlagValue) {
        guard let value = Int(encoded: value) else {
            return nil
        }

        self = UInt(value)
    }

    public func encoded() -> EncodedFlagValue {
        .integer(Int(self))
    }

}

// MARK: - UInt8
extension UInt8: FeatureFlagProtocol {
    public typealias EncodedValue = Int

    public init?(encoded value: EncodedFlagValue) {
        guard let value = Int(encoded: value) else {
            return nil
        }

        self = UInt8(value)
    }

    public func encoded() -> EncodedFlagValue {
        .integer(Int(self))
    }

}

// MARK: - UInt16
extension UInt16: FeatureFlagProtocol {
    public typealias EncodedValue = Int

    public init?(encoded value: EncodedFlagValue) {
        guard let value = Int(encoded: value) else {
            return nil
        }

        self = UInt16(value)
    }

    public func encoded() -> EncodedFlagValue {
        .integer(Int(self))
    }

}

// MARK: - UInt32
extension UInt32: FeatureFlagProtocol {
    public typealias EncodedValue = Int

    public init?(encoded value: EncodedFlagValue) {
        guard let value = Int(encoded: value) else {
            return nil
        }

        self = UInt32(value)
    }

    public func encoded() -> EncodedFlagValue {
        .integer(Int(self))
    }

}

// MARK: - UInt64
extension UInt64: FeatureFlagProtocol {
    public typealias EncodedValue = Int

    public init?(encoded value: EncodedFlagValue) {
        guard let value = Int(encoded: value) else {
            return nil
        }

        self = UInt64(value)
    }

    public func encoded() -> EncodedFlagValue {
        .integer(Int(self))
    }

}

// MARK: - Double
extension Double: FeatureFlagProtocol {
    public typealias EncodedValue = Double

    public init?(encoded value: EncodedFlagValue) {
        switch value {
            case let .double(value):
                self = value
            case let .float(value):
                self = Double(value)
            case let .integer(value):
                self = Double(value)
            case let .string(value):
                self = (value as NSString).doubleValue
            default:
                return nil
        }
    }

    public func encoded() -> EncodedFlagValue {
        .double(self)
    }

}

// MARK: - Float
extension Float: FeatureFlagProtocol {
    public typealias EncodedValue = Float

    public init?(encoded value: EncodedFlagValue) {
        switch value {
            case .float(let v):
                self = v
            case .double(let v):
                self = Float(v)
            case .integer(let v):
                self = Float(v)
            case .string(let v):
                self = (v as NSString).floatValue
            default:
                return nil
        }
    }

    public func encoded() -> EncodedFlagValue {
        .float(self)
    }

}

// MARK: JSON
public class JSONData {

    // MARK: - Private Properties

    /// Dictionary contents
    private var dictionary: NSDictionary

    // MARK: - Initialization

    /// Initialize a new JSON with data.
    ///
    /// - Parameter dict: dictionary
    public init(_ dict: NSDictionary?) {
        self.dictionary = dict ?? [:]
    }

    /// Initialize with a dictionary.
    ///
    /// - Parameter dict: dictionary.
    public init(_ dict: [String: Any]) {
        self.dictionary = dict as NSDictionary
    }

    /// Initialize with json string. Return `nil` if invalid json.
    ///
    /// - Parameter jsonString: json string
    public init?(jsonString: String) {
        guard let data = jsonString.data(using: .utf8),
              let dict = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) as? NSDictionary else {
            return nil
        }

        self.dictionary = dict
    }

    required public init?(encoded value: EncodedFlagValue) {
        switch value {
            case .json(let dict):
                self.dictionary = dict
            default:
                return nil
        }
    }

    // MARK: - Public Functions

    /// Get the value for a given keypath.
    ///
    /// - Parameter keyPath: keypath.
    /// - Returns: V?
    public func valueForKey<V>(_ keyPath: String) -> V?  {
        return dictionary.value(forKey: keyPath) as? V
    }

}

// MARK: JSONData (FlagProtocol)
extension JSONData: FeatureFlagProtocol {
    public typealias EncodedValue = NSDictionary

    public func encoded() -> EncodedFlagValue {
        .json(self.dictionary)
    }

}

// MARK: - Boolean Type
extension Bool: FeatureFlagProtocol {
    public typealias EncodedValue = Bool

    public init?(encoded value: EncodedFlagValue) {
        switch value {
            case .bool(let v):
                self = v
            case .integer(let v):
                self = (v != 0)
            case .string(let v):
                self = (v as NSString).boolValue
            default:
                return nil
        }
    }

    public func encoded() -> EncodedFlagValue {
        .bool(self)
    }

}

// MARK: - String Type
extension String: FeatureFlagProtocol {
    public typealias EncodedValue = String

    public init?(encoded value: EncodedFlagValue) {
        guard case .string(let value) = value else {
            return nil
        }

        self = value
    }

    public func encoded() -> EncodedFlagValue {
        .string(self)
    }

}

// MARK: - Data Type
extension Data: FeatureFlagProtocol {
    public typealias EncodedValue = Data

    public init?(encoded value: EncodedFlagValue) {
        guard case .data(let value) = value else {
            return nil
        }

        self = value
    }

    public func encoded() -> EncodedFlagValue {
        .data(self)
    }

}

// MARK: - RawRepresentable
extension RawRepresentable where Self: FeatureFlagProtocol, RawValue: FeatureFlagProtocol {
    public typealias EncodedValue = RawValue.EncodedValue

    public init?(encoded value: EncodedFlagValue) {
        guard let rawValue = RawValue(encoded: value) else {
            return nil
        }

        self.init(rawValue: rawValue)
    }

    public func encoded() -> EncodedFlagValue {
        self.rawValue.encoded()
    }

}

// MARK: - Optional
extension Optional: FeatureFlagProtocol where Wrapped: FeatureFlagProtocol {
    public typealias EncodedValue = Wrapped.EncodedValue?

    public init?(encoded value: EncodedFlagValue) {
        if case .none = value {
            self = .none
        } else if let wrapped = Wrapped(encoded: value) {
            self = wrapped
        } else {
            self = .none
        }
    }

    public func encoded() -> EncodedFlagValue {
        self?.encoded() ?? .none
    }

}
