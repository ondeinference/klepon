import Foundation
import Testing

@testable import Klepon

// MARK: - Fixtures

extension GuideEntry {
    /// Builds a `GuideEntry` with sensible defaults so tests only specify the
    /// fields they care about.
    static func fixture(
        id: String = "klepon",
        kind: Kind = .dish,
        title: String = "Klepon",
        subtitle: String = "Palm sugar-filled rice cake rolled in coconut",
        summary: String = "A soft, sweet bite with a warm syrupy center.",
        story: String = "Klepon is a beloved Indonesian snack made from glutinous rice flour.",
        tasteNotes: [String] = ["Sweet", "Chewy", "Coconut"],
        highlights: [String] = ["Palm sugar center", "Fresh coconut coating"],
        region: String? = "Java",
        aliases: [String] = ["Onde-onde kecil"],
        tags: [String] = ["Snack", "Dessert"],
        relatedIDs: [String] = [],
        suggestedQuestions: [String] = ["What does klepon taste like?"],
        imageName: String? = nil,
        isFeatured: Bool = true
    ) -> GuideEntry {
        GuideEntry(
            id: id,
            kind: kind,
            title: title,
            subtitle: subtitle,
            summary: summary,
            story: story,
            tasteNotes: tasteNotes,
            highlights: highlights,
            region: region,
            aliases: aliases,
            tags: tags,
            relatedIDs: relatedIDs,
            suggestedQuestions: suggestedQuestions,
            imageName: imageName,
            isFeatured: isFeatured
        )
    }
}

/// A test double for the on-device guide engine. Lets us exercise
/// `GuideAnswerService` without the Rust/UniFFI inference runtime.
final class StubGuideEngine: GuideAnswering {
    enum Behavior {
        case success(String)
        case failure
    }

    let behavior: Behavior
    private(set) var receivedPrompts: [String] = []

    init(behavior: Behavior) {
        self.behavior = behavior
    }

    func answer(prompt: String) async throws -> String {
        receivedPrompts.append(prompt)
        switch behavior {
        case .success(let text):
            return text
        case .failure:
            throw OndeGuideError.unavailable
        }
    }
}

// MARK: - GuideAnswerService

struct GuideAnswerServiceTests {
    private func makeService(behavior: StubGuideEngine.Behavior) -> (
        service: GuideAnswerService, engine: StubGuideEngine
    ) {
        let entry = GuideEntry.fixture()
        let repository = ContentRepository(entries: [entry], collections: [])
        let engine = StubGuideEngine(behavior: behavior)
        return (GuideAnswerService(repository: repository, guideEngine: engine), engine)
    }

    @Test
    func usesEngineAnswerWhenAlreadyStructured() async {
        let structured = """
            Short answer: It is sweet.
            What to expect: Coconut and palm sugar.
            Try next: Onde-onde.
            """
        let (service, engine) = makeService(behavior: .success(structured))

        let card = await service.answer(question: "How does it taste?", about: .fixture())

        #expect(card.isGeneratedOnDevice)
        #expect(card.body == structured)
        #expect(engine.receivedPrompts.count == 1)
        #expect(engine.receivedPrompts[0].contains("User question: How does it taste?"))
    }

    @Test
    func wrapsUnstructuredEngineAnswerIntoSections() async {
        let (service, _) = makeService(behavior: .success("Just a freeform sentence."))

        let card = await service.answer(question: "Tell me about it", about: .fixture())

        #expect(card.isGeneratedOnDevice)
        #expect(card.body.contains("Short answer: Just a freeform sentence."))
        #expect(card.body.contains("What to expect:"))
        #expect(card.body.contains("Try next:"))
    }

    @Test
    func fallsBackWhenEngineThrows() async {
        let (service, _) = makeService(behavior: .failure)

        let card = await service.answer(question: "Anything?", about: .fixture())

        #expect(card.isGeneratedOnDevice == false)
        #expect(card.body.contains("Short answer:"))
        #expect(card.body.contains("What to expect:"))
        #expect(card.body.contains("Try next:"))
    }

    @Test
    func followUpSuggestionsExcludeTheAskedQuestion() async {
        let entry = GuideEntry.fixture(
            suggestedQuestions: ["What does klepon taste like?", "Where is it from?"])
        let repository = ContentRepository(entries: [entry], collections: [])
        let service = GuideAnswerService(
            repository: repository, guideEngine: StubGuideEngine(behavior: .failure))

        let card = await service.answer(
            question: "What does klepon taste like?", about: entry)

        #expect(!card.followUpSuggestions.contains("What does klepon taste like?"))
        #expect(card.followUpSuggestions.contains("Where is it from?"))
    }
}

// MARK: - SearchService

struct SearchServiceTests {
    private func makeService(entries: [GuideEntry]) -> SearchService {
        SearchService(repository: ContentRepository(entries: entries, collections: []))
    }

    @Test
    func emptyQueryReturnsNoResults() {
        let service = makeService(entries: [.fixture()])
        #expect(service.results(for: "   ").isEmpty)
    }

    @Test
    func exactTitleMatchOutranksSubtitleMatch() {
        let exact = GuideEntry.fixture(
            id: "rendang", title: "Rendang", subtitle: "Slow-cooked beef", summary: "Rich curry",
            aliases: [], tags: [], suggestedQuestions: [])
        let subtitleOnly = GuideEntry.fixture(
            id: "other", title: "Sambal", subtitle: "Goes well with Rendang", summary: "Chili paste",
            aliases: [], tags: [], suggestedQuestions: [])
        let service = makeService(entries: [subtitleOnly, exact])

        let results = service.results(for: "Rendang")

        #expect(results.first?.id == "rendang")
        #expect(results.count == 2)
    }

    @Test
    func unmatchedQueryReturnsEmpty() {
        let service = makeService(entries: [.fixture()])
        #expect(service.results(for: "zzz-no-match").isEmpty)
    }
}

// MARK: - ContentRepository

struct ContentRepositoryTests {
    @Test
    func looksUpEntriesByIDAndRelations() {
        let related = GuideEntry.fixture(id: "coconut", title: "Coconut")
        let entry = GuideEntry.fixture(id: "klepon", relatedIDs: ["coconut"])
        let repository = ContentRepository(entries: [entry, related], collections: [])

        #expect(repository.entry(id: "klepon")?.title == "Klepon")
        #expect(repository.entry(id: "missing") == nil)
        #expect(repository.relatedEntries(for: entry).map(\.id) == ["coconut"])
    }

    @Test
    func featuredEntriesFilterByFlag() {
        let featured = GuideEntry.fixture(id: "a", isFeatured: true)
        let hidden = GuideEntry.fixture(id: "b", isFeatured: false)
        let repository = ContentRepository(entries: [featured, hidden], collections: [])

        #expect(repository.featuredEntries.map(\.id) == ["a"])
    }
}

// MARK: - FavoritesStore

@MainActor
struct FavoritesStoreTests {
    private func makeDefaults() -> UserDefaults {
        let suiteName = "klepon.tests.favorites"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }

    @Test
    func toggleAddsThenRemovesAndPersists() {
        let defaults = makeDefaults()
        let store = FavoritesStore(defaults: defaults)

        #expect(store.isFavorite("klepon") == false)

        store.toggle("klepon")
        #expect(store.isFavorite("klepon"))

        // A fresh store reading the same defaults should see the persisted value.
        let reloaded = FavoritesStore(defaults: defaults)
        #expect(reloaded.isFavorite("klepon"))

        store.toggle("klepon")
        #expect(store.isFavorite("klepon") == false)
    }
}
