import Combine
import Foundation

@MainActor
final class RecentSearchStore: ObservableObject {
    @Published private(set) var queries: [String]

    private let defaults: UserDefaults
    private let storageKey = "klepon.recentSearches"
    private let limit = 8

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.queries = defaults.stringArray(forKey: storageKey) ?? []
    }

    func record(_ query: String) {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else { return }

        queries.removeAll { $0.caseInsensitiveCompare(trimmedQuery) == .orderedSame }
        queries.insert(trimmedQuery, at: 0)
        queries = Array(queries.prefix(limit))
        persist()
    }

    func remove(_ query: String) {
        queries.removeAll { $0 == query }
        persist()
    }

    func clear() {
        queries = []
        persist()
    }

    private func persist() {
        defaults.set(queries, forKey: storageKey)
    }
}
