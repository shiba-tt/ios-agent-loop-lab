/// A pure value type for app version strings like "1.2.3" or "1.2.3-beta.1".
///
/// This is the minimal proof of the lab's core architectural decision:
/// domain logic lives in a SwiftPM package with no UIKit/SwiftUI/Xcode
/// dependency, so agents can build and test it on Linux (`swift test`).
///
/// Prerelease identifiers follow SemVer 2.0.0: rule 9 for the grammar
/// (dot-separated ASCII alphanumerics/hyphens, no empty identifiers, no
/// leading zeroes in numeric identifiers) and rule 11 for precedence.
public struct SemanticVersion: Hashable, Comparable, CustomStringConvertible, Sendable {
    public let major: Int
    public let minor: Int
    public let patch: Int

    /// Dot-separated prerelease identifiers, e.g. ["beta", "1"] for
    /// "1.2.3-beta.1". Empty for a release version.
    public let prerelease: [String]

    /// Like the numeric components, `prerelease` is not validated here;
    /// the parsing initializer is the validating entry point.
    public init(major: Int, minor: Int, patch: Int, prerelease: [String] = []) {
        self.major = major
        self.minor = minor
        self.patch = patch
        self.prerelease = prerelease
    }

    /// Parses "MAJOR.MINOR.PATCH" with an optional "-PRERELEASE" suffix.
    /// Returns nil for anything else (missing components, negative numbers,
    /// non-digits, or a prerelease part violating SemVer 2.0.0 rule 9).
    public init?(_ string: String) {
        let core: Substring
        let prerelease: [String]
        // Identifiers may themselves contain "-" (e.g. "1.0.0-x-y-z"),
        // so only the first hyphen separates core from prerelease.
        if let hyphen = string.firstIndex(of: "-") {
            core = string[..<hyphen]
            let identifiers = string[string.index(after: hyphen)...]
                .split(separator: ".", omittingEmptySubsequences: false)
            guard !identifiers.isEmpty,
                  identifiers.allSatisfy(Self.isValidPrereleaseIdentifier)
            else { return nil }
            prerelease = identifiers.map(String.init)
        } else {
            core = string[...]
            prerelease = []
        }

        let parts = core.split(separator: ".", omittingEmptySubsequences: false)
        guard parts.count == 3 else { return nil }
        guard parts.allSatisfy({ !$0.isEmpty && $0.allSatisfy(\.isNumber) }),
              let major = Int(parts[0]),
              let minor = Int(parts[1]),
              let patch = Int(parts[2])
        else { return nil }
        self.init(major: major, minor: minor, patch: patch, prerelease: prerelease)
    }

    public static func < (lhs: SemanticVersion, rhs: SemanticVersion) -> Bool {
        if (lhs.major, lhs.minor, lhs.patch) != (rhs.major, rhs.minor, rhs.patch) {
            return (lhs.major, lhs.minor, lhs.patch) < (rhs.major, rhs.minor, rhs.patch)
        }
        // Equal core: a prerelease ranks below the plain release (rule 11.3).
        if lhs.prerelease.isEmpty || rhs.prerelease.isEmpty {
            return !lhs.prerelease.isEmpty && rhs.prerelease.isEmpty
        }
        for (left, right) in zip(lhs.prerelease, rhs.prerelease) where left != right {
            return Self.identifierPrecedes(left, right)
        }
        // All shared identifiers equal: the shorter list ranks lower (rule 11.4.4).
        return lhs.prerelease.count < rhs.prerelease.count
    }

    public var description: String {
        let core = "\(major).\(minor).\(patch)"
        return prerelease.isEmpty ? core : "\(core)-\(prerelease.joined(separator: "."))"
    }

    // MARK: - SemVer 2.0.0 prerelease rules

    private static func isValidPrereleaseIdentifier(_ identifier: Substring) -> Bool {
        guard !identifier.isEmpty,
              identifier.allSatisfy({ $0.isASCII && ($0.isLetter || $0.isNumber || $0 == "-") })
        else { return false }
        if isNumeric(identifier), identifier.count > 1, identifier.first == "0" {
            return false
        }
        return true
    }

    private static func identifierPrecedes(_ lhs: String, _ rhs: String) -> Bool {
        switch (isNumeric(lhs), isNumeric(rhs)) {
        case (true, true):
            // Numeric identifiers have no leading zeroes, so more digits
            // means a larger number; comparing by digit count avoids Int
            // overflow for arbitrarily long identifiers.
            return lhs.count != rhs.count ? lhs.count < rhs.count : lhs < rhs
        case (true, false):
            // Numeric identifiers rank below alphanumeric ones (rule 11.4.3).
            return true
        case (false, true):
            return false
        case (false, false):
            return lhs < rhs
        }
    }

    private static func isNumeric(_ identifier: some StringProtocol) -> Bool {
        identifier.allSatisfy { $0.isASCII && $0.isNumber }
    }
}
