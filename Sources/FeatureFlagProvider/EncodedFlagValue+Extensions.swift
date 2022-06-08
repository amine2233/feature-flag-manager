//
//  File.swift
//  
//
//  Created by Amine Bensalah on 13/05/2022.
//

import Foundation
import FeatureFlag

extension EncodedFlagValue {

    // MARK: - Initialization

    /// Create a new encoded data type from a generic object received as init.
    ///
    /// - Parameters:
    ///   - object: object to decode.
    ///   - typeHint: type of data.
    init?<Value>(object: Any, classType: Value.Type) where Value: FeatureFlagProtocol {
        switch object {
            case let value as Bool where classType.EncodedValue == Bool.self || classType.EncodedValue == Optional<Bool>.self:
                self = .bool(value)
            case let value as Data:
                self = .data(value)
            case let value as Int:
                self = .integer(value)
            case let value as Float:
                self = .float(value)
            case let value as Double:
                self = .double(value)
            case let value as String:
                self = .string(value)
            case is NSNull:
                self = .none
            case let value as [Any]:
                self = .array(value.compactMap({
                    EncodedFlagValue(object: $0, classType: classType)
                }))
            case let value as [String: Any]:
                self = .dictionary(value.compactMapValues({
                    EncodedFlagValue(object: $0, classType: classType)
                }))
            case let value as [String: Any]:
                self = .json(AnyCodable(value))
            default:
                return nil
        }
    }

    /// Trnsform boxed data in a valid `NSObject` you can store.
    ///
    /// - Returns: NSObject
    #if !os(Linux)
    func nsObject() -> NSObject {
        switch self {
            case let .array(value):
                return value.map({ $0.nsObject() }) as NSArray
            case let .bool(value):
                return value as NSNumber
            case let .data(value):
                return value as NSData
            case let .dictionary(value):
                return value.mapValues({ $0.nsObject() }) as NSDictionary
            case let .double(value):
                return value as NSNumber
            case let .float(value):
                return value as NSNumber
            case let .integer(value):
                return value as NSNumber
            case .none:
                return NSNull()
            case let .string(value):
                return value as NSString
            case let .json(value):
                return NSDictionary(dictionary: value.value as? [String: Any] ?? [:])
        }
    }
    #endif
}
