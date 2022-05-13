import Foundation
import FeatureFlag

// MARK: - Dictionnary

public enum BentoDict {

    /// Remove a set key from dictionary.
    internal static func removeValue(_ dict: inout [String: Any], forKeyPath keyPath: FeatureFlagKeyPath) {
        switch keyPath.count {
            case 1:
                dict.removeValue(forKey: keyPath.first!)
            case (2..<Int.max):
                let key = keyPath.first!
                var subDict = (dict[key] as? [String: Any]) ?? [:]
                removeValue(&subDict, forKeyPath: keyPath.dropFirst())
                dict[key] = subDict
            default:
                return
        }
    }

    /// Set the value into a dictionary for a keypath.
    ///
    /// - Parameters:
    ///   - dict: source dictionary.
    ///   - value: value to set.
    ///   - keyPath: keypath to set.
    internal static func setValueForDictionary<V>(_ dict: inout [String: Any], value: V?, keyPath: FeatureFlagKeyPath) {
        switch keyPath.count {
            case 1:
                if let value = value {
                    // swiftlint:disable force_unwrapping
                    dict[keyPath.first!] = value
                } else {
                    // swiftlint:disable force_unwrapping
                    dict.removeValue(forKey: keyPath.first!)
                }

            case (2..<Int.max):
                // swiftlint:disable force_unwrapping
                let key = keyPath.first!
                var subDict = (dict[key] as? [String: Any]) ?? [:]
                setValueForDictionary(&subDict, value: value, keyPath: keyPath.dropFirst())
                dict[key] = subDict

            default:
                return
        }
    }

    /// Get the value of the object for a given keypath.
    ///
    /// - Parameters:
    ///   - dict: dictionary source of the data.
    ///   - keys: keypath.
    /// - Returns: typed value.
    internal static func getValueInDictionary<V>(_ dict: [String: Any], forKeyPath keys: FeatureFlagKeyPath) -> V? {
        switch keys.count {
            case 1:
                return dict[keys[0]!] as? V

            case (2..<Int.max):
                var running = dict

                let exceptLastOne = keys.pathComponents[0 ..< (keys.count - 1)]
                for key in exceptLastOne{
                    guard let r = running[key] as? [String: AnyObject] else {
                        return nil
                    }

                    running = r
                }

                // swiftlint:disable force_unwrapping
                return running[keys.last!] as? V

            default:
                return nil

        }
    }

}
