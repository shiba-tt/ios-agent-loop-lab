import XCTest
import AppCore

final class SettingsStoreTests: XCTestCase {
    // The issue's two validated example settings, plus an unvalidated one.
    private let nickname = SettingKey("nickname", default: "guest", rule: .characterCount(1...20))
    private let reminderHour = SettingKey("reminderHour", default: 9, rule: .range(0...23))
    private let soundEnabled = SettingKey("soundEnabled", default: true)

    private var store = InMemorySettingsStore()

    override func setUp() {
        super.setUp()
        store = InMemorySettingsStore()
    }

    // MARK: - Defaults for unset keys

    func testUnsetKeyReturnsDefault() {
        XCTAssertEqual(store.value(for: nickname), "guest")
        XCTAssertEqual(store.value(for: reminderHour), 9)
        XCTAssertTrue(store.value(for: soundEnabled))
    }

    func testRemoveValueRevertsToDefault() throws {
        try store.set("Alice", for: nickname)
        store.removeValue(for: nickname)
        XCTAssertEqual(store.value(for: nickname), "guest")
    }

    func testRemovingUnsetKeyIsNoOp() {
        store.removeValue(for: nickname)
        XCTAssertEqual(store.value(for: nickname), "guest")
    }

    // MARK: - Typed round trips

    func testRoundTripStoresValues() throws {
        try store.set("Alice", for: nickname)
        try store.set(22, for: reminderHour)
        try store.set(false, for: soundEnabled)
        XCTAssertEqual(store.value(for: nickname), "Alice")
        XCTAssertEqual(store.value(for: reminderHour), 22)
        XCTAssertFalse(store.value(for: soundEnabled))
    }

    func testOverwriteReplacesStoredValue() throws {
        try store.set("Alice", for: nickname)
        try store.set("Bob", for: nickname)
        XCTAssertEqual(store.value(for: nickname), "Bob")
    }

    func testKeysAreIndependent() throws {
        try store.set("Alice", for: nickname)
        XCTAssertEqual(store.value(for: reminderHour), 9)
        try store.set(7, for: reminderHour)
        XCTAssertEqual(store.value(for: nickname), "Alice")
    }

    // MARK: - Validation accepts in-range values

    func testAcceptsBoundaryValues() throws {
        try store.set("x", for: nickname)
        XCTAssertEqual(store.value(for: nickname), "x")
        try store.set(String(repeating: "x", count: 20), for: nickname)
        XCTAssertEqual(store.value(for: nickname), String(repeating: "x", count: 20))
        try store.set(0, for: reminderHour)
        XCTAssertEqual(store.value(for: reminderHour), 0)
        try store.set(23, for: reminderHour)
        XCTAssertEqual(store.value(for: reminderHour), 23)
    }

    func testAcceptsNonASCIINickname() throws {
        try store.set("あいうえお", for: nickname)
        XCTAssertEqual(store.value(for: nickname), "あいうえお")
    }

    // MARK: - Validation rejects out-of-range values

    func testRejectsNicknameBelowMinimumLength() {
        XCTAssertThrowsError(try store.set("", for: nickname))
    }

    func testRejectsNicknameAboveMaximumLength() {
        XCTAssertThrowsError(try store.set(String(repeating: "x", count: 21), for: nickname))
    }

    func testRejectsReminderHourBelowRange() {
        XCTAssertThrowsError(try store.set(-1, for: reminderHour))
    }

    func testRejectsReminderHourAboveRange() {
        XCTAssertThrowsError(try store.set(24, for: reminderHour))
    }

    func testCharacterCountUsesGraphemeClusters() throws {
        // "🇯🇵" is two Unicode scalars but one user-perceived character, so
        // two flags pass a 1...2 limit and three exceed it.
        let key = SettingKey("flags", default: "", rule: .characterCount(1...2))
        try store.set("🇯🇵🇯🇵", for: key)
        XCTAssertEqual(store.value(for: key), "🇯🇵🇯🇵")
        XCTAssertThrowsError(try store.set("🇯🇵🇯🇵🇯🇵", for: key))
    }

    // MARK: - Rejection reasons

    func testRejectionReasonForTooLongNickname() {
        XCTAssertThrowsError(try store.set(String(repeating: "x", count: 21), for: nickname)) { error in
            guard let validationError = error as? SettingValidationError else {
                return XCTFail("expected SettingValidationError, got \(error)")
            }
            XCTAssertEqual(validationError.keyName, "nickname")
            XCTAssertEqual(validationError.reason, "character count must be in 1...20 (got 21)")
            XCTAssertEqual(validationError.description, "nickname: character count must be in 1...20 (got 21)")
        }
    }

    func testRejectionReasonForOutOfRangeHour() {
        XCTAssertThrowsError(try store.set(24, for: reminderHour)) { error in
            guard let validationError = error as? SettingValidationError else {
                return XCTFail("expected SettingValidationError, got \(error)")
            }
            XCTAssertEqual(validationError.keyName, "reminderHour")
            XCTAssertEqual(validationError.reason, "must be in 0...23 (got 24)")
        }
    }

    func testCustomRuleRejectsWithItsOwnReason() {
        let theme = SettingKey(
            "theme",
            default: "system",
            rule: SettingRule<String>(rejectionReason: { value in
                ["system", "light", "dark"].contains(value) ? nil : "unsupported theme: \(value)"
            })
        )
        XCTAssertNoThrow(try store.set("dark", for: theme))
        XCTAssertThrowsError(try store.set("sepia", for: theme)) { error in
            XCTAssertEqual(
                error as? SettingValidationError,
                SettingValidationError(keyName: "theme", reason: "unsupported theme: sepia")
            )
        }
    }

    // MARK: - Rejected writes change nothing

    func testRejectedWriteLeavesStoredValueIntact() throws {
        try store.set("Alice", for: nickname)
        XCTAssertThrowsError(try store.set(String(repeating: "x", count: 21), for: nickname))
        XCTAssertEqual(store.value(for: nickname), "Alice")
    }

    func testRejectedWriteOnUnsetKeyKeepsDefault() {
        XCTAssertThrowsError(try store.set(24, for: reminderHour))
        XCTAssertEqual(store.value(for: reminderHour), 9)
    }

    // MARK: - Keys without a rule

    func testKeyWithoutRuleAcceptsAnyValue() throws {
        let freeText = SettingKey("freeText", default: "")
        try store.set(String(repeating: "x", count: 10_000), for: freeText)
        XCTAssertEqual(store.value(for: freeText), String(repeating: "x", count: 10_000))
    }

    // MARK: - Documented edge behavior

    func testKeysWithSameNameShareStorage() throws {
        let alias = SettingKey("nickname", default: "other")
        try store.set("Alice", for: nickname)
        XCTAssertEqual(store.value(for: alias), "Alice")
    }

    func testTypeMismatchedReadReturnsDefault() throws {
        // Two keys sharing a name with different Value types: the typed
        // read cannot surface the stored value, so it falls back to the
        // reading key's default (documented on InMemorySettingsStore).
        let intAlias = SettingKey("nickname", default: 0)
        try store.set("Alice", for: nickname)
        XCTAssertEqual(store.value(for: intAlias), 0)
    }

    // MARK: - Protocol abstraction

    func testWorksThroughProtocolExistential() throws {
        let abstract: any SettingsStore = InMemorySettingsStore()
        try abstract.set("Alice", for: nickname)
        XCTAssertEqual(abstract.value(for: nickname), "Alice")
        XCTAssertThrowsError(try abstract.set("", for: nickname)) { error in
            XCTAssertNotNil(error as? SettingValidationError)
        }
    }
}
