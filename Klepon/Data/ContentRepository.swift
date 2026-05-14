import Foundation

final class ContentRepository {
    let entries: [GuideEntry]
    let collections: [GuideCollection]

    private let entriesByID: [String: GuideEntry]

    init(bundle: Bundle = .main) {
        self.entries = ContentRepository.loadEntries(from: bundle)
        self.collections = ContentRepository.loadCollections(from: bundle)
        self.entriesByID = Dictionary(uniqueKeysWithValues: entries.map { ($0.id, $0) })
    }

    var featuredEntries: [GuideEntry] {
        entries.filter(\.isFeatured)
    }

    func entry(id: String) -> GuideEntry? {
        entriesByID[id]
    }

    func entries(ids: [String]) -> [GuideEntry] {
        ids.compactMap { entriesByID[$0] }
    }

    func relatedEntries(for entry: GuideEntry) -> [GuideEntry] {
        entries(ids: entry.relatedIDs)
    }

    func entries(in collection: GuideCollection) -> [GuideEntry] {
        entries(ids: collection.entryIDs)
    }

    private static func loadEntries(from bundle: Bundle) -> [GuideEntry] {
        loadJSON(named: "guide_entries", from: bundle) ?? []
    }

    private static func loadCollections(from bundle: Bundle) -> [GuideCollection] {
        loadJSON(named: "collections", from: bundle) ?? []
    }

    private static func loadJSON<T: Decodable>(named fileName: String, from bundle: Bundle) -> T? {
        let decoder = JSONDecoder()
        let candidateURLs = [
            bundle.url(
                forResource: fileName, withExtension: "json", subdirectory: "Resources/Content"),
            bundle.url(forResource: fileName, withExtension: "json"),
        ]

        for candidate in candidateURLs {
            guard let url = candidate else { continue }

            do {
                let data = try Data(contentsOf: url)
                return try decoder.decode(T.self, from: data)
            } catch {
                assertionFailure("Failed to decode \(fileName).json: \(error.localizedDescription)")
            }
        }

        assertionFailure("Missing bundled content file: \(fileName).json")
        return nil
    }
}
