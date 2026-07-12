/// A validation rule for a setting value: a function from a candidate value
/// to the reason it is rejected, where `nil` means the value is acceptable.
///
/// Factory methods cover the common cases (numeric ranges, string length);
/// use the initializer for bespoke rules. Keeping the rule a plain value on
/// the key — rather than logic inside a store — is what lets every
/// `SettingsStore` implementation accept and reject exactly the same writes.
public struct SettingRule<Value: Sendable>: Sendable {
    /// Returns why `value` is unacceptable, or nil when it passes.
    public let rejectionReason: @Sendable (Value) -> String?

    public init(rejectionReason: @escaping @Sendable (Value) -> String?) {
        self.rejectionReason = rejectionReason
    }
}

extension SettingRule where Value: Comparable {
    /// Accepts values within `allowed`, bounds inclusive.
    public static func range(_ allowed: ClosedRange<Value>) -> SettingRule {
        SettingRule(rejectionReason: { value in
            allowed.contains(value)
                ? nil
                : "must be in \(allowed.lowerBound)...\(allowed.upperBound) (got \(value))"
        })
    }
}

extension SettingRule where Value == String {
    /// Accepts strings whose character count falls within `allowed`, bounds
    /// inclusive. Characters are user-perceived characters (grapheme
    /// clusters), so a flag emoji counts as one even though it is several
    /// Unicode scalars — the natural reading of a "nickname length" limit.
    public static func characterCount(_ allowed: ClosedRange<Int>) -> SettingRule {
        SettingRule(rejectionReason: { value in
            allowed.contains(value.count)
                ? nil
                : "character count must be in \(allowed.lowerBound)...\(allowed.upperBound) (got \(value.count))"
        })
    }
}

/// Why a write was rejected: the key it targeted and the reason produced by
/// the key's rule. Thrown by `SettingsStore.set(_:for:)`.
public struct SettingValidationError: Error, Hashable, Sendable, CustomStringConvertible {
    /// `SettingKey.name` of the key the rejected write targeted.
    public let keyName: String
    /// Human-readable reason from the key's rule.
    public let reason: String

    public init(keyName: String, reason: String) {
        self.keyName = keyName
        self.reason = reason
    }

    public var description: String { "\(keyName): \(reason)" }
}

/// A typed settings key: the storage name, the default returned while the
/// key is unset, and an optional rule constraining writable values.
///
/// A key carries the whole schema of its setting, so declare each setting
/// once as a shared constant. The rule travels with the key value, not with
/// the store: a second key reusing the same name (with another rule or
/// `Value` type) addresses the same slot but bypasses the original contract.
public struct SettingKey<Value: Sendable>: Sendable {
    /// Storage identifier. Keys with the same name address the same slot.
    public let name: String
    /// Returned by reads while no value is stored. Returned as-is, without
    /// passing through `rule` — choose a default that satisfies it.
    public let defaultValue: Value
    /// Constraint on writable values; nil accepts everything.
    public let rule: SettingRule<Value>?

    public init(_ name: String, default defaultValue: Value, rule: SettingRule<Value>? = nil) {
        self.name = name
        self.defaultValue = defaultValue
        self.rule = rule
    }

    /// The error a store must throw when asked to write `value` to this
    /// key, or nil when the value is acceptable. Exposed so that every
    /// `SettingsStore` implementation enforces the same contract instead of
    /// re-deriving it.
    public func validationError(for value: Value) -> SettingValidationError? {
        guard let reason = rule?.rejectionReason(value) else { return nil }
        return SettingValidationError(keyName: name, reason: reason)
    }
}
