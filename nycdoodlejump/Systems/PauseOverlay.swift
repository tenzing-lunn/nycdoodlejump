import SpriteKit

final class PauseOverlay: SKNode {
    private let background: SKShapeNode
    private let panel: SKShapeNode
    private let titleLabel = SKLabelNode(fontNamed: GameConfig.debugFontName)
    private let resumeLabel = SKLabelNode(fontNamed: GameConfig.debugFontName)
    private let restartLabel = SKLabelNode(fontNamed: GameConfig.debugFontName)
    private let mainMenuLabel = SKLabelNode(fontNamed: GameConfig.debugFontName)
    private let storeLabel = SKLabelNode(fontNamed: GameConfig.debugFontName)
    private let settingsLabel = SKLabelNode(fontNamed: GameConfig.debugFontName)
    private let resumeHitbox = SKShapeNode()
    private let restartHitbox = SKShapeNode()
    private let mainMenuHitbox = SKShapeNode()
    private let storeHitbox = SKShapeNode()
    private let settingsHitbox = SKShapeNode()

    init(size: CGSize) {
        background = SKShapeNode(rectOf: size)
        panel = SKShapeNode(rectOf: CGSize(width: 260, height: 260), cornerRadius: 10)
        super.init()
        setup()
        updateLayout(size: size)
        isHidden = true
    }

    required init?(coder aDecoder: NSCoder) {
        background = SKShapeNode(rectOf: .zero)
        panel = SKShapeNode(rectOf: .zero, cornerRadius: 10)
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
            roundedRect: CGRect(x: -130, y: -130, width: 260, height: 260),
            cornerWidth: 10,
            cornerHeight: 10,
            transform: nil
        )

        titleLabel.position = CGPoint(x: 0, y: 90)
        resumeLabel.position = CGPoint(x: 0, y: 45)
        restartLabel.position = CGPoint(x: 0, y: 5)
        storeLabel.position = CGPoint(x: 0, y: -35)
        settingsLabel.position = CGPoint(x: 0, y: -75)
        mainMenuLabel.position = CGPoint(x: 0, y: -115)

        resumeHitbox.path = CGPath(rect: CGRect(x: -90, y: -16, width: 180, height: 32), transform: nil)
        restartHitbox.path = CGPath(rect: CGRect(x: -90, y: -16, width: 180, height: 32), transform: nil)
        mainMenuHitbox.path = CGPath(rect: CGRect(x: -90, y: -16, width: 180, height: 32), transform: nil)
        storeHitbox.path = CGPath(rect: CGRect(x: -90, y: -16, width: 180, height: 32), transform: nil)
        settingsHitbox.path = CGPath(rect: CGRect(x: -90, y: -16, width: 180, height: 32), transform: nil)

        resumeHitbox.position = resumeLabel.position
        restartHitbox.position = restartLabel.position
        mainMenuHitbox.position = mainMenuLabel.position
        storeHitbox.position = storeLabel.position
        settingsHitbox.position = settingsLabel.position
    }

    func show() {
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

        panel.fillColor = SKColor(white: 0.1, alpha: 0.85)
        panel.strokeColor = SKColor(white: 1.0, alpha: 0.15)
        addChild(panel)

        titleLabel.text = "Paused"
        titleLabel.fontSize = 22
        titleLabel.fontColor = .white

        resumeLabel.text = "Resume"
        resumeLabel.fontSize = 18
        resumeLabel.fontColor = .white

        restartLabel.text = "Restart"
        restartLabel.fontSize = 18
        restartLabel.fontColor = .white

        mainMenuLabel.text = "Main Menu"
        mainMenuLabel.fontSize = 18
        mainMenuLabel.fontColor = .white

        storeLabel.text = "Store"
        storeLabel.fontSize = 18
        storeLabel.fontColor = .white

        settingsLabel.text = "Settings"
        settingsLabel.fontSize = 18
        settingsLabel.fontColor = .white

        resumeHitbox.fillColor = .clear
        resumeHitbox.strokeColor = .clear
        resumeHitbox.name = "resumeButton"

        restartHitbox.fillColor = .clear
        restartHitbox.strokeColor = .clear
        restartHitbox.name = "pauseRestartButton"

        mainMenuHitbox.fillColor = .clear
        mainMenuHitbox.strokeColor = .clear
        mainMenuHitbox.name = "mainMenuButton"

        storeHitbox.fillColor = .clear
        storeHitbox.strokeColor = .clear
        storeHitbox.name = "storeButton"

        settingsHitbox.fillColor = .clear
        settingsHitbox.strokeColor = .clear
        settingsHitbox.name = "settingsButton"

        addChild(titleLabel)
        addChild(resumeHitbox)
        addChild(resumeLabel)
        addChild(restartHitbox)
        addChild(restartLabel)
        addChild(storeHitbox)
        addChild(storeLabel)
        addChild(settingsHitbox)
        addChild(settingsLabel)
        addChild(mainMenuHitbox)
        addChild(mainMenuLabel)
    }
}
