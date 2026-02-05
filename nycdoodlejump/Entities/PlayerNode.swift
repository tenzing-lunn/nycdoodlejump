import SpriteKit

final class PlayerNode: SKSpriteNode {
    static func make() -> PlayerNode {
        let texture = PixelArtFactory.playerTexture()
        let node = PlayerNode(texture: texture, color: .white, size: GameConfig.playerSize)
        node.name = "player"
        node.zPosition = 1000
        node.colorBlendFactor = 0.85

        let body = SKPhysicsBody(rectangleOf: node.size)
        body.allowsRotation = false
        body.affectedByGravity = false
        body.linearDamping = 0
        body.restitution = 0
        body.friction = 0
        body.categoryBitMask = 0
        body.contactTestBitMask = 0
        body.collisionBitMask = 0
        node.physicsBody = body

        let outline = SKShapeNode(rectOf: node.size, cornerRadius: 4)
        outline.strokeColor = .white
        outline.lineWidth = 2
        outline.fillColor = .clear
        outline.zPosition = 1
        outline.isHidden = !GameConfig.showHitboxes
        outline.name = "hitboxOutline"
        node.addChild(outline)

        return node
    }
}
