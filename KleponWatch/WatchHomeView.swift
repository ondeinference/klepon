import SwiftUI

private struct WatchGuideEntry: Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let notes: [String]
}

private let watchEntries: [WatchGuideEntry] = [
    .init(
        id: "klepon",
        title: "Klepon",
        subtitle: "Sweet rice cake with palm sugar",
        notes: ["Chewy", "Coconut", "Palm sugar"]
    ),
    .init(
        id: "rendang",
        title: "Rendang",
        subtitle: "Slow-cooked beef with deep spice",
        notes: ["Rich", "Savory", "West Sumatra"]
    ),
    .init(
        id: "nasi-goreng",
        title: "Nasi goreng",
        subtitle: "Indonesia’s beloved fried rice",
        notes: ["Smoky", "Comforting", "Kecap manis"]
    ),
    .init(
        id: "sate",
        title: "Sate",
        subtitle: "Skewered grilled meat with sauce",
        notes: ["Grilled", "Street food", "Peanut sauce"]
    ),
]

struct WatchHomeView: View {
    var body: some View {
        NavigationStack {
            List(watchEntries) { entry in
                NavigationLink(entry.title) {
                    WatchEntryDetailView(entry: entry)
                }
            }
            .navigationTitle("Klepon")
        }
    }
}

private struct WatchEntryDetailView: View {
    let entry: WatchGuideEntry

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text(entry.title)
                    .font(.headline)

                Text(entry.subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                ForEach(entry.notes, id: \.self) { note in
                    Text("• \(note)")
                        .font(.footnote)
                }

                Text("Watch support is browse-first for now.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(.top, 6)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
        }
        .navigationTitle(entry.title)
    }
}
