import SpriteKit

final class CountdownOverlay: SKNode {
    private let label = SKLabelNode(fontNamed: GameConfig.debugFontName)

    override init() {
        super.init()
        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }

    func updateLayout(size: CGSize) {
        label.position = CGPoint(x: 0, y: 0)
    }

    func start(completion: @escaping () -> Void) {
        isHidden = false
        label.removeAllActions()
        removeAllActions()

        let sequence = SKAction.sequence([
            SKAction.run { [weak self] in self?.label.text = "3" },
            SKAction.wait(forDuration: 0.8),
            SKAction.run { [weak self] in self?.label.text = "2" },
            SKAction.wait(forDuration: 0.8),
            SKAction.run { [weak self] in self?.label.text = "1" },
            SKAction.wait(forDuration: 0.8),
            SKAction.run { [weak self] in self?.label.text = "GO" },
            SKAction.wait(forDuration: 0.4),
            SKAction.run { [weak self] in self?.isHidden = true },
            SKAction.run(completion)
        ])
        run(sequence, withKey: "countdown")
    }

    func hide() {
        isHidden = true
        removeAllActions()
    }

    private func setup() {
        zPosition = 30_000
        label.fontSize = 48
        label.fontColor = .white
        label.horizontalAlignmentMode = .center
        label.verticalAlignmentMode = .center
        addChild(label)
        isHidden = true
    }
}
