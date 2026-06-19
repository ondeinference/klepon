import Foundation

public protocol GuideOperations {
    func fetchGuideEntries() -> [GuideEntry]
    func saveFavorite(entry: GuideEntry) -> Bool
    func searchEntries(query: String) -> [GuideEntry]
}