import Foundation

public protocol ContentRepositoryProtocol {
    func fetchAll() -> [GuideEntry]
}

final class ContentRepository: ContentRepositoryProtocol {
    // Implementation details here
    public func fetchAll() -> [GuideEntry] {
        // Existing implementation
        return []
    }
}