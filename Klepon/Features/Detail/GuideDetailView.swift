import SwiftUI

struct GuideDetailView: View {
    let entry: GuideEntry

    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var favoritesStore: FavoritesStore
    @EnvironmentObject private var recentlyViewedStore: RecentlyViewedStore

    @State private var showingAskSheet = false
    @State private var showingUnsupportedAlert = false
    @State private var initialQuestion: String?

    private var relatedEntries: [GuideEntry] {
        appState.contentRepository.relatedEntries(for: entry)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                headerCard
                    .tvOSFocusable()
                richTextSection(title: "What it is", text: entry.story)
                    .tvOSFocusable()

                if !entry.tasteNotes.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        SectionHeader("What it tastes like")

                        FlexibleTagLayout(items: entry.tasteNotes)
                    }
                    .tvOSFocusable()
                }

                if !entry.highlights.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        SectionHeader("Good to know")

                        KleponCard {
                            VStack(alignment: .leading, spacing: 12) {
                                ForEach(entry.highlights, id: \.self) { item in
                                    Label(item, systemImage: "circle.fill")
                                        .font(KleponTypography.bodySecondary)
                                        .foregroundStyle(KleponColor.textSecondary)
                                        .labelStyle(DetailBulletLabelStyle())
                                }
                            }
                        }
                    }
                    .tvOSFocusable()
                }

                if let region = entry.region {
                    richTextSection(title: "Region or context", text: region)
                        .tvOSFocusable()
                }

                askSection

                if !relatedEntries.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        SectionHeader("Similar dishes and related notes")

                        ForEach(relatedEntries) { relatedEntry in
                            NavigationLink {
                                GuideDetailView(entry: relatedEntry)
                            } label: {
                                KleponCard {
                                    VStack(alignment: .leading, spacing: 10) {
                                        HStack {
                                            Text(relatedEntry.title)
                                                .font(KleponTypography.cardTitle)
                                                .foregroundStyle(KleponColor.textPrimary)

                                            Spacer(minLength: 12)

                                            Text(relatedEntry.kind.displayTitle)
                                                .font(KleponTypography.caption)
                                                .foregroundStyle(KleponColor.accentWarm)
                                        }

                                        Text(relatedEntry.summary)
                                            .font(KleponTypography.bodySecondary)
                                            .foregroundStyle(KleponColor.textSecondary)
                                            .lineLimit(2)
                                    }
                                }
                            }
                            .kleponInteractiveButtonStyle()
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .background(KleponColor.background.ignoresSafeArea())
        .navigationTitle(entry.title)
        .kleponInlineNavigationTitle()
        .toolbar {
            ToolbarItem(placement: .kleponPrimaryAction) {
                Button {
                    favoritesStore.toggle(entry.id)
                } label: {
                    Image(systemName: favoritesStore.isFavorite(entry.id) ? "heart.fill" : "heart")
                }
                .tint(KleponColor.highlight)
            }
        }
        .sheet(isPresented: $showingAskSheet) {
            NavigationStack {
                AskSheetView(entry: entry, initialQuestion: initialQuestion)
            }
        }
        .alert(
            "Not available on this device",
            isPresented: $showingUnsupportedAlert
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(
                "The private guide requires Apple TV 4K 3rd generation (2022) or newer. "
                    + "Older models don't have the hardware needed to run on-device inference."
            )
        }
        .onAppear {
            recentlyViewedStore.record(entry.id)
        }
    }

    private func openAskSheet(question: String? = nil) {
        #if os(tvOS)
            if !kleponDeviceSupportsInference() {
                showingUnsupportedAlert = true
                return
            }
        #endif
        initialQuestion = question
        showingAskSheet = true
    }

    private var headerCard: some View {
        KleponCard(padding: 20) {
            VStack(alignment: .leading, spacing: 16) {
                GuideArtworkView(entry: entry, height: 184)

                HStack(spacing: 10) {
                    KleponChip(title: entry.kind.displayTitle, icon: entry.kind.symbolName)

                    if let region = entry.region {
                        KleponChip(title: region)
                    }
                }

                Text(entry.summary)
                    .font(KleponTypography.body)
                    .foregroundStyle(KleponColor.textSecondary)
            }
        }
    }

    private func richTextSection(title: String, text: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title)

            KleponCard {
                Text(text)
                    .font(KleponTypography.body)
                    .foregroundStyle(KleponColor.textSecondary)
            }
        }
    }

    private var askSection: some View {
        KleponCard {
            VStack(alignment: .leading, spacing: 14) {
                Text("Ask privately about \(entry.title)")
                    .font(KleponTypography.cardTitle)
                    .foregroundStyle(KleponColor.textPrimary)

                Text(
                    "Get a warmer explanation, compare dishes, or ask what to try next without turning this into a generic chat screen."
                )
                .font(KleponTypography.bodySecondary)
                .foregroundStyle(KleponColor.textSecondary)

                if !entry.suggestedQuestions.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Try a quick question")
                            .font(KleponTypography.caption)
                            .foregroundStyle(KleponColor.accentWarm)

                        LazyVGrid(
                            columns: [GridItem(.adaptive(minimum: 150), spacing: 10)],
                            alignment: .leading,
                            spacing: 10
                        ) {
                            ForEach(Array(entry.suggestedQuestions.prefix(3)), id: \.self) {
                                question in
                                Button {
                                    openAskSheet(question: question)
                                } label: {
                                    Text(question)
                                        .font(KleponTypography.bodySecondary)
                                        .multilineTextAlignment(.leading)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(12)
                                        .background(
                                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                                .fill(KleponColor.surfaceSecondary)
                                        )
                                        .foregroundStyle(KleponColor.textPrimary)
                                }
                                .kleponInteractiveButtonStyle()
                            }
                        }
                    }
                }

                KleponActionButton(title: "Ask privately", systemImage: "lock") {
                    openAskSheet()
                }
            }
        }
    }
}

private struct DetailBulletLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(alignment: .top, spacing: 10) {
            configuration.icon
                .font(.system(size: 6))
                .padding(.top, 8)
            configuration.title
        }
    }
}

private struct FlexibleTagLayout: View {
    let items: [String]

    var body: some View {
        LazyVGrid(
            columns: [GridItem(.adaptive(minimum: 96), spacing: 10)], alignment: .leading,
            spacing: 10
        ) {
            ForEach(items, id: \.self) { item in
                KleponChip(title: item)
            }
        }
    }
}
