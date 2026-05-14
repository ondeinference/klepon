import Foundation

struct WatchContentLoader {
    func loadEntries() -> [GuideEntry] {
        guard let url = Bundle.main.url(forResource: "guide_entries", withExtension: "json") else {
            return []
        }

        do {
            let data = try Data(contentsOf: url)
            let entries = try JSONDecoder().decode([GuideEntry].self, from: data)
            return entries.filter { $0.kind == .dish }
        } catch {
            return []
        }
    }
}
