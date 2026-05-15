import SwiftUI

struct DiscoverView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var guideEngine: OndeGuideEngine
    @EnvironmentObject private var recentlyViewedStore: RecentlyViewedStore

    @Binding var showingSettings: Bool

    private var featuredEntry: GuideEntry? {
        let featuredEntries = appState.contentRepository.featuredEntries
        guard !featuredEntries.isEmpty else { return nil }
        let dayIndex = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 0
        return featuredEntries[dayIndex % featuredEntries.count]
    }

    private var starterEntries: [GuideEntry] {
        Array(appState.contentRepository.featuredEntries.prefix(4))
    }

    private var featuredTasteNotes: [String] {
        ["Private on your device", "Curated first", "Warm follow-up answers"]
    }

    private var recentlyViewedEntries: [GuideEntry] {
        recentlyViewedStore.entryIDs.compactMap { appState.contentRepository.entry(id: $0) }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                introSection

                if let featuredEntry {
                    SectionHeader("Featured today", subtitle: "A thoughtful place to start")

                    NavigationLink {
                        GuideDetailView(entry: featuredEntry)
                    } label: {
                        FeaturedEntryCard(entry: featuredEntry)
                    }
                    .buttonStyle(.plain)
                } else {
                    EmptyStateView(
                        title: "Curated dishes are on the way",
                        message:
                            "Add a few starter entries to your bundled content and Discover will come to life.",
                        systemImage: "fork.knife.circle"
                    )
                }

                if !appState.contentRepository.collections.isEmpty {
                    VStack(alignment: .leading, spacing: 18) {
                        SectionHeader(
                            "Browse by collection",
                            subtitle: "Curated paths through taste, place, and tradition")

                        ForEach(appState.contentRepository.collections) { collection in
                            CollectionRail(
                                collection: collection,
                                entries: appState.contentRepository.entries(in: collection))
                        }
                    }
                }

                if !starterEntries.isEmpty {
                    VStack(alignment: .leading, spacing: 14) {
                        SectionHeader(
                            "Good first dishes",
                            subtitle: "Iconic flavors to open the app with confidence")

                        ForEach(starterEntries) { entry in
                            NavigationLink {
                                GuideDetailView(entry: entry)
                            } label: {
                                EntryListCard(entry: entry)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                if !recentlyViewedEntries.isEmpty {
                    VStack(alignment: .leading, spacing: 14) {
                        SectionHeader(
                            "Pick up where you left off",
                            subtitle: "Recently opened dishes, ingredients, and food notes")

                        ForEach(Array(recentlyViewedEntries.prefix(3))) { entry in
                            NavigationLink {
                                GuideDetailView(entry: entry)
                            } label: {
                                EntryListCard(entry: entry)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                privateGuideCard
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .background(KleponColor.background.ignoresSafeArea())
        .navigationTitle("Klepon")
        .kleponLargeNavigationTitle()
        .toolbar {
            ToolbarItem(placement: .kleponPrimaryAction) {
                Button {
                    showingSettings = true
                } label: {
                    Image(systemName: "gearshape.2")
                }
                .tint(KleponColor.accent)
            }
        }
    }

    private var introSection: some View {
        KleponCard(padding: 22) {
            VStack(alignment: .leading, spacing: 14) {
                Text("Taste of Indonesia")
                    .font(KleponTypography.heroTitle)
                    .foregroundStyle(KleponColor.textPrimary)

                Text(
                    "Explore dishes, ingredients, and food traditions with a guide that feels calm, personal, and private on your device."
                )
                .font(KleponTypography.body)
                .foregroundStyle(KleponColor.textSecondary)

                FlexibleDiscoverTagLayout(items: featuredTasteNotes)
            }
        }
    }

    private var privateGuideCard: some View {
        KleponCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: guideEngine.availability == .ready ? "lock.fill" : "sparkles")
                        .font(.title3)
                        .foregroundStyle(KleponColor.accent)
                        .padding(10)
                        .background(Circle().fill(KleponColor.surfaceSecondary))

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Ask privately")
                            .font(KleponTypography.cardTitle)
                            .foregroundStyle(KleponColor.textPrimary)

                        Text(guideEngine.availability.title)
                            .font(KleponTypography.caption)
                            .foregroundStyle(
                                guideEngine.availability.isFailure
                                    ? KleponColor.highlight : KleponColor.accentWarm)
                    }
                }

                Text(guideEngine.availability.detail)
                    .font(KleponTypography.bodySecondary)
                    .foregroundStyle(KleponColor.textSecondary)

                HStack(spacing: 10) {
                    KleponChip(
                        title: guideEngine.estimatedDownloadDescription, icon: "arrow.down.circle")
                    KleponChip(title: guideEngine.storageUsedDescription, icon: "internaldrive")
                }

                if guideEngine.availability == .ready {
                    Text(
                        "Open any dish to ask taste, ingredient, or comparison questions without leaving the guide."
                    )
                    .font(KleponTypography.caption)
                    .foregroundStyle(KleponColor.accentWarm)
                }

                KleponActionButton(
                    title: guideEngine.availability.actionTitle,
                    systemImage: guideEngine.availability == .ready
                        ? "checkmark.circle.fill" : "arrow.down.circle",
                    isLoading: guideEngine.availability.isBusy,
                    isDisabled: guideEngine.availability == .ready
                ) {
                    Task {
                        await guideEngine.prepareIfNeeded(
                            forceReload: guideEngine.availability.isFailure)
                    }
                }
            }
        }
    }
}

private struct FeaturedEntryCard: View {
    let entry: GuideEntry

    var body: some View {
        KleponCard(padding: 20) {
            VStack(alignment: .leading, spacing: 14) {
                GuideArtworkView(entry: entry, height: 178)

                KleponChip(title: entry.kind.displayTitle, icon: entry.kind.symbolName)

                Text(entry.summary)
                    .font(KleponTypography.body)
                    .foregroundStyle(KleponColor.textSecondary)

                FlexibleDiscoverTagLayout(items: Array(entry.tasteNotes.prefix(3)))
            }
        }
    }
}

private struct EntryListCard: View {
    let entry: GuideEntry

    var body: some View {
        KleponCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(entry.title)
                        .font(KleponTypography.cardTitle)
                        .foregroundStyle(KleponColor.textPrimary)

                    Spacer(minLength: 12)

                    Image(systemName: entry.kind.symbolName)
                        .foregroundStyle(KleponColor.accentWarm)
                }

                Text(entry.summary)
                    .font(KleponTypography.bodySecondary)
                    .foregroundStyle(KleponColor.textSecondary)
                    .lineLimit(2)
            }
        }
    }
}

