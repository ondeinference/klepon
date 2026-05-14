import Combine
import Foundation

@MainActor
final class AppState: ObservableObject {
    @Published var hasCompletedOnboarding: Bool {
        didSet {
            UserDefaults.standard.set(hasCompletedOnboarding, forKey: Keys.hasCompletedOnboarding)
        }
    }

    let contentRepository: ContentRepository
    let searchService: SearchService
    let favoritesStore: FavoritesStore
    let recentSearchStore: RecentSearchStore
    let recentlyViewedStore: RecentlyViewedStore
    let guideEngine: OndeGuideEngine
    let answerService: GuideAnswerService

    init() {
        OndeEnvironmentBootstrap.configureIfNeeded()

        let repository = ContentRepository()
        let favoritesStore = FavoritesStore()
        let recentSearchStore = RecentSearchStore()
        let recentlyViewedStore = RecentlyViewedStore()
        let guideEngine = OndeGuideEngine()

        self.contentRepository = repository
        self.searchService = SearchService(repository: repository)
        self.favoritesStore = favoritesStore
        self.recentSearchStore = recentSearchStore
        self.recentlyViewedStore = recentlyViewedStore
        self.guideEngine = guideEngine
        self.answerService = GuideAnswerService(repository: repository, guideEngine: guideEngine)
        guideEngine.refreshStorageUsage()
        self.hasCompletedOnboarding = UserDefaults.standard.bool(
            forKey: Keys.hasCompletedOnboarding)
    }

    func completeOnboarding() {
        hasCompletedOnboarding = true
    }
}

private enum Keys {
    static let hasCompletedOnboarding = "klepon.hasCompletedOnboarding"
}
