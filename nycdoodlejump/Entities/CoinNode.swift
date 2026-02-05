import SpriteKit

final class CoinNode: SKSpriteNode {
    var isCollected: Bool = false

    static func make() -> CoinNode {
        let texture = PixelArtFactory.coinTexture()
        let size = CGSize(width: GameConfig.coinRadius * 2, height: GameConfig.coinRadius * 2)
        let node = CoinNode(texture: texture, color: .white, size: size)
        node.name = "coin"
        node.zPosition = 900
        node.isCollected = false
        node.colorBlendFactor = 0.0
        return node
    }

    func prepareForReuse() {
        isCollected = false
        alpha = 1.0
        xScale = 1.0
        yScale = 1.0
        isHidden = false
    }
}
