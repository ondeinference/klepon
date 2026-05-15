import SwiftUI

struct SavedView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var favoritesStore: FavoritesStore

    private var savedEntries: [GuideEntry] {
        appState.contentRepository.entries.filter { favoritesStore.favoriteIDs.contains($0.id) }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if savedEntries.isEmpty {
                    EmptyStateView(
                        title: "Save dishes you want to revisit",
                        message:
                            "Build a shortlist as you browse so it is easy to come back to dishes, ingredients, and traditions later.",
                        systemImage: "heart"
                    )
                } else {
                    SectionHeader(
                        "Your shortlist", subtitle: "A calm place to keep what you want to remember"
                    )

                    ForEach(savedEntries) { entry in
                        KleponCard {
                            HStack(alignment: .top, spacing: 12) {
                                NavigationLink {
                                    GuideDetailView(entry: entry)
                                } label: {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text(entry.title)
                                            .font(KleponTypography.cardTitle)
                                            .foregroundStyle(KleponColor.textPrimary)

                                        Text(entry.summary)
                                            .font(KleponTypography.bodySecondary)
                                            .foregroundStyle(KleponColor.textSecondary)
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                .kleponInteractiveButtonStyle()

                                Button {
                                    favoritesStore.toggle(entry.id)
                                } label: {
                                    Image(systemName: "heart.slash")
                                        .foregroundStyle(KleponColor.highlight)
                                        .padding(10)
                                        .background(Circle().fill(KleponColor.surfaceSecondary))
                                }
                                .kleponInteractiveButtonStyle()
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .background(KleponColor.background.ignoresSafeArea())
        .navigationTitle("Saved")
    }
}
