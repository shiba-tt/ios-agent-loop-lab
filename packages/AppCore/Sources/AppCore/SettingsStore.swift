/// Type-safe read/write access to user settings, abstracted from any
/// concrete persistence so the domain layer never touches UserDefaults and
/// stays buildable and testable on Linux. A UserDefaults-backed adapter is
/// an app-target concern and conforms to this protocol there.
///
/// The schema of each setting (default value, validation rule) lives on
/// `SettingKey`, not on the store. Implementations must gate writes through
/// `SettingKey.validationError(for:)`, so swapping the persistence backend
/// never changes which writes are accepted.
///
/// Stores are reference types: a settings store is shared mutable state by
/// nature, and value-type conformances would silently fork that state.
public protocol SettingsStore: AnyObject {
    /// Returns the value stored for `key`, or `key.defaultValue` while the
    /// key is unset. Reads are total — they never fail.
    func value<Value: Sendable>(for key: SettingKey<Value>) -> Value

    /// Stores `value` for `key` after validating it against the key's rule.
    /// A rejected write throws `SettingValidationError` — whose fields carry
    /// the rejection reason — and leaves the store unchanged.
    func set<Value: Sendable>(_ value: Value, for key: SettingKey<Value>) throws

    /// Forgets any stored value for `key`, so reads fall back to the
    /// default. Removing an unset key is a no-op.
    func removeValue<Value: Sendable>(for key: SettingKey<Value>)
}
