import Foundation

final class SearchService {
    private let repository: ContentRepository

    init(repository: ContentRepository) {
        self.repository = repository
    }

    func results(for query: String) -> [GuideEntry] {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else { return [] }

        let needle = trimmedQuery.lowercased()

        let rankedEntries: [(entry: GuideEntry, score: Int)] = repository.entries.compactMap {
            entry in
            let score = score(for: entry, needle: needle)
            guard score > 0 else { return nil }
            return (entry: entry, score: score)
        }

        return
            rankedEntries
            .sorted { lhs, rhs in
                if lhs.score == rhs.score {
                    return lhs.entry.title < rhs.entry.title
                }
                return lhs.score > rhs.score
            }
            .map(\.entry)
    }

    func suggestions(limit: Int = 6) -> [GuideEntry] {
        Array(repository.featuredEntries.prefix(limit))
    }

    private func score(for entry: GuideEntry, needle: String) -> Int {
        let title = entry.title.lowercased()
        let subtitle = entry.subtitle.lowercased()

        if title == needle { return 120 }
        if entry.aliases.map({ $0.lowercased() }).contains(needle) { return 100 }
        if title.hasPrefix(needle) { return 90 }
        if title.contains(needle) { return 80 }
        if subtitle.contains(needle) { return 60 }
        if entry.tags.contains(where: { $0.lowercased().contains(needle) }) { return 45 }
        if entry.searchTokens.contains(where: { $0.lowercased().contains(needle) }) { return 30 }

        return 0
    }
}
