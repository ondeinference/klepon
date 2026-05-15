import SwiftUI

struct SearchView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var recentSearchStore: RecentSearchStore

    @State private var query = ""

    private var results: [GuideEntry] {
        appState.searchService.results(for: query)
    }

    private var recentEntries: [GuideEntry] {
        appState.recentlyViewedStore.entryIDs.compactMap {
            appState.contentRepository.entry(id: $0)
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    if !recentSearchStore.queries.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            SectionHeader("Recent searches")

                            LazyVGrid(
                                columns: [GridItem(.adaptive(minimum: 120), spacing: 10)],
                                alignment: .leading,
                                spacing: 10
                            ) {
                                ForEach(recentSearchStore.queries, id: \.self) { recentQuery in
                                    Button {
                                        query = recentQuery
                                    } label: {
                                        KleponChip(title: recentQuery, icon: "clock")
                                    }
                                    .kleponInteractiveButtonStyle()
                                }
                            }
                        }
                    }

                    SectionHeader(
                        "Start with something familiar",
                        subtitle: "Try a dish, ingredient, or food tradition")

                    ForEach(appState.searchService.suggestions()) { entry in
                        NavigationLink {
                            GuideDetailView(entry: entry)
                        } label: {
                            SearchResultCard(entry: entry)
                        }
                        .simultaneousGesture(
                            TapGesture().onEnded {
                                appState.recentSearchStore.record(entry.title)
                            }
                        )
                        .kleponInteractiveButtonStyle()
                    }

                    if !recentEntries.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            SectionHeader("Recently viewed", subtitle: "Pick up where you left off")

                            ForEach(Array(recentEntries.prefix(3))) { entry in
                                NavigationLink {
                                    GuideDetailView(entry: entry)
                                } label: {
                                    SearchResultCard(entry: entry)
                                }
                                .kleponInteractiveButtonStyle()
                            }
                        }
                    }
                } else if results.isEmpty {
                    EmptyStateView(
                        title: "No exact match yet",
                        message:
                            "Try another spelling or open a dish and ask a private follow-up question from there.",
                        systemImage: "magnifyingglass"
                    )
                } else {
                    SectionHeader("Results", subtitle: "Curated matches from your local guide")

                    ForEach(results) { entry in
                        NavigationLink {
                            GuideDetailView(entry: entry)
                        } label: {
                            SearchResultCard(entry: entry)
                        }
                        .simultaneousGesture(
                            TapGesture().onEnded {
                                appState.recentSearchStore.record(query)
                            }
                        )
                        .kleponInteractiveButtonStyle()
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .background(KleponColor.background.ignoresSafeArea())
        .navigationTitle("Search")
        .searchable(text: $query, prompt: "Try rendang, sambal, or klepon")
        .onSubmit(of: .search) {
            appState.recentSearchStore.record(query)
        }
    }
}

private struct SearchResultCard: View {
    let entry: GuideEntry

    var body: some View {
        KleponCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(entry.title)
                        .font(KleponTypography.cardTitle)
                        .foregroundStyle(KleponColor.textPrimary)

                    Spacer(minLength: 12)

                    Label(entry.kind.displayTitle, systemImage: entry.kind.symbolName)
                        .font(KleponTypography.caption)
                        .foregroundStyle(KleponColor.accentWarm)
                }

                Text(entry.subtitle)
                    .font(KleponTypography.bodySecondary)
                    .foregroundStyle(KleponColor.textSecondary)

                if !entry.tasteNotes.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(Array(entry.tasteNotes.prefix(3)), id: \.self) { note in
                                KleponChip(title: note)
                            }
                        }
                    }
                }
            }
        }
    }
}
