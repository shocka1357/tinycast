import Foundation

@main
struct AliasStoreTest {
    @MainActor
    static func main() {
        var failures = 0

        func check(_ description: String, _ condition: @autoclosure () -> Bool) {
            if condition() {
                print("PASS  \(description)")
            } else {
                print("FAIL  \(description)")
                failures += 1
            }
        }

        let suite = "tinycast-alias-test-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = AliasStore(defaults: defaults)

        store.setAlias("go", for: "example-entry")
        check("an ordinary alias is not instant", !store.isInstantMatch("go", for: "example-entry"))

        store.setInstant(true, for: "example-entry")
        check("an exact alias is instant", store.isInstantMatch("go", for: "example-entry"))
        check("an alias prefix is not instant", !store.isInstantMatch("g", for: "example-entry"))
        check("matching uses the launcher's fold", store.isInstantMatch("GO", for: "example-entry"))

        store.setAlias("open", for: "example-entry")
        check("editing preserves the instant flag", store.isInstantMatch("open", for: "example-entry"))
        store.setAlias("", for: "example-entry")
        check("clearing an alias clears its instant flag", !store.isInstant(for: "example-entry"))

        store.setInstant(true, for: "missing")
        check("an entry without an alias cannot be instant", !store.isInstant(for: "missing"))

        store.replace(["example-entry": "go"])
        store.replaceInstantKeys(["example-entry", "missing"])
        check("backup restore keeps only real aliases", store.instantKeys == ["example-entry"])
        store.removeKeys(["example-entry"])
        check("removing an entry removes its instant flag", store.instantKeys.isEmpty)

        if failures > 0 { exit(1) }
    }
}
