import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(CompressedRtfTests.allTests),
    ]
}
#endif
