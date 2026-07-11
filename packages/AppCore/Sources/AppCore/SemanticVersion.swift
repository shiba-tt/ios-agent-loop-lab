/// A pure value type for app version strings like "1.2.3".
///
/// This is the minimal proof of the lab's core architectural decision:
/// domain logic lives in a SwiftPM package with no UIKit/SwiftUI/Xcode
/// dependency, so agents can build and test it on Linux (`swift test`).
public struct SemanticVersion: Hashable, Comparable, CustomStringConvertible, Sendable {
    public let major: Int
    public let minor: Int
    public let patch: Int

    public init(major: Int, minor: Int, patch: Int) {
        self.major = major
        self.minor = minor
        self.patch = patch
    }

    /// Parses "MAJOR.MINOR.PATCH". Returns nil for anything else
    /// (missing components, negative numbers, non-digits).
    public init?(_ string: String) {
        let parts = string.split(separator: ".", omittingEmptySubsequences: false)
        guard parts.count == 3 else { return nil }
        guard parts.allSatisfy({ !$0.isEmpty && $0.allSatisfy(\.isNumber) }),
              let major = Int(parts[0]),
              let minor = Int(parts[1]),
              let patch = Int(parts[2])
        else { return nil }
        self.init(major: major, minor: minor, patch: patch)
    }

    public static func < (lhs: SemanticVersion, rhs: SemanticVersion) -> Bool {
        (lhs.major, lhs.minor, lhs.patch) < (rhs.major, rhs.minor, rhs.patch)
    }

    public var description: String {
        "\(major).\(minor).\(patch)"
    }
}
