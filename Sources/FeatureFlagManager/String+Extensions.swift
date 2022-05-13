//
//  File.swift
//  
//
//  Created by Amine Bensalah on 13/05/2022.
//

import Foundation

internal extension String {

    // MARK: - Internal Functions

    /// Transform receiver as specified.
    ///
    /// - Parameter transform: transformation.
    /// - Returns: String
    func transform(_ transform: Transform) -> String {
        switch transform {
            case .none: return self
            case .kebabCase: return toSnakeCase(separator: "-")
            case .snakeCase: return toSnakeCase()
            case .custom(let v): return v
        }
    }

    // MARK: - Private Functions

    /// Apply transformm to a camel case string to snake case:
    /// Example: from `myProperty` to `my_property` with a specified separator (by default is `_`).
    ///
    /// - Parameter separator: separator to use, by default `_`.
    /// - Returns: String
    private func toSnakeCase(separator: Character = "_") -> String {
        guard isEmpty == false else {
            return self
        }

        let pattern = "([a-z0-9])([A-Z])"

        let regex = try? NSRegularExpression(pattern: pattern, options: [])
        let range = NSRange(location: 0, length: count)
        return regex?.stringByReplacingMatches(in: self, options: [], range: range, withTemplate: "$1\(separator)$2").lowercased() ?? self
    }

}

// MARK: - String (Transform)
public extension String {

    /// Transform of the keys.
    ///
    /// - `none`: no transform is applied.
    /// - `kebabCase`: refers to the style of writing in which each space is replaced by a `-` character.
    /// - `snakeCase`: refers to the style of writing in which each space is replaced by a `_` character.
    /// - `custom`: define a fixed key to use as the key of the collection.
    enum Transform {
        case none
        case kebabCase
        case snakeCase
        case custom(String)
    }

}
