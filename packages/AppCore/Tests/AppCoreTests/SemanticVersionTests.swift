import XCTest
import AppCore

final class SemanticVersionTests: XCTestCase {
    func testParsesValidVersion() {
        let version = SemanticVersion("1.2.3")
        XCTAssertEqual(version, SemanticVersion(major: 1, minor: 2, patch: 3))
    }

    func testParsesZeroVersion() {
        XCTAssertEqual(SemanticVersion("0.0.0"), SemanticVersion(major: 0, minor: 0, patch: 0))
    }

    func testRejectsInvalidStrings() {
        let invalid = ["", "1", "1.2", "1.2.3.4", "a.b.c", "1.2.x", "1..3", "1.2.-3", " 1.2.3", "1.2.3 "]
        for string in invalid {
            XCTAssertNil(SemanticVersion(string), "expected nil for \(string)")
        }
    }

    func testOrdering() {
        XCTAssertLessThan(SemanticVersion("1.2.3")!, SemanticVersion("1.2.10")!)
        XCTAssertLessThan(SemanticVersion("1.9.9")!, SemanticVersion("2.0.0")!)
        XCTAssertLessThan(SemanticVersion("1.2.3")!, SemanticVersion("1.3.0")!)
        XCTAssertFalse(SemanticVersion("2.0.0")! < SemanticVersion("2.0.0")!)
    }

    func testDescriptionRoundTrip() {
        let original = "10.20.30"
        XCTAssertEqual(SemanticVersion(original)?.description, original)
    }
}
