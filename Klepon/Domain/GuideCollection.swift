import Foundation

struct GuideCollection: Identifiable, Codable, Hashable {
    let id: String
    let title: String
    let subtitle: String
    let entryIDs: [String]
}
