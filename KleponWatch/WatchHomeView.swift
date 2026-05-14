import SwiftUI

private struct WatchGuideStore {
    let entries: [GuideEntry] = WatchContentLoader().loadEntries()

    var featuredEntries: [GuideEntry] {
        Array(entries.filter(\.isFeatured).prefix(3))
    }

    var browseEntries: [GuideEntry] {
        let featuredIDs = Set(featuredEntries.map(\.id))
        let remaining = entries.filter { !featuredIDs.contains($0.id) }
        return Array((featuredEntries + remaining).prefix(6))
    }
}

struct WatchHomeView: View {
    private let store = WatchGuideStore()

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 14) {
                    introCard

                    if store.entries.isEmpty {
                        emptyStateCard
                    } else {
                        if !store.featuredEntries.isEmpty {
                            WatchKleponSectionHeader(
                                "Start here",
                                subtitle: "A warm first taste of the guide"
                            )

                            ForEach(store.featuredEntries) { entry in
                                NavigationLink {
                                    WatchEntryDetailView(entry: entry)
                                } label: {
                                    WatchEntryCard(entry: entry)
                                }
                                .buttonStyle(.plain)
                            }
                        }

                        WatchKleponSectionHeader(
                            "Browse",
                            subtitle: "A few essentials that feel good on the wrist"
                        )

                        ForEach(store.browseEntries) { entry in
                            NavigationLink {
                                WatchEntryDetailView(entry: entry)
                            } label: {
                                WatchEntryCard(entry: entry)
                            }
                            .buttonStyle(.plain)
                        }

                        WatchKleponFooterCard(
                            message:
                                "Browse on watch. Use the iPhone app for the fuller guide and private follow-up answers."
                        )
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
            }
            .background(KleponColor.background.ignoresSafeArea())
            .navigationTitle("Klepon")
        }
    }

    private var introCard: some View {
        WatchKleponCard(padding: 16) {
            VStack(alignment: .leading, spacing: 10) {
                Text("Taste of Indonesia")
                    .font(WatchKleponTypography.heroTitle)
                    .foregroundStyle(KleponColor.textPrimary)

                Text(
                    "A calmer way to browse dishes, flavors, and food traditions from your wrist."
                )
                .font(WatchKleponTypography.body)
                .foregroundStyle(KleponColor.textSecondary)
                .lineSpacing(2)

                HStack(spacing: 8) {
                    WatchKleponChip(title: "Curated")
                    WatchKleponChip(title: "Private", icon: "lock.fill")
                }
            }
        }
    }

    private var emptyStateCard: some View {
        WatchKleponCard {
            VStack(alignment: .leading, spacing: 10) {
                Image(systemName: "fork.knife.circle.fill")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(KleponColor.accent)

                Text("Guide unavailable")
                    .font(WatchKleponTypography.cardTitle)
                    .foregroundStyle(KleponColor.textPrimary)

                Text(
                    "Open Klepon on iPhone first if you want the fuller guide and private follow-up answers."
                )
                .font(WatchKleponTypography.bodySecondary)
                .foregroundStyle(KleponColor.textSecondary)
                .lineSpacing(2)
            }
        }
    }
}

private struct WatchEntryCard: View {
    let entry: GuideEntry

    var body: some View {
        WatchKleponCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top, spacing: 10) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(entry.title)
                            .font(WatchKleponTypography.cardTitle)
                            .foregroundStyle(KleponColor.textPrimary)
                            .lineLimit(2)

                        Text(entry.subtitle)
                            .font(WatchKleponTypography.bodySecondary)
                            .foregroundStyle(KleponColor.textSecondary)
                            .lineLimit(2)
                    }

                    Spacer(minLength: 0)

                    Image(systemName: entry.kind.symbolName)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(KleponColor.accentWarm)
                        .padding(8)
                        .background(Circle().fill(KleponColor.surfaceSecondary))
                }

                HStack(spacing: 8) {
                    WatchKleponChip(title: entry.kind.displayTitle, icon: entry.kind.symbolName)

                    if let region = entry.region {
                        Text(region)
                            .font(WatchKleponTypography.caption)
                            .foregroundStyle(KleponColor.accentWarm)
                            .lineLimit(1)
                    }
                }
            }
        }
    }
}

private struct WatchEntryDetailView: View {
    let entry: GuideEntry

    private var tasteItems: [String] {
        Array(entry.tasteNotes.prefix(4))
    }

    private var highlightItems: [String] {
        Array(entry.highlights.prefix(4))
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 12) {
                WatchKleponCard(padding: 16) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(entry.title)
                            .font(WatchKleponTypography.heroTitle)
                            .foregroundStyle(KleponColor.textPrimary)

                        Text(entry.subtitle)
                            .font(WatchKleponTypography.body)
                            .foregroundStyle(KleponColor.textSecondary)
                            .lineSpacing(2)

                        HStack(spacing: 8) {
                            WatchKleponChip(
                                title: entry.kind.displayTitle,
                                icon: entry.kind.symbolName
                            )

                            if let region = entry.region {
                                Text(region)
                                    .font(WatchKleponTypography.caption)
                                    .foregroundStyle(KleponColor.accentWarm)
                                    .lineLimit(1)
                            }
                        }
                    }
                }

                WatchKleponCard {
                    Text(entry.summary)
                        .font(WatchKleponTypography.body)
                        .foregroundStyle(KleponColor.textSecondary)
                        .lineSpacing(2)
                }

                if !tasteItems.isEmpty {
                    WatchKleponCard {
                        VStack(alignment: .leading, spacing: 10) {
                            WatchKleponSectionHeader("Taste")
                            WatchKleponChipGrid(items: tasteItems)
                        }
                    }
                }

                if !highlightItems.isEmpty {
                    WatchKleponCard {
                        VStack(alignment: .leading, spacing: 10) {
                            WatchKleponSectionHeader("Quick notes")

                            ForEach(highlightItems, id: \.self) { note in
                                HStack(alignment: .top, spacing: 8) {
                                    Circle()
                                        .fill(KleponColor.accentWarm)
                                        .frame(width: 5, height: 5)
                                        .padding(.top, 5)

                                    Text(note)
                                        .font(WatchKleponTypography.bodySecondary)
                                        .foregroundStyle(KleponColor.textSecondary)
                                        .lineSpacing(2)
                                }
                            }
                        }
                    }
                }

                WatchKleponFooterCard(
                    message:
                        "Open Klepon on iPhone if you want the fuller guide and on-device follow-up answers."
                )
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
        }
        .background(KleponColor.background.ignoresSafeArea())
        .navigationTitle(entry.title)
    }
}

#Preview {
    WatchHomeView()
}
