//
//  File.swift
//  
//
//  Created by amine on 08/06/2022.
//

import Foundation
import FeatureFlag

final class FeatureFlagsProviderMock: FeatureFlagsProvider {
    var name: String {
        "Mocks"
    }
    
    var shortDescription: String?
    
    var isWritable: Bool { true }
    
    private var dictionary: [FeatureFlagKeyPath: Any]
    
    init(dictionary: [FeatureFlagKeyPath: Any]) {
        self.dictionary = dictionary
    }
    
    func valueForFlag<Value>(key: FeatureFlagKeyPath) -> Value? where Value : FeatureFlagProtocol {
        dictionary[key] as? Value
    }
    
    func setValue<Value>(_ value: Value?, forFlag key: FeatureFlagKeyPath) throws -> Bool where Value : FeatureFlagProtocol {
        dictionary[key] = value
        return value != nil
    }
    
    func resetValueForFlag(key: FeatureFlagKeyPath) throws {
        dictionary.removeAll()
    }
}