private struct FlexibleDiscoverTagLayout: View {
    let items: [String]

    var body: some View {
        LazyVGrid(
            columns: [GridItem(.adaptive(minimum: 110), spacing: 10)], alignment: .leading,
            spacing: 10
        ) {
            ForEach(items, id: \.self) { item in
                KleponChip(title: item)
            }
        }
    }
}

private struct CollectionRail: View {
    let collection: GuideCollection
    let entries: [GuideEntry]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(collection.title)
                    .font(KleponTypography.cardTitle)
                    .foregroundStyle(KleponColor.textPrimary)

                Text(collection.subtitle)
                    .font(KleponTypography.bodySecondary)
                    .foregroundStyle(KleponColor.textSecondary)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(entries) { entry in
                        NavigationLink {
                            GuideDetailView(entry: entry)
                        } label: {
                            VStack(alignment: .leading, spacing: 10) {
                                Text(entry.title)
                                    .font(KleponTypography.cardTitle)
                                    .foregroundStyle(KleponColor.textPrimary)
                                    .lineLimit(2)

                                Text(entry.subtitle)
                                    .font(KleponTypography.caption)
                                    .foregroundStyle(KleponColor.accentWarm)
                                    .lineLimit(2)

                                Spacer(minLength: 0)

                                Text(entry.summary)
                                    .font(KleponTypography.bodySecondary)
                                    .foregroundStyle(KleponColor.textSecondary)
                                    .lineLimit(3)
                            }
                            .padding(16)
                            .frame(width: 220, alignment: .leading)
                            .frame(minHeight: 160, alignment: .topLeading)
                            .background(
                                RoundedRectangle(cornerRadius: 22, style: .continuous)
                                    .fill(KleponColor.surfaceSecondary)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}
