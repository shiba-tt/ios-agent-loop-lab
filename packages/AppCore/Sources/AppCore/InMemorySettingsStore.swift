/// Dictionary-backed `SettingsStore` for tests, previews, and as the
/// reference implementation of the store contract. Values live only as long
/// as the instance.
///
/// Not thread-safe: confine an instance to one isolation domain. A
/// concurrency-safe or persistent store is a separate adapter conforming to
/// the same protocol.
public final class InMemorySettingsStore: SettingsStore {
    /// Keyed by `SettingKey.name`. A stored value whose runtime type does
    /// not match the reading key's `Value` (two keys sharing a name with
    /// different types) is treated as unset: the read returns the key's
    /// default rather than trapping.
    private var storage: [String: any Sendable] = [:]

    public init() {}

    public func value<Value: Sendable>(for key: SettingKey<Value>) -> Value {
        storage[key.name] as? Value ?? key.defaultValue
    }

    public func set<Value: Sendable>(_ value: Value, for key: SettingKey<Value>) throws {
        if let error = key.validationError(for: value) {
            throw error
        }
        storage[key.name] = value
    }

    public func removeValue<Value: Sendable>(for key: SettingKey<Value>) {
        storage.removeValue(forKey: key.name)
    }
}
