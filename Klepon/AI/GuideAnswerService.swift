import Foundation

final class GuideAnswerService {
    private let repository: ContentRepository
    private let guideEngine: OndeGuideEngine

    init(repository: ContentRepository, guideEngine: OndeGuideEngine) {
        self.repository = repository
        self.guideEngine = guideEngine
    }

    func answer(question: String, about entry: GuideEntry, previousCards: [AnswerCard] = []) async
        -> AnswerCard
    {
        let contextEntries = groundingEntries(for: entry)
        let prompt = buildPrompt(
            question: question, using: contextEntries, previousCards: previousCards)

        do {
            let rawBody = try await guideEngine.answer(prompt: prompt)
            let body = normalizedAnswerBody(rawBody, for: entry, using: contextEntries)
            return AnswerCard(
                question: question,
                headline: "A private answer about \(entry.title)",
                body: body,
                highlights: Array(entry.tasteNotes.prefix(3)),
                followUpSuggestions: followUpSuggestions(for: entry, excluding: question),
                sourceEntryIDs: contextEntries.map(\.id),
                isGeneratedOnDevice: true
            )
        } catch {
            return fallbackAnswer(question: question, about: entry, using: contextEntries)
        }
    }

    private func groundingEntries(for entry: GuideEntry) -> [GuideEntry] {
        let related = repository.relatedEntries(for: entry)
        return Array(([entry] + related).prefix(3))
    }

    private func buildPrompt(
        question: String, using contextEntries: [GuideEntry], previousCards: [AnswerCard]
    ) -> String {
        let notes = contextEntries.map { entry in
            """
            Title: \(entry.title)
            Type: \(entry.kind.displayTitle)
            Summary: \(entry.summary)
            Story: \(entry.story)
            Taste notes: \(entry.tasteNotes.joined(separator: ", "))
            Highlights: \(entry.highlights.joined(separator: "; "))
            Region: \(entry.region ?? "Not specified")
            """
        }
        .joined(separator: "\n\n")

        let previousContext = previousConversationContext(from: previousCards)

        return """
            You are answering inside Klepon, a private local guide to Indonesian food.
            Use only the guide notes below.
            If the notes are not enough, say the guide does not have enough detail yet.
            Keep the tone warm, respectful, and concise.
            Answer in three short parts:
            1. Short answer
            2. What to expect
            3. Try next

            Guide notes:
            \(notes)

            \(previousContext)
            User question: \(question)
            """
    }

    private func previousConversationContext(from previousCards: [AnswerCard]) -> String {
        let recentCards = previousCards.suffix(2)
        guard !recentCards.isEmpty else { return "" }

        let formatted = recentCards.map { card in
            "Question: \(card.question)\nAnswer: \(card.body)"
        }
        .joined(separator: "\n\n")

        return "Previous guide conversation:\n\(formatted)\n"
    }

    private func followUpSuggestions(for entry: GuideEntry, excluding question: String) -> [String]
    {
        let normalizedQuestion = question.lowercased()
        let filtered = entry.suggestedQuestions.filter { $0.lowercased() != normalizedQuestion }
        return Array(filtered.prefix(3))
    }

    private func normalizedAnswerBody(
        _ rawBody: String,
        for entry: GuideEntry,
        using contextEntries: [GuideEntry]
    ) -> String {
        let trimmedBody = rawBody.trimmingCharacters(in: .whitespacesAndNewlines)
        let lowercasedBody = trimmedBody.lowercased()

        if lowercasedBody.contains("short answer") || lowercasedBody.contains("what to expect")
            || lowercasedBody.contains("try next")
        {
            return trimmedBody
        }

        let tryNext = contextEntries.dropFirst().first?.title ?? entry.title
        let expectation = expectationLine(for: entry)

        return """
            Short answer: \(trimmedBody)
            What to expect: \(expectation)
            Try next: If you want a nearby path through the guide, open \(tryNext) next.
            """
    }

    private func expectationLine(for entry: GuideEntry) -> String {
        let taste = entry.tasteNotes.prefix(3).joined(separator: ", ")
        if taste.isEmpty {
            return entry.summary
        }
        return "Expect \(taste), with the overall dish feeling \(entry.summary.lowercased())."
    }

    private func fallbackAnswer(
        question: String, about entry: GuideEntry, using contextEntries: [GuideEntry]
    ) -> AnswerCard {
        let regionLine =
            entry.region.map { "It is often associated with \($0)." }
            ?? "Regional context can vary."
        let tryNext = contextEntries.dropFirst().first?.title ?? entry.title
        let body = """
            Short answer: \(entry.title) is \(entry.summary.lowercased())
            What to expect: \(entry.story) \(regionLine)
            Try next: Once the private guide is ready, ask a follow-up or open \(tryNext) next for a nearby reference point.
            """

        return AnswerCard(
            question: question,
            headline: "A grounded guide note for now",
            body: body,
            highlights: Array(entry.highlights.prefix(3)),
            followUpSuggestions: followUpSuggestions(for: entry, excluding: question),
            sourceEntryIDs: contextEntries.map(\.id),
            isGeneratedOnDevice: false
        )
    }
}
