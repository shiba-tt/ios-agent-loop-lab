import Foundation

/// Scheduling metadata for an in-app announcement: when it is live and
/// which app versions it targets.
///
/// Deciding *whether* to show an announcement is kept separate from
/// fetching or rendering it: callers pass the current date and app version
/// explicitly, so the type has no hidden clock or bundle reads and stays
/// testable on Linux. `Date` is an absolute instant — any calendar or
/// timezone interpretation of "today" is the caller's responsibility.
public struct Announcement: Hashable, Sendable {
    /// First instant (inclusive) at which the announcement may be shown.
    public let from: Date
    /// Last instant (inclusive) at which the announcement may be shown.
    public let to: Date
    /// Lowest app version (inclusive) the announcement targets.
    public let minVersion: SemanticVersion
    /// Highest app version (inclusive) the announcement targets.
    public let maxVersion: SemanticVersion

    /// Bounds are taken as-is: an inverted interval (`from > to` or
    /// `minVersion > maxVersion`) is not an error, it simply matches no
    /// date or version, so `shouldDisplay` is always false for it.
    public init(from: Date, to: Date, minVersion: SemanticVersion, maxVersion: SemanticVersion) {
        self.from = from
        self.to = to
        self.minVersion = minVersion
        self.maxVersion = maxVersion
    }

    /// Whether the announcement should be shown at `date` to a user running
    /// `appVersion`: true exactly when the date falls within the display
    /// period and the version within the target range, both inclusive of
    /// their boundaries.
    ///
    /// Versions compare by SemVer precedence, so a prerelease of the lower
    /// bound (e.g. "1.2.0-rc.1" against `minVersion` "1.2.0") sorts below
    /// the range and is not displayed.
    public func shouldDisplay(on date: Date, appVersion: SemanticVersion) -> Bool {
        from <= date && date <= to
            && minVersion <= appVersion && appVersion <= maxVersion
    }
}
