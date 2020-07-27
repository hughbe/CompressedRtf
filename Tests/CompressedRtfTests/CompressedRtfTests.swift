import XCTest
@testable import CompressedRtf

final class CompressedRtfTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(CompressedRtf().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
