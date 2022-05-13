//
//  File.swift
//  
//
//  Created by Amine Bensalah on 13/05/2022.
//

import Foundation

public protocol AnyFeatureFlagsLoader {
    /// Providers of the flag.
    var providers: [FeatureFlagsProvider]? { get }

    /// Type of collection group loaded by loader instance.
    var collectionType: String { get }

    /// List of feature flags of the loader.
    var featureFlags: [AnyFeatureFlag] { get }

    /// Hierarchical list of flags of the loader.
    var hierarcyFeatureFlags: [AnyFeature] { get }

    /// Description of the key configuration.
    var keyConfiguration: KeyConfiguration { get }

    /// Metadata associated with loader.
    var metadata: FeatureFlagMetadata? { get }
}

extension FeatureFlagsLoader: AnyFeatureFlagsLoader {
    public var collectionType: String {
        String(describing: type(of: loadedCollection))
    }
}
