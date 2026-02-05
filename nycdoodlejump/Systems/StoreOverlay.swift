import SpriteKit

final class StoreOverlay: SKNode {
    struct SkinItem {
        let id: String
        let name: String
        let price: Int
        let color: SKColor
    }

    static let skins: [SkinItem] = [
        SkinItem(id: "classic_green", name: "Classic Green", price: 0, color: .systemGreen),
        SkinItem(id: "taxi_yellow", name: "Taxi Yellow", price: 50, color: .yellow),
        SkinItem(id: "midnight_blue", name: "Midnight Blue", price: 120, color: .systemBlue),
        SkinItem(id: "hotdog_red", name: "Hot Dog Red", price: 200, color: .systemRed),
        SkinItem(id: "mint", name: "Mint", price: 350, color: .systemTeal)
    ]

    static func skin(for id: String) -> SkinItem? {
        skins.first { $0.id == id }
    }

    static func color(for id: String) -> SKColor {
        skin(for: id)?.color ?? .systemGreen
    }

    private let background: SKShapeNode
    private let panel: SKShapeNode
    private let titleLabel = SKLabelNode(fontNamed: GameConfig.debugFontName)
    private let walletLabel = SKLabelNode(fontNamed: GameConfig.debugFontName)
    private let closeLabel = SKLabelNode(fontNamed: GameConfig.debugFontName)
    private let closeHitbox = SKShapeNode()
    private var itemLabels: [String: SKLabelNode] = [:]
    private var itemHitboxes: [String: SKShapeNode] = [:]

    init(size: CGSize) {
        background = SKShapeNode(rectOf: size)
        panel = SKShapeNode(rectOf: CGSize(width: 300, height: 320), cornerRadius: 12)
        super.init()
        setup()
        updateLayout(size: size)
        isHidden = true
    }

    required init?(coder aDecoder: NSCoder) {
        background = SKShapeNode(rectOf: .zero)
        panel = SKShapeNode(rectOf: .zero, cornerRadius: 12)
        super.init(coder: aDecoder)
        setup()
        isHidden = true
    }

    func updateLayout(size: CGSize) {
        background.path = CGPath(
            rect: CGRect(x: -size.width * 0.5, y: -size.height * 0.5, width: size.width, height: size.height),
            transform: nil
        )
        panel.path = CGPath(
            roundedRect: CGRect(x: -150, y: -160, width: 300, height: 320),
            cornerWidth: 12,
            cornerHeight: 12,
            transform: nil
        )

        titleLabel.position = CGPoint(x: 0, y: 125)
        walletLabel.position = CGPoint(x: 0, y: 95)
        closeLabel.position = CGPoint(x: 0, y: -135)
        closeHitbox.path = CGPath(rect: CGRect(x: -70, y: -16, width: 140, height: 32), transform: nil)
        closeHitbox.position = closeLabel.position

        let startY: CGFloat = 60
        let spacing: CGFloat = -32
        for (index, skin) in StoreOverlay.skins.enumerated() {
            let y = startY + CGFloat(index) * spacing
            itemLabels[skin.id]?.position = CGPoint(x: 0, y: y)
            itemHitboxes[skin.id]?.position = CGPoint(x: 0, y: y)
            itemHitboxes[skin.id]?.path = CGPath(rect: CGRect(x: -120, y: -14, width: 240, height: 28), transform: nil)
        }
    }

    func show(wallet: Int, owned: Set<String>, selected: String) {
        update(wallet: wallet, owned: owned, selected: selected)
        isHidden = false
    }

    func hide() {
        isHidden = true
    }

    func update(wallet: Int, owned: Set<String>, selected: String) {
        walletLabel.text = "Wallet: \(wallet)"
        for skin in StoreOverlay.skins {
            let label = itemLabels[skin.id]
            let status: String
            if selected == skin.id {
                status = "Selected"
            } else if owned.contains(skin.id) {
                status = "Owned"
            } else {
                status = "Buy \(skin.price)"
            }
            label?.text = "\(skin.name) - \(status)"
        }
    }

    private func setup() {
        zPosition = 30_000

        background.fillColor = SKColor(white: 0, alpha: 0.6)
        background.strokeColor = .clear
        addChild(background)

        panel.fillColor = SKColor(white: 0.1, alpha: 0.9)
        panel.strokeColor = SKColor(white: 1.0, alpha: 0.15)
        addChild(panel)

        titleLabel.text = "Store"
        titleLabel.fontSize = 22
        titleLabel.fontColor = .white

        walletLabel.fontSize = 16
        walletLabel.fontColor = .white

        closeLabel.text = "Close"
        closeLabel.fontSize = 18
        closeLabel.fontColor = .white

        closeHitbox.fillColor = .clear
        closeHitbox.strokeColor = .clear
        closeHitbox.name = "storeCloseButton"

        addChild(titleLabel)
        addChild(walletLabel)
        addChild(closeHitbox)
        addChild(closeLabel)

        for skin in StoreOverlay.skins {
            let label = SKLabelNode(fontNamed: GameConfig.debugFontName)
            label.fontSize = 16
            label.fontColor = .white
            label.horizontalAlignmentMode = .center
            label.verticalAlignmentMode = .center

            let hitbox = SKShapeNode()
            hitbox.fillColor = .clear
            hitbox.strokeColor = .clear
            hitbox.name = "skinButton_\(skin.id)"

            addChild(hitbox)
            addChild(label)

            itemLabels[skin.id] = label
            itemHitboxes[skin.id] = hitbox
        }
    }
}
