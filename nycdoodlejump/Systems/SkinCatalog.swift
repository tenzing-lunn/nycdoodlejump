import SpriteKit

struct StoreItem {
    let id: String
    let name: String
    let price: Int
    let color: SKColor
}

struct SkinCatalog {
    static let items: [StoreItem] = [
        StoreItem(id: "classic_green", name: "Classic Green", price: 0, color: .systemGreen),
        StoreItem(id: "taxi_yellow", name: "Taxi Yellow", price: 50, color: .yellow),
        StoreItem(id: "midnight_blue", name: "Midnight Blue", price: 120, color: .systemBlue),
        StoreItem(id: "hotdog_red", name: "Hot Dog Red", price: 200, color: .systemRed),
        StoreItem(id: "mint", name: "Mint", price: 350, color: .systemTeal)
    ]

    static func item(for id: String) -> StoreItem? {
        items.first { $0.id == id }
    }
}
