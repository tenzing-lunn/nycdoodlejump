import SpriteKit

final class SettingsOverlay: SKNode {
    private let background: SKShapeNode
    private let panel: SKShapeNode
    private let titleLabel = SKLabelNode(fontNamed: GameConfig.debugFontName)
    private let modeLabel = SKLabelNode(fontNamed: GameConfig.debugFontName)
    private let modeHitbox = SKShapeNode()
    private let sensitivityLabel = SKLabelNode(fontNamed: GameConfig.debugFontName)
    private let track = SKShapeNode(rectOf: CGSize(width: 200, height: 6), cornerRadius: 3)
    private let knob = SKShapeNode(circleOfRadius: 10)
    private let closeLabel = SKLabelNode(fontNamed: GameConfig.debugFontName)
    private let closeHitbox = SKShapeNode()

    private var sliderMinX: CGFloat = -100
    private var sliderMaxX: CGFloat = 100

    init(size: CGSize) {
        background = SKShapeNode(rectOf: size)
        panel = SKShapeNode(rectOf: CGSize(width: 300, height: 240), cornerRadius: 12)
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
            roundedRect: CGRect(x: -150, y: -120, width: 300, height: 240),
            cornerWidth: 12,
            cornerHeight: 12,
            transform: nil
        )

        titleLabel.position = CGPoint(x: 0, y: 90)
        modeLabel.position = CGPoint(x: 0, y: 45)
        modeHitbox.path = CGPath(rect: CGRect(x: -90, y: -16, width: 180, height: 32), transform: nil)
        modeHitbox.position = modeLabel.position

        sensitivityLabel.position = CGPoint(x: 0, y: 10)
        track.position = CGPoint(x: 0, y: -20)
        sliderMinX = -100
        sliderMaxX = 100

        closeLabel.position = CGPoint(x: 0, y: -85)
        closeHitbox.path = CGPath(rect: CGRect(x: -70, y: -16, width: 140, height: 32), transform: nil)
        closeHitbox.position = closeLabel.position
    }

    func show(modeText: String, sensitivity: CGFloat) {
        update(modeText: modeText, sensitivity: sensitivity)
        isHidden = false
    }

    func hide() {
        isHidden = true
    }

    func update(modeText: String, sensitivity: CGFloat) {
        modeLabel.text = "Mode: \(modeText)"
        sensitivityLabel.text = String(format: "Sensitivity: %.1fx", sensitivity)
        knob.position = CGPoint(x: knobX(for: sensitivity), y: track.position.y)
    }

    func sensitivityFromTouch(x: CGFloat) -> CGFloat {
        let clamped = max(sliderMinX, min(sliderMaxX, x))
        let t = (clamped - sliderMinX) / (sliderMaxX - sliderMinX)
        return 0.5 + (2.5 - 0.5) * t
    }

    func knobX(for sensitivity: CGFloat) -> CGFloat {
        let clamped = max(0.5, min(2.5, sensitivity))
        let t = (clamped - 0.5) / (2.5 - 0.5)
        return sliderMinX + (sliderMaxX - sliderMinX) * t
    }

    func trackNode() -> SKShapeNode { track }
    func knobNode() -> SKShapeNode { knob }

    private func setup() {
        zPosition = 30_000

        background.fillColor = SKColor(white: 0, alpha: 0.6)
        background.strokeColor = .clear
        addChild(background)

        panel.fillColor = SKColor(white: 0.1, alpha: 0.9)
        panel.strokeColor = SKColor(white: 1.0, alpha: 0.15)
        addChild(panel)

        titleLabel.text = "Settings"
        titleLabel.fontSize = 22
        titleLabel.fontColor = .white

        modeLabel.fontSize = 18
        modeLabel.fontColor = .white
        modeLabel.horizontalAlignmentMode = .center
        modeLabel.verticalAlignmentMode = .center

        modeHitbox.fillColor = .clear
        modeHitbox.strokeColor = .clear
        modeHitbox.name = "settingsToggleButton"

        sensitivityLabel.fontSize = 14
        sensitivityLabel.fontColor = .white
        sensitivityLabel.horizontalAlignmentMode = .center
        sensitivityLabel.verticalAlignmentMode = .center

        track.fillColor = SKColor(white: 1.0, alpha: 0.2)
        track.strokeColor = .clear
        track.name = "sensitivityTrack"

        knob.fillColor = .white
        knob.strokeColor = .clear
        knob.name = "sensitivityKnob"

        closeLabel.text = "Close"
        closeLabel.fontSize = 18
        closeLabel.fontColor = .white

        closeHitbox.fillColor = .clear
        closeHitbox.strokeColor = .clear
        closeHitbox.name = "settingsCloseButton"

        addChild(titleLabel)
        addChild(modeHitbox)
        addChild(modeLabel)
        addChild(sensitivityLabel)
        addChild(track)
        addChild(knob)
        addChild(closeHitbox)
        addChild(closeLabel)
    }
}
