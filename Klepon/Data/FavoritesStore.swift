import Combine
import Foundation

@MainActor
final class FavoritesStore: ObservableObject {
    @Published private(set) var favoriteIDs: Set<String>

    private let defaults: UserDefaults
    private let storageKey = "klepon.favoriteIDs"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.favoriteIDs = Set(defaults.stringArray(forKey: storageKey) ?? [])
    }

    func isFavorite(_ entryID: String) -> Bool {
        favoriteIDs.contains(entryID)
    }

    func toggle(_ entryID: String) {
        if favoriteIDs.contains(entryID) {
            favoriteIDs.remove(entryID)
        } else {
            favoriteIDs.insert(entryID)
        }

        persist()
    }

    func clear() {
        favoriteIDs = []
        persist()
    }

    private func persist() {
        defaults.set(Array(favoriteIDs).sorted(), forKey: storageKey)
    }
}
