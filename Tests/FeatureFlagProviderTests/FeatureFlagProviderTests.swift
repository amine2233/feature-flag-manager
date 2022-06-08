import XCTest
import FeatureFlag
@testable import FeatureFlagProvider

class FeatureFlagProviderTests: XCTestCase {
    
    // Allocate your own data providers
    let mockProvider = FeatureFlagsProviderMock(dictionary: [:])
    // let fbProvider = FirebaseRemoteProvider()

    // Loader is the point for query values
    var userFlagsLoader: FeatureFlagsLoader<UserFlags>!

    override func setUpWithError() throws {
        self.userFlagsLoader = FeatureFlagsLoader(
            UserFlags.self, // load flags definition
            description: .init(name: "User Features", description: "Cool experimental features for user account"),
            providers: [mockProvider]) // set providers
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func test_show_social_login_default_value() throws {
        // given
        
        // when
        let result = self.userFlagsLoader.showSocialLogin
        
        // then
        XCTAssertTrue(result)
    }
    
    func test_show_social_login_set_default_value() throws {
        // given
        self.userFlagsLoader.$showSocialLogin.setDefault(false)
        
        // when
        let result = self.userFlagsLoader.$showSocialLogin.defaultValue
        
        // then
        XCTAssertFalse(result)
    }

    func test_show_social_login_set_new_value() throws {
        // given
        self.userFlagsLoader.$showSocialLogin.setValue(false)
        
        // when
        let result = self.userFlagsLoader.showSocialLogin
        
        // then
        XCTAssertFalse(result)
    }
    
    func test_show_social_login_set_reset_value() throws {
        // given
        self.userFlagsLoader.$showSocialLogin.setValue(false)
        try self.userFlagsLoader.$showSocialLogin.resetValue()
        
        // when
        let result = self.userFlagsLoader.showSocialLogin
        
        // then
        XCTAssertTrue(result)
    }
}
