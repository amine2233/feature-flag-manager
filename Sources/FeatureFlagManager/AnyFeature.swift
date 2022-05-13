//
//  File.swift
//  
//
//  Created by Amine Bensalah on 13/05/2022.
//

import Foundation

public protocol AnyFeature {
    /// Childs
    func hierarchyfeatureFlags() -> [AnyFeature]

    /// Metadata associated.
    var metadata: FeatureFlagMetadata { get }
}
