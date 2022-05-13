import Foundation

/// This represent the metadata information associated with a flag.
/// Typically these values are read from the UI interface or can be used as documented reference inside the code.
public struct FeatureFlagMetadata {

    /// Name of the flag/group.
    public var name: String?

    /// When set to `true` the flag can't be altered by using the FeatureFlags Browser.
    /// By default is set to `false`.
    /// NOTE: you can still alter it via code.
    public var isLocked = false

    /// A short description of the flag. You should really provider a context in order to avoid confusion, this
    /// this the reason this is the only property which is not set to optional.
    public var description: String

    /// If true this key should be not visibile by any tool which read values.
    /// By default is set to `false`.
    public var isInternal = false

    /// Where applicable the index defines the order of the item into a UI list view.
    public var order: Int = 0

    // MARK: - Initialization

    public init(name: String? = nil, description: String, order: Int = 0,
                isInternal: Bool = false,
                isLocked: Bool = false) {
        self.name = name
        self.description = description
        self.order = order
        self.isInternal = isInternal
        self.isLocked = isLocked
    }

}
