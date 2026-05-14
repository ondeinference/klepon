import Foundation

struct GuideEntry: Identifiable, Codable, Hashable {
    enum Kind: String, Codable, CaseIterable {
        case dish
        case ingredient
        case tradition

        var displayTitle: String {
            switch self {
            case .dish:
                return "Dish"
            case .ingredient:
                return "Ingredient"
            case .tradition:
                return "Tradition"
            }
        }

        var symbolName: String {
            switch self {
            case .dish:
                return "fork.knife"
            case .ingredient:
                return "leaf"
            case .tradition:
                return "sparkles"
            }
        }
    }

    let id: String
    let kind: Kind
    let title: String
    let subtitle: String
    let summary: String
    let story: String
    let tasteNotes: [String]
    let highlights: [String]
    let region: String?
    let aliases: [String]
    let tags: [String]
    let relatedIDs: [String]
    let suggestedQuestions: [String]
    let imageName: String?
    let isFeatured: Bool

    var searchTokens: [String] {
        [title, subtitle, summary] + aliases + tags + tasteNotes
    }
}
