import Foundation
@preconcurrency import TVServices

final class ContentProvider: TVTopShelfContentProvider {
    override func loadTopShelfContent() async -> (any TVTopShelfContent)? {
        var carouselItems: [TVTopShelfCarouselItem] = []

        for item in TopShelfCatalog.items {
            let carouselItem = TVTopShelfCarouselItem(identifier: item.id)
            carouselItem.title = item.title
            carouselItem.contextTitle = item.contextTitle
            carouselItem.summary = item.summary
            carouselItem.genre = item.kindTitle
            carouselItem.namedAttributes = [
                TVTopShelfNamedAttribute(name: "Section", values: [item.sectionTitle]),
                TVTopShelfNamedAttribute(name: "Type", values: [item.kindTitle]),
            ]
            carouselItem.displayAction = TVTopShelfAction(url: item.displayURL)
            carouselItem.playAction = TVTopShelfAction(url: item.playURL)

            if let imageURL = Bundle.main.url(forResource: item.artworkName, withExtension: "png") {
                carouselItem.setImageURL(imageURL, for: .screenScale1x)
                carouselItem.setImageURL(imageURL, for: .screenScale2x)
            }

            carouselItems.append(carouselItem)
        }

        return TVTopShelfCarouselContent(style: .details, items: carouselItems)
    }
}

private enum TopShelfCatalog {
    static let items: [Item] = [
        Item(
            id: "klepon",
            title: "Klepon",
            contextTitle: "Featured sweet",
            summary:
                "A chewy rice cake with molten palm sugar and soft coconut that feels instantly comforting.",
            kindTitle: "Dish",
            sectionTitle: "Discover",
            artworkName: "topshelf-klepon",
            displayURL: URL(string: "klepon://entry?id=klepon")!,
            playURL: URL(string: "klepon://ask?id=klepon")!
        ),
        Item(
            id: "rendang",
            title: "Rendang",
            contextTitle: "Deep and celebratory",
            summary:
                "Slow-cooked beef, coconut, and spice reduced into one of Indonesia's richest classics.",
            kindTitle: "Dish",
            sectionTitle: "Discover",
            artworkName: "topshelf-rendang",
            displayURL: URL(string: "klepon://entry?id=rendang")!,
            playURL: URL(string: "klepon://ask?id=rendang")!
        ),
        Item(
            id: "sambal",
            title: "Sambal",
            contextTitle: "Pantry essential",
            summary:
                "A whole family of chile condiments that can be bright, smoky, sweet, sharp, or deeply savory.",
            kindTitle: "Ingredient",
            sectionTitle: "Discover",
            artworkName: "topshelf-sambal",
            displayURL: URL(string: "klepon://entry?id=sambal")!,
            playURL: URL(string: "klepon://ask?id=sambal")!
        ),
        Item(
            id: "street-food",
            title: "Street food culture",
            contextTitle: "Daily food rhythm",
            summary:
                "Portable meals, market snacks, and fast comfort that shape how many people first meet Indonesian food.",
            kindTitle: "Tradition",
            sectionTitle: "Discover",
            artworkName: "topshelf-street-food",
            displayURL: URL(string: "klepon://entry?id=street-food")!,
            playURL: URL(string: "klepon://ask?id=street-food")!
        ),
    ]

    struct Item {
        let id: String
        let title: String
        let contextTitle: String
        let summary: String
        let kindTitle: String
        let sectionTitle: String
        let artworkName: String
        let displayURL: URL
        let playURL: URL
    }
}
