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

    // MARK: - Prerelease (SemVer 2.0.0)

    func testParsesPrereleaseVersion() {
        let version = SemanticVersion("1.2.3-beta.1")
        XCTAssertEqual(version?.prerelease, ["beta", "1"])
        XCTAssertEqual(version, SemanticVersion(major: 1, minor: 2, patch: 3, prerelease: ["beta", "1"]))
    }

    func testPrereleaseIsEmptyForReleaseVersion() {
        XCTAssertEqual(SemanticVersion("1.2.3")?.prerelease, [])
    }

    func testParsesIdentifiersContainingHyphensAndDigits() {
        XCTAssertEqual(SemanticVersion("1.0.0-x-y-z.--")?.prerelease, ["x-y-z", "--"])
        XCTAssertEqual(SemanticVersion("1.0.0-0.3.7")?.prerelease, ["0", "3", "7"])
        XCTAssertEqual(SemanticVersion("1.0.0-0a.15")?.prerelease, ["0a", "15"])
    }

    func testRejectsInvalidPrerelease() {
        let invalid = [
            "1.2.3-",           // empty prerelease
            "1.2.3-béta",       // non-ASCII
            "1.2.3-beta..1",    // empty identifier in the middle
            "1.2.3-beta.",      // trailing empty identifier
            "1.2.3-.beta",      // leading empty identifier
            "1.2.3-beta.01",    // leading zero in numeric identifier
            "1.2.3-00",         // ditto
            "1.2.3-beta_1",     // underscore is not alphanumeric/hyphen
            "1.2.3-beta 1",     // neither is a space
            "1.2-beta",         // incomplete core
            "-beta",            // missing core
        ]
        for string in invalid {
            XCTAssertNil(SemanticVersion(string), "expected nil for \(string)")
        }
    }

    func testIssuePrecedenceChain() {
        // Required by issue #3.
        assertStrictlyAscending(["1.2.3-alpha", "1.2.3-alpha.1", "1.2.3-beta", "1.2.3"])
    }

    func testSemverSpecPrecedenceChain() {
        // The worked example from SemVer 2.0.0 rule 11.4.
        assertStrictlyAscending([
            "1.0.0-alpha", "1.0.0-alpha.1", "1.0.0-alpha.beta", "1.0.0-beta",
            "1.0.0-beta.2", "1.0.0-beta.11", "1.0.0-rc.1", "1.0.0",
        ])
    }

    func testNumericIdentifiersRankBelowAlphanumericOnes() {
        assertStrictlyAscending(["1.0.0-1", "1.0.0--", "1.0.0-alpha"])
    }

    func testNumericIdentifiersBeyondIntRangeCompareByMagnitude() {
        assertStrictlyAscending(["1.0.0-2", "1.0.0-99999999999999999999"])
    }

    func testPrereleaseLosesToHigherCoreVersion() {
        XCTAssertLessThan(SemanticVersion("1.2.3-rc.1")!, SemanticVersion("1.2.4-alpha")!)
        XCTAssertLessThan(SemanticVersion("1.2.3")!, SemanticVersion("1.2.4-alpha")!)
    }

    func testPrereleaseAffectsEquality() {
        XCTAssertNotEqual(SemanticVersion("1.2.3-alpha"), SemanticVersion("1.2.3"))
        XCTAssertFalse(SemanticVersion("1.2.3-alpha")! < SemanticVersion("1.2.3-alpha")!)
    }

    func testPrereleaseDescriptionRoundTrip() {
        for original in ["1.2.3-beta.1", "1.0.0-x-y-z.--", "1.0.0-0.3.7"] {
            XCTAssertEqual(SemanticVersion(original)?.description, original)
        }
    }

    private func assertStrictlyAscending(
        _ strings: [String], file: StaticString = #filePath, line: UInt = #line
    ) {
        let versions = strings.compactMap(SemanticVersion.init)
        XCTAssertEqual(versions.count, strings.count, "every version should parse", file: file, line: line)
        for (lower, higher) in zip(versions, versions.dropFirst()) {
            XCTAssertLessThan(lower, higher, file: file, line: line)
            XCTAssertFalse(higher < lower, "\(higher) must not precede \(lower)", file: file, line: line)
        }
    }
}
