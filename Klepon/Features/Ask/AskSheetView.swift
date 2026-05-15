import SwiftUI

struct AskSheetView: View {
    let entry: GuideEntry
    let initialQuestion: String?

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var guideEngine: OndeGuideEngine

    @State private var question = ""
    @State private var answerHistory: [AnswerCard] = []
    @State private var isLoading = false

    private var latestAnswerCard: AnswerCard? {
        answerHistory.last
    }

    private var earlierAnswerCards: [AnswerCard] {
        Array(answerHistory.dropLast())
    }

    private func sourceTitles(for card: AnswerCard) -> [String] {
        card.sourceEntryIDs.compactMap { appState.contentRepository.entry(id: $0)?.title }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                KleponCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Ask privately about \(entry.title)")
                            .font(KleponTypography.screenTitle)
                            .foregroundStyle(KleponColor.textPrimary)

                        Text(
                            "Ask a natural follow-up, keep it short, and let the guide stay in the background."
                        )
                        .font(KleponTypography.body)
                        .foregroundStyle(KleponColor.textSecondary)

                        Text(guideEngine.availability.title)
                            .font(KleponTypography.caption)
                            .foregroundStyle(
                                guideEngine.availability.isFailure
                                    ? KleponColor.highlight : KleponColor.accentWarm)

                        Text(guideEngine.availability.detail)
                            .font(KleponTypography.bodySecondary)
                            .foregroundStyle(KleponColor.textSecondary)
                    }
                }

                VStack(alignment: .leading, spacing: 12) {
                    SectionHeader("Suggested questions")

                    LazyVGrid(
                        columns: [GridItem(.adaptive(minimum: 140), spacing: 10)], spacing: 10
                    ) {
                        ForEach(entry.suggestedQuestions, id: \.self) { suggestion in
                            Button {
                                question = suggestion
                                submit(question: suggestion)
                            } label: {
                                Text(suggestion)
                                    .font(KleponTypography.bodySecondary)
                                    .multilineTextAlignment(.leading)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                                            .fill(KleponColor.surfaceSecondary)
                                    )
                                    .foregroundStyle(KleponColor.textPrimary)
                            }
                            .kleponInteractiveButtonStyle()
                            .disabled(isLoading)
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 12) {
                    SectionHeader("Your question")

                    #if os(tvOS)
                        TextField(
                            "Ask about taste, ingredients, or what to try next", text: $question
                        )
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(KleponColor.surfaceSecondary)
                        )
                    #else
                        TextField(
                            "Ask about taste, ingredients, or what to try next", text: $question,
                            axis: .vertical
                        )
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(2...5)
                    #endif

                    KleponActionButton(
                        title: isLoading ? "Thinking" : "Get answer",
                        systemImage: "lock",
                        isLoading: isLoading,
                        isDisabled: question.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    ) {
                        submit(question: question)
                    }

                    if guideEngine.availability.isFailure {
                        KleponActionButton(
                            title: "Retry private guide",
                            systemImage: "arrow.clockwise",
                            tone: .secondary
                        ) {
                            Task {
                                await guideEngine.prepareIfNeeded(forceReload: true)
                            }
                        }
                    }
                }

                if isLoading {
                    AnswerLoadingCard()
                }

                if let latestAnswerCard {
                    AnswerCardView(
                        card: latestAnswerCard,
                        sourceTitles: sourceTitles(for: latestAnswerCard),
                        isInteractionDisabled: isLoading,
                        onFollowUp: { followUp in
                            question = followUp
                            submit(question: followUp)
                        }
                    )
                }

                if !earlierAnswerCards.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        SectionHeader("Earlier in this sheet")

                        ForEach(Array(earlierAnswerCards.reversed()), id: \.id) { card in
                            AnswerCardView(
                                card: card,
                                sourceTitles: sourceTitles(for: card),
                                isInteractionDisabled: isLoading,
                                onFollowUp: { followUp in
                                    question = followUp
                                    submit(question: followUp)
                                }
                            )
                        }
                    }
                }

                KleponCard {
                    Text(
                        "Private answers use the on-device guide when it is ready. If it is not ready yet, Klepon falls back to the curated notes already bundled in the app."
                    )
                    .font(KleponTypography.caption)
                    .foregroundStyle(KleponColor.textSecondary)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .background(KleponColor.background.ignoresSafeArea())
        .navigationTitle("Ask privately")
        .kleponInlineNavigationTitle()
        .toolbar {
            ToolbarItem(placement: .kleponPrimaryAction) {
                Button("Done") {
                    dismiss()
                }
                .tint(KleponColor.accent)
            }
        }
        .task {
            guard let initialQuestion, question.isEmpty else { return }
            question = initialQuestion
            submit(question: initialQuestion)
        }
    }

    private func submit(question: String) {
        let trimmedQuestion = question.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuestion.isEmpty, !isLoading else { return }

        isLoading = true

        Task {
            let result = await appState.answerService.answer(
                question: trimmedQuestion,
                about: entry,
                previousCards: answerHistory
            )
            answerHistory.append(result)
            if answerHistory.count > 3 {
                answerHistory = Array(answerHistory.suffix(3))
            }
            isLoading = false
        }
    }
}

