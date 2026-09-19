import Foundation

/// The user's per-entry aliases, keyed like favorites and ranking by `preferenceKey`.
@MainActor
@Observable
final class AliasStore {
    private let defaults: UserDefaults
    private let defaultsKey = "launcherAliases"
    private let instantDefaultsKey = "instantLauncherAliases"

    private(set) var aliases: [String: String]
    private(set) var instantKeys: Set<String>
    /// AppIndex includes this in its result key, invalidating a ranking when an alias changes.
    private(set) var revision = 0

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let storedAliases = defaults.dictionary(forKey: defaultsKey) as? [String: String] ?? [:]
        let storedInstantKeys = Set(defaults.stringArray(forKey: instantDefaultsKey) ?? [])
        aliases = storedAliases
        instantKeys = storedInstantKeys.intersection(storedAliases.keys)
    }

    func alias(for entryKey: String) -> String? { aliases[entryKey] }

    func isInstant(for entryKey: String) -> Bool { instantKeys.contains(entryKey) }

    func isInstantMatch(_ query: String, for entryKey: String) -> Bool {
        guard instantKeys.contains(entryKey), let alias = aliases[entryKey] else { return false }
        return FuzzyMatch.match(query: query, candidate: alias)?.tier == .exact
    }

    /// Stored as typed — trimming here would eat the space mid-word — but blank still means none.
    func setAlias(_ alias: String, for entryKey: String) {
        let value = alias.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : alias
        guard aliases[entryKey] != value else { return }
        aliases[entryKey] = value
        if value == nil { instantKeys.remove(entryKey) }
        revision &+= 1
        persist()
    }

    func setInstant(_ instant: Bool, for entryKey: String) {
        let changed: Bool
        if instant, aliases[entryKey] != nil {
            changed = instantKeys.insert(entryKey).inserted
        } else {
            changed = instantKeys.remove(entryKey) != nil
        }
        guard changed else { return }
        revision &+= 1
        persist()
    }

    func removeKeys(_ keys: Set<String>) {
        let remaining = aliases.filter { !keys.contains($0.key) }
        guard remaining.count != aliases.count else { return }
        aliases = remaining
        instantKeys.subtract(keys)
        revision &+= 1
        persist()
    }

    /// Replace the whole table at once (used when importing a settings backup).
    func replace(_ new: [String: String]) {
        // An import obeys the same rule as typing: blank means none, or it lands unclearable.
        aliases = new.filter { !$0.value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        instantKeys.formIntersection(aliases.keys)
        revision &+= 1
        persist()
    }

    func replaceInstantKeys(_ keys: Set<String>) {
        let value = keys.intersection(aliases.keys)
        guard value != instantKeys else { return }
        instantKeys = value
        revision &+= 1
        persist()
    }

    private func persist() {
        defaults.set(aliases, forKey: defaultsKey)
        defaults.set(Array(instantKeys), forKey: instantDefaultsKey)
    }
}
