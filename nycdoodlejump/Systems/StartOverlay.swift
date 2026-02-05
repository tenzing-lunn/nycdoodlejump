import SpriteKit

final class StartOverlay: SKNode {
    private let background: SKShapeNode
    private let titleLabel = SKLabelNode(fontNamed: GameConfig.debugFontName)
    private let subtitleLabel = SKLabelNode(fontNamed: GameConfig.debugFontName)
    private let highScoreLabel = SKLabelNode(fontNamed: GameConfig.debugFontName)
    private let walletLabel = SKLabelNode(fontNamed: GameConfig.debugFontName)
    private let startPlate = SKShapeNode()
    private let startLabel = SKLabelNode(fontNamed: GameConfig.debugFontName)
    private let storePlate = SKShapeNode()
    private let storeLabel = SKLabelNode(fontNamed: GameConfig.debugFontName)

    init(size: CGSize) {
        background = SKShapeNode(rectOf: size)
        super.init()
        setup()
        updateLayout(size: size)
        isHidden = true
    }

    required init?(coder aDecoder: NSCoder) {
        background = SKShapeNode(rectOf: .zero)
        super.init(coder: aDecoder)
        setup()
        isHidden = true
    }

    func updateLayout(size: CGSize) {
        background.path = CGPath(
            rect: CGRect(x: -size.width * 0.5, y: -size.height * 0.5, width: size.width, height: size.height),
            transform: nil
        )
        titleLabel.position = CGPoint(x: 0, y: 90)
        subtitleLabel.position = CGPoint(x: 0, y: 50)
        highScoreLabel.position = CGPoint(x: 0, y: 20)
        walletLabel.position = CGPoint(x: 0, y: -5)
        startLabel.position = CGPoint(x: 0, y: -55)
        startPlate.path = CGPath(
            roundedRect: CGRect(x: -120, y: -32, width: 240, height: 64),
            cornerWidth: 16,
            cornerHeight: 16,
            transform: nil
        )
        startPlate.position = startLabel.position

        storeLabel.position = CGPoint(x: 0, y: -115)
        storePlate.path = CGPath(
            roundedRect: CGRect(x: -120, y: -28, width: 240, height: 56),
            cornerWidth: 16,
            cornerHeight: 16,
            transform: nil
        )
        storePlate.position = storeLabel.position
    }

    func show(highScore: Int, wallet: Int) {
        highScoreLabel.text = "High: \(highScore)"
        walletLabel.text = "Wallet: \(wallet)"
        alpha = 1.0
        isHidden = false
    }

    func fadeOut(completion: @escaping () -> Void) {
        removeAction(forKey: "startFade")
        run(
            SKAction.sequence([
                SKAction.fadeOut(withDuration: 0.25),
                SKAction.run { [weak self] in
                    self?.isHidden = true
                    self?.alpha = 1.0
                    completion()
                }
            ]),
            withKey: "startFade"
        )
    }

    private func setup() {
        zPosition = 30_000

        background.fillColor = SKColor(white: 0, alpha: 0.7)
        background.strokeColor = .clear
        addChild(background)

        titleLabel.text = "NYC DOODLE JUMP"
        titleLabel.fontSize = 24
        titleLabel.fontColor = .white

        subtitleLabel.text = "Tap to move • Arrow keys on desktop"
        subtitleLabel.fontSize = 14
        subtitleLabel.fontColor = .white

        highScoreLabel.fontSize = 16
        highScoreLabel.fontColor = .white

        walletLabel.fontSize = 16
        walletLabel.fontColor = .white

        startPlate.fillColor = SKColor(white: 1.0, alpha: 0.12)
        startPlate.strokeColor = SKColor(white: 1.0, alpha: 0.25)
        startPlate.name = "startButton"
        startPlate.zPosition = 1

        startLabel.text = "Start"
        startLabel.fontSize = 22
        startLabel.fontColor = .white
        startLabel.name = "startButton"

        storePlate.fillColor = SKColor(white: 1.0, alpha: 0.12)
        storePlate.strokeColor = SKColor(white: 1.0, alpha: 0.25)
        storePlate.name = "storeButton"
        storePlate.zPosition = 1

        storeLabel.text = "Store"
        storeLabel.fontSize = 18
        storeLabel.fontColor = .white
        storeLabel.name = "storeButton"

        addChild(titleLabel)
        addChild(subtitleLabel)
        addChild(highScoreLabel)
        addChild(walletLabel)
        addChild(startPlate)
        addChild(startLabel)
        addChild(storePlate)
        addChild(storeLabel)
    }
}
