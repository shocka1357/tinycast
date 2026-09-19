import SwiftUI

struct ApplicationsSettingsView: View {
    var body: some View {
        Form {
            // Scopes first: they decide what gets indexed, so they read before the results.
            SearchScopesSection()

            LauncherItemsSection(
                kind: .application,
                anchor: .applicationsApplications,
                searchPrompt: "Search applications…")
        }
        .formStyle(.grouped)
        .settingsScrollTarget(.applications)
        .releasesFocusOnOutsideClick()
    }
}

/// Every launcher alias in one place, including commands and panes that normally live elsewhere.
struct AliasesSettingsView: View {
    @Environment(AppIndex.self) private var appIndex
    @Environment(AliasStore.self) private var aliases
    @State private var query = ""
    @State private var picking = false

    private var visibleKeys: [String] {
        aliases.aliases.keys
            .filter(matchesQuery)
            .sorted { presentation(for: $0).name.localizedStandardCompare(
                presentation(for: $1).name) == .orderedAscending }
    }

    var body: some View {
        Form {
            Section {
                SettingsFilterField(prompt: "Search aliases…", query: $query)

                if visibleKeys.isEmpty {
                    Text(emptyMessage)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                } else {
                    ForEach(visibleKeys, id: \.self) { key in
                        aliasRow(key)
                    }
                }

                Button("Add Alias…") { picking = true }
                    .popover(isPresented: $picking, arrowEdge: .bottom) {
                        AliasPickerPopover(excluded: Set(aliases.aliases.keys)) {
                            picking = false
                        }
                    }
            } header: {
                SettingsSectionHeader(.aliasesAliases)
            } footer: {
                Text("The bolt makes an exact alias launch immediately. Use × to remove an alias; aliases without the bolt still wait for Return.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .settingsScrollTarget(.aliases)
        .releasesFocusOnOutsideClick()
    }

    @ViewBuilder
    private func aliasRow(_ key: String) -> some View {
        let item = presentation(for: key)
        SettingsRow(title: item.name, subtitle: item.subtitle) {
            if let entry = item.entry {
                AppIconView(app: entry).frame(width: 18, height: 18)
            } else {
                Image(systemName: "questionmark.app.dashed")
                    .frame(width: 18, height: 18)
                    .foregroundStyle(.secondary)
            }
        } trailing: {
            AliasField(key: key, name: item.name)
        }
    }

    private var emptyMessage: String {
        query.isEmpty ? "No aliases yet." : "No aliases match “\(query)”."
    }

    private func matchesQuery(_ key: String) -> Bool {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return true }
        let item = presentation(for: key)
        return [item.name, item.subtitle, aliases.alias(for: key) ?? "", key]
            .contains { FuzzyMatch.match(query: query, candidate: $0) != nil }
    }

    private func presentation(for key: String) -> AliasPresentation {
        if let entry = appIndex.apps.first(where: { $0.preferenceKey == key }) {
            return AliasPresentation(name: entry.name, subtitle: entry.kindLabel, entry: entry)
        }
        return AliasPresentation(name: key, subtitle: "Unavailable item", entry: nil)
    }
}

private struct AliasPresentation {
    let name: String
    let subtitle: String
    let entry: AppEntry?
}

/// Two-step add flow: pick any launcher item, then choose its alias and instant behaviour.
private struct AliasPickerPopover: View {
    let excluded: Set<String>
    let onFinish: () -> Void

    @Environment(AppIndex.self) private var appIndex
    @Environment(AliasStore.self) private var aliases
    @State private var query = ""
    @State private var selected: AppEntry?
    @State private var draft = ""
    @State private var instant = false
    @FocusState private var aliasFocused: Bool

    private var candidates: [AppEntry] {
        let source = query.isEmpty ? appIndex.apps : appIndex.matches(query)
        var seen = Set<String>()
        return source.filter { entry in
            !excluded.contains(entry.preferenceKey) && seen.insert(entry.preferenceKey).inserted
        }
    }

    var body: some View {
        Group {
            if let selected {
                editor(selected)
            } else {
                picker
            }
        }
        .frame(width: 280, height: 300)
    }

    private var picker: some View {
        VStack(spacing: 0) {
            TextField("Search apps and commands…", text: $query)
                .textFieldStyle(.roundedBorder)
                .padding(Theme.Spacing.md)
            Divider()
            if candidates.isEmpty {
                ContentUnavailableView.search(text: query)
            } else {
                ScrollView {
                    LazyVStack(spacing: 1) {
                        ForEach(candidates) { entry in
                            Button { selected = entry } label: {
                                HStack(spacing: Theme.Spacing.lg) {
                                    AppIconView(app: entry).frame(width: 20, height: 20)
                                    VStack(alignment: .leading, spacing: Theme.Spacing.xxs) {
                                        Text(entry.name).lineLimit(1)
                                        Text(entry.kindLabel)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                            .lineLimit(1)
                                    }
                                    Spacer(minLength: 0)
                                }
                                .padding(.horizontal, Theme.Spacing.md)
                                .padding(.vertical, Theme.Spacing.sm)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(Theme.Spacing.sm)
                }
            }
        }
    }

    private func editor(_ entry: AppEntry) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
            Button {
                selected = nil
                draft = ""
                instant = false
            } label: {
                Label("Choose another item", systemImage: "chevron.left")
            }
            .buttonStyle(.plain)

            HStack(spacing: Theme.Spacing.lg) {
                AppIconView(app: entry).frame(width: 32, height: 32)
                VStack(alignment: .leading, spacing: Theme.Spacing.xxs) {
                    Text(entry.name).font(.headline)
                    Text(entry.kindLabel).font(.caption).foregroundStyle(.secondary)
                }
            }

            TextField("Alias", text: $draft)
                .textFieldStyle(.roundedBorder)
                .focused($aliasFocused)
                .onSubmit { save(entry) }

            Toggle("Launch instantly on an exact match", isOn: $instant)

            Spacer()
            HStack {
                Spacer()
                Button("Cancel", action: onFinish)
                Button("Add Alias") { save(entry) }
                    .buttonStyle(.borderedProminent)
                    .disabled(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(Theme.Spacing.lg)
        .onAppear { aliasFocused = true }
    }

    private func save(_ entry: AppEntry) {
        guard !draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        aliases.setAlias(draft, for: entry.preferenceKey)
        aliases.setInstant(instant, for: entry.preferenceKey)
        onFinish()
    }
}
