import Foundation

struct AnswerCard: Identifiable, Equatable {
    let id = UUID()
    let question: String
    let headline: String
    let body: String
    let highlights: [String]
    let followUpSuggestions: [String]
    let sourceEntryIDs: [String]
    let isGeneratedOnDevice: Bool
}
