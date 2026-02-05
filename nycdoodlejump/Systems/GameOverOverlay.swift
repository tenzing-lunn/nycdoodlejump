import SpriteKit

final class GameOverOverlay: SKNode {
    private let background: SKShapeNode
    private let titleLabel = SKLabelNode(fontNamed: GameConfig.debugFontName)
    private let scoreLabel = SKLabelNode(fontNamed: GameConfig.debugFontName)
    private let highScoreLabel = SKLabelNode(fontNamed: GameConfig.debugFontName)
    private let restartLabel = SKLabelNode(fontNamed: GameConfig.debugFontName)
    private let storeLabel = SKLabelNode(fontNamed: GameConfig.debugFontName)
    private let restartHitbox = SKShapeNode()
    private let storeHitbox = SKShapeNode()
    private let restartPlate = SKShapeNode()
    private let mainMenuLabel = SKLabelNode(fontNamed: GameConfig.debugFontName)
    private let mainMenuPlate = SKShapeNode()

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
        let panelWidth = min(size.width * 0.7, 320)
        let panelHeight = min(size.height * 0.45, 260)
        let halfPanel = CGSize(width: panelWidth * 0.5, height: panelHeight * 0.5)

        background.path = CGPath(rect: CGRect(
            x: -size.width * 0.5,
            y: -size.height * 0.5,
            width: size.width,
            height: size.height
        ), transform: nil)

        titleLabel.position = CGPoint(x: 0, y: halfPanel.height - 40)
        scoreLabel.position = CGPoint(x: 0, y: 30)
        highScoreLabel.position = CGPoint(x: 0, y: 0)
        restartLabel.position = CGPoint(x: 0, y: -40)
        restartPlate.path = CGPath(
            roundedRect: CGRect(x: -120, y: -32, width: 240, height: 64),
            cornerWidth: 16,
            cornerHeight: 16,
            transform: nil
        )
        restartPlate.position = restartLabel.position
        restartHitbox.path = CGPath(
            rect: CGRect(x: -120, y: -32, width: 240, height: 64),
            transform: nil
        )
        restartHitbox.position = restartLabel.position

        mainMenuLabel.position = CGPoint(x: 0, y: -115)
        mainMenuPlate.path = CGPath(
            roundedRect: CGRect(x: -120, y: -28, width: 240, height: 56),
            cornerWidth: 16,
            cornerHeight: 16,
            transform: nil
        )
        mainMenuPlate.position = mainMenuLabel.position
    }

    func show(score: Int, highScore: Int) {
        scoreLabel.text = "Score: \(score)"
        highScoreLabel.text = "High Score: \(highScore)"
        isHidden = false
    }

    func hide() {
        isHidden = true
    }

    private func setup() {
        zPosition = 20_000

        background.fillColor = SKColor(white: 0, alpha: 0.55)
        background.strokeColor = .clear
        addChild(background)

        titleLabel.text = "Game Over"
        titleLabel.fontSize = 26
        titleLabel.fontColor = .white

        scoreLabel.fontSize = 18
        scoreLabel.fontColor = .white

        highScoreLabel.fontSize = 18
        highScoreLabel.fontColor = .white

        restartLabel.text = "Restart"
        restartLabel.fontSize = 22
        restartLabel.fontColor = .white
        restartLabel.name = "restartButton"

        restartPlate.fillColor = SKColor(white: 1.0, alpha: 0.12)
        restartPlate.strokeColor = SKColor(white: 1.0, alpha: 0.25)
        restartPlate.zPosition = 1
        restartPlate.name = "restartButton"

        storeLabel.text = "Store"
        storeLabel.fontSize = 18
        storeLabel.fontColor = .white

        restartHitbox.fillColor = .clear
        restartHitbox.strokeColor = .clear
        restartHitbox.name = "restartButton"

        mainMenuLabel.text = "Main Menu"
        mainMenuLabel.fontSize = 18
        mainMenuLabel.fontColor = .white
        mainMenuLabel.name = "mainMenuButton"

        mainMenuPlate.fillColor = SKColor(white: 1.0, alpha: 0.12)
        mainMenuPlate.strokeColor = SKColor(white: 1.0, alpha: 0.25)
        mainMenuPlate.zPosition = 1
        mainMenuPlate.name = "mainMenuButton"

        storeHitbox.fillColor = .clear
        storeHitbox.strokeColor = .clear
        storeHitbox.name = "storeButton"

        addChild(titleLabel)
        addChild(scoreLabel)
        addChild(highScoreLabel)
        addChild(restartPlate)
        addChild(restartHitbox)
        addChild(restartLabel)
        addChild(mainMenuPlate)
        addChild(mainMenuLabel)
    }
}
