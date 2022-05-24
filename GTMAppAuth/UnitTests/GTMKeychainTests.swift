import XCTest

#if SWIFT_PACKAGE
import AppAuthCore
#endif


class GTMKeychainTests: XCTestCase {

    let kIssuer: String = "https://accounts.google.com"

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testSPMImportSuccess() throws {
        let issuer = NSURL(string:kIssuer)!

        OIDAuthorizationService.discoverConfiguration(forIssuer: issuer as URL) { configuration, error in
            XCTAssertNotNil(configuration)
        }
    }

}
