import Foundation
import XCTest
import AppCore

final class AnnouncementTests: XCTestCase {
    // The logic is pure interval comparison, so opaque epoch offsets are
    // enough and keep the tests free of calendar/timezone concerns.
    private let start = Date(timeIntervalSince1970: 1_000)
    private let end = Date(timeIntervalSince1970: 2_000)
    private let insideDate = Date(timeIntervalSince1970: 1_500)
    private let insideVersion = SemanticVersion("1.5.0")!

    private var announcement: Announcement {
        Announcement(
            from: start,
            to: end,
            minVersion: SemanticVersion("1.2.0")!,
            maxVersion: SemanticVersion("2.0.0")!
        )
    }

    // MARK: - Display period

    func testDisplaysWithinPeriod() {
        XCTAssertTrue(announcement.shouldDisplay(on: insideDate, appVersion: insideVersion))
    }

    func testDoesNotDisplayBeforePeriod() {
        let before = Date(timeIntervalSince1970: 999)
        XCTAssertFalse(announcement.shouldDisplay(on: before, appVersion: insideVersion))
    }

    func testDoesNotDisplayAfterPeriod() {
        let after = Date(timeIntervalSince1970: 2_001)
        XCTAssertFalse(announcement.shouldDisplay(on: after, appVersion: insideVersion))
    }

    func testDisplaysExactlyAtPeriodStart() {
        XCTAssertTrue(announcement.shouldDisplay(on: start, appVersion: insideVersion))
    }

    func testDisplaysExactlyAtPeriodEnd() {
        XCTAssertTrue(announcement.shouldDisplay(on: end, appVersion: insideVersion))
    }

    // MARK: - Version range

    func testDoesNotDisplayBelowMinVersion() {
        XCTAssertFalse(announcement.shouldDisplay(on: insideDate, appVersion: SemanticVersion("1.1.9")!))
    }

    func testDoesNotDisplayAboveMaxVersion() {
        XCTAssertFalse(announcement.shouldDisplay(on: insideDate, appVersion: SemanticVersion("2.0.1")!))
    }

    func testDisplaysExactlyAtMinVersion() {
        XCTAssertTrue(announcement.shouldDisplay(on: insideDate, appVersion: SemanticVersion("1.2.0")!))
    }

    func testDisplaysExactlyAtMaxVersion() {
        XCTAssertTrue(announcement.shouldDisplay(on: insideDate, appVersion: SemanticVersion("2.0.0")!))
    }

    func testPrereleaseOfMinVersionIsBelowRange() {
        // SemVer precedence: 1.2.0-rc.1 < 1.2.0, so it falls outside the range.
        XCTAssertFalse(announcement.shouldDisplay(on: insideDate, appVersion: SemanticVersion("1.2.0-rc.1")!))
    }

    // MARK: - Both conditions must hold

    func testDoesNotDisplayWhenNeitherConditionMatches() {
        let after = Date(timeIntervalSince1970: 2_001)
        XCTAssertFalse(announcement.shouldDisplay(on: after, appVersion: SemanticVersion("0.9.0")!))
    }

    // MARK: - Degenerate ranges

    func testSingleInstantPeriodDisplaysOnlyAtThatInstant() {
        let single = Announcement(
            from: start, to: start,
            minVersion: SemanticVersion("1.2.0")!, maxVersion: SemanticVersion("2.0.0")!
        )
        XCTAssertTrue(single.shouldDisplay(on: start, appVersion: insideVersion))
        XCTAssertFalse(single.shouldDisplay(on: Date(timeIntervalSince1970: 1_001), appVersion: insideVersion))
    }

    func testSingleVersionRangeDisplaysOnlyThatVersion() {
        let single = Announcement(
            from: start, to: end,
            minVersion: SemanticVersion("1.5.0")!, maxVersion: SemanticVersion("1.5.0")!
        )
        XCTAssertTrue(single.shouldDisplay(on: insideDate, appVersion: SemanticVersion("1.5.0")!))
        XCTAssertFalse(single.shouldDisplay(on: insideDate, appVersion: SemanticVersion("1.5.1")!))
        XCTAssertFalse(single.shouldDisplay(on: insideDate, appVersion: SemanticVersion("1.4.9")!))
    }

    func testInvertedPeriodDisplaysNothing() {
        let inverted = Announcement(
            from: end, to: start,
            minVersion: SemanticVersion("1.2.0")!, maxVersion: SemanticVersion("2.0.0")!
        )
        XCTAssertFalse(inverted.shouldDisplay(on: insideDate, appVersion: insideVersion))
        XCTAssertFalse(inverted.shouldDisplay(on: start, appVersion: insideVersion))
        XCTAssertFalse(inverted.shouldDisplay(on: end, appVersion: insideVersion))
    }

    func testInvertedVersionRangeDisplaysNothing() {
        let inverted = Announcement(
            from: start, to: end,
            minVersion: SemanticVersion("2.0.0")!, maxVersion: SemanticVersion("1.2.0")!
        )
        XCTAssertFalse(inverted.shouldDisplay(on: insideDate, appVersion: insideVersion))
        XCTAssertFalse(inverted.shouldDisplay(on: insideDate, appVersion: SemanticVersion("2.0.0")!))
        XCTAssertFalse(inverted.shouldDisplay(on: insideDate, appVersion: SemanticVersion("1.2.0")!))
    }
}
