import Combine
import Foundation

@MainActor
final class RecentlyViewedStore: ObservableObject {
    @Published private(set) var entryIDs: [String]

    private let defaults: UserDefaults
    private let storageKey = "klepon.recentlyViewed"
    private let limit = 10

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.entryIDs = defaults.stringArray(forKey: storageKey) ?? []
    }

    func record(_ entryID: String) {
        entryIDs.removeAll { $0 == entryID }
        entryIDs.insert(entryID, at: 0)
        entryIDs = Array(entryIDs.prefix(limit))
        persist()
    }

    func clear() {
        entryIDs = []
        persist()
    }

    private func persist() {
        defaults.set(entryIDs, forKey: storageKey)
    }
}
