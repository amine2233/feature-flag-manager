//
//  File.swift
//  
//
//  Created by amine on 08/06/2022.
//

import Foundation
import FeatureFlag
import FeatureFlagProvider

// Define the structure of your feature flags with type-safe properties!
struct UserFlags: FeatureFlagCollectionProtocol {
    @FeatureFlag(default: true, description: "Show social login options along native login form")
    var showSocialLogin: Bool
    
    @FeatureFlag(default: 0, description: "Maximum login attempts before blocking account")
    var maxLoginAttempts: Int
    
    @FeatureFlag(key: "rating_mode", default: "at_launch", description: "The behaviour to show the rating popup")
    var appReviewRating: String

    public init() {}
}
