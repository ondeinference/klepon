import Foundation

final class GuideAnswerService: GuideOperations {
    private let contentRepository: ContentRepository
    private let favoritesStore: FavoritesStore
    private let searchService: SearchService

    init(contentRepository: ContentRepository, favoritesStore: FavoritesStore, searchService: SearchService) {
        self.contentRepository = contentRepository
        self.favoritesStore = favoritesStore
        self.searchService = searchService
    }

    func fetchGuideEntries() -> [GuideEntry] {
        return contentRepository.fetchAll()
    }

    func saveFavorite(entry: GuideEntry) -> Bool {
        return favoritesStore.save(entry: entry)
    }

    func searchEntries(query: String) -> [GuideEntry] {
        return searchService.search(query: query)
    }
}