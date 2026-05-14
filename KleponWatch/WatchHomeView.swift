import SwiftUI

private struct WatchGuideStore {
    let entries: [GuideEntry] = WatchContentLoader().loadEntries()

    var featuredEntries: [GuideEntry] {
        Array(entries.filter(\.isFeatured).prefix(4))
    }

    var browseEntries: [GuideEntry] {
        let featuredIDs = Set(featuredEntries.map(\.id))
        let remaining = entries.filter { !featuredIDs.contains($0.id) }
        return Array((featuredEntries + remaining).prefix(8))
    }
}

struct WatchHomeView: View {
    private let store = WatchGuideStore()

    var body: some View {
        NavigationStack {
            if store.entries.isEmpty {
                ScrollView {
                    VStack(spacing: 10) {
                        Image(systemName: "fork.knife.circle")
                            .font(.title2)
                            .foregroundStyle(.secondary)

                        Text("Guide unavailable")
                            .font(.headline)

                        Text(
                            "Open Klepon on iPhone first if you want the fuller guide and private follow-up answers."
                        )
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                    }
                    .padding()
                }
                .navigationTitle("Klepon")
            } else {
                List {
                    if !store.featuredEntries.isEmpty {
                        Section("Start here") {
                            ForEach(store.featuredEntries) { entry in
                                NavigationLink {
                                    WatchEntryDetailView(entry: entry)
                                } label: {
                                    EntryRow(entry: entry)
                                }
                            }
                        }
                    }

                    Section("Browse") {
                        ForEach(store.browseEntries) { entry in
                            NavigationLink {
                                WatchEntryDetailView(entry: entry)
                            } label: {
                                EntryRow(entry: entry)
                            }
                        }
                    }

                    Section {
                        Text(
                            "Browse on watch. Use the iPhone app for the full guide and private follow-up answers."
                        )
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    }
                }
                .navigationTitle("Klepon")
            }
        }
    }
}

private struct EntryRow: View {
    let entry: GuideEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(entry.title)
                .font(.headline)

            Text(entry.subtitle)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
        .padding(.vertical, 2)
    }
}

private struct WatchEntryDetailView: View {
    let entry: GuideEntry

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text(entry.title)
                    .font(.headline)

                Text(entry.subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                if let region = entry.region {
                    Text(region)
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.secondary)
                }

                Divider()

                Text(entry.summary)
                    .font(.footnote)

                if !entry.tasteNotes.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Taste")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(.secondary)

                        ForEach(Array(entry.tasteNotes.prefix(3)), id: \.self) { note in
                            Text("• \(note)")
                                .font(.footnote)
                        }
                    }
                }

                if !entry.highlights.isEmpty {
                    Divider()

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Quick notes")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(.secondary)

                        ForEach(Array(entry.highlights.prefix(3)), id: \.self) { note in
                            Text("• \(note)")
                                .font(.footnote)
                        }
                    }
                }

                Divider()

                Text(
                    "Open Klepon on iPhone if you want the fuller guide and on-device follow-up answers."
                )
                .font(.footnote)
                .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
        }
        .navigationTitle(entry.title)
    }
}

#Preview {
    WatchHomeView()
}