private struct AnswerCardView: View {
    let card: AnswerCard
    let sourceTitles: [String]
    let isInteractionDisabled: Bool
    let onFollowUp: (String) -> Void

    var body: some View {
        KleponCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text(card.headline)
                        .font(KleponTypography.cardTitle)
                        .foregroundStyle(KleponColor.textPrimary)

                    Spacer(minLength: 12)

                    if card.isGeneratedOnDevice {
                        KleponChip(title: "On this device", icon: "lock")
                    } else {
                        KleponChip(title: "Curated fallback", icon: "book")
                    }
                }

                VStack(alignment: .leading, spacing: 14) {
                    ForEach(parseSections(from: card.body), id: \.title) { section in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(section.title)
                                .font(KleponTypography.caption)
                                .foregroundStyle(KleponColor.accentWarm)

                            Text(section.body)
                                .font(KleponTypography.body)
                                .foregroundStyle(KleponColor.textSecondary)
                        }
                    }
                }

                if !card.highlights.isEmpty {
                    FlexibleAnswerTagLayout(items: card.highlights)
                }

                if !sourceTitles.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Grounded in")
                            .font(KleponTypography.caption)
                            .foregroundStyle(KleponColor.accentWarm)

                        FlexibleAnswerTagLayout(items: sourceTitles)
                    }
                }

                if !card.followUpSuggestions.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Try a follow-up")
                            .font(KleponTypography.caption)
                            .foregroundStyle(KleponColor.accentWarm)

                        ForEach(card.followUpSuggestions, id: \.self) { followUp in
                            Button {
                                onFollowUp(followUp)
                            } label: {
                                Text(followUp)
                                    .font(KleponTypography.bodySecondary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                                            .fill(KleponColor.surfaceSecondary)
                                    )
                                    .foregroundStyle(KleponColor.textPrimary)
                            }
                            .kleponInteractiveButtonStyle()
                            .disabled(isInteractionDisabled)
                        }
                    }
                }
            }
        }
    }
}

private struct AnswerLoadingCard: View {
    var body: some View {
        KleponCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Preparing your answer")
                    .font(KleponTypography.cardTitle)
                    .foregroundStyle(KleponColor.textPrimary)

                Text(
                    "Klepon is grounding your question against the local guide and keeping the response short."
                )
                .font(KleponTypography.bodySecondary)
                .foregroundStyle(KleponColor.textSecondary)

                ProgressView()
                    .tint(KleponColor.accent)
            }
        }
    }
}

private struct AnswerSection {
    let title: String
    let body: String
}

private func parseSections(from body: String) -> [AnswerSection] {
    let headings = ["Short answer", "What to expect", "Try next"]
    let lines =
        body
        .components(separatedBy: .newlines)
        .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        .filter { !$0.isEmpty }

    guard !lines.isEmpty else {
        return [AnswerSection(title: "Answer", body: body)]
    }

    var sections: [AnswerSection] = []
    var currentTitle: String?
    var currentBodyLines: [String] = []

    func flushSection() {
        guard let currentTitle, !currentBodyLines.isEmpty else { return }
        sections.append(
            AnswerSection(title: currentTitle, body: currentBodyLines.joined(separator: " ")))
    }

    for line in lines {
        if let heading = headings.first(where: { heading in
            let loweredLine = line.lowercased()
            let loweredHeading = heading.lowercased()
            return loweredLine == loweredHeading || loweredLine.hasPrefix(loweredHeading + ":")
        }) {
            flushSection()
            currentTitle = heading
            if let range = line.range(of: ":") {
                let remainder = String(line[range.upperBound...]).trimmingCharacters(
                    in: .whitespaces)
                currentBodyLines = remainder.isEmpty ? [] : [remainder]
            } else {
                currentBodyLines = []
            }
        } else {
            currentBodyLines.append(line)
        }
    }

    flushSection()

    if sections.isEmpty {
        return [AnswerSection(title: "Answer", body: body)]
    }

    return sections
}

private struct FlexibleAnswerTagLayout: View {
    let items: [String]

    var body: some View {
        LazyVGrid(
            columns: [GridItem(.adaptive(minimum: 90), spacing: 10)], alignment: .leading,
            spacing: 10
        ) {
            ForEach(items, id: \.self) { item in
                KleponChip(title: item)
            }
        }
    }
}
