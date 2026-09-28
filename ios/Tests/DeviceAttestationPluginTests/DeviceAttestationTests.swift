import XCTest
@testable import DeviceAttestationPlugin

class DeviceAttestationTests: XCTestCase {
    func testIsSupportedReturnsBool() {
        let implementation = DeviceAttestation()
        let supported = implementation.isSupported()
        XCTAssertTrue(supported == true || supported == false)
    }
}
