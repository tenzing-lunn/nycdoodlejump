import SpriteKit

final class PlatformNode: SKSpriteNode {
    enum PlatformType {
        case taxi
        case cart
        case subway
        case pigeon
        case manhole
    }

    var type: PlatformType = .taxi
    var used: Bool = false
    var vx: CGFloat = 0

    static func make() -> PlatformNode {
        let texture = PixelArtFactory.platformTexture(for: .taxi)
        let node = PlatformNode(texture: texture, color: .white, size: GameConfig.platformSize)
        node.name = "platform"
        node.zPosition = 100
        node.physicsBody = nil
        node.colorBlendFactor = 0.0
        return node
    }

    func configure(as type: PlatformType) {
        self.type = type
        used = false
        vx = 0
        texture = PixelArtFactory.platformTexture(for: type)

        switch type {
        case .taxi:
            color = .yellow
            size = GameConfig.platformSize
        case .cart:
            color = .orange
            size = GameConfig.platformSize
        case .subway:
            color = .gray
            size = GameConfig.platformSize
        case .pigeon:
            color = SKColor(white: 0.85, alpha: 1.0)
            size = GameConfig.platformSize
        case .manhole:
            color = SKColor(white: 0.12, alpha: 1.0)
            size = GameConfig.manholeSize
        }

        let outline = (childNode(withName: "hitboxOutline") as? SKShapeNode) ?? SKShapeNode()
        outline.name = "hitboxOutline"
        outline.path = CGPath(
            rect: CGRect(x: -size.width * 0.5, y: -size.height * 0.5, width: size.width, height: size.height),
            transform: nil
        )
        if type == .manhole {
            outline.strokeColor = SKColor(white: 0.9, alpha: 0.9)
            outline.lineWidth = 2
        } else {
            outline.strokeColor = SKColor(white: 1.0, alpha: 0.6)
            outline.lineWidth = 1
        }
        outline.fillColor = .clear
        outline.zPosition = 1
        outline.isHidden = !GameConfig.showHitboxes
        if outline.parent == nil {
            addChild(outline)
        }
    }
}
