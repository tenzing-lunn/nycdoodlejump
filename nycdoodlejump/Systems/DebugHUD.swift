import Foundation
import SpriteKit

final class DebugHUD: SKNode {
    private let fpsLabel = SKLabelNode(fontNamed: GameConfig.debugFontName)
    private let playerYLabel = SKLabelNode(fontNamed: GameConfig.debugFontName)
    private let scoreLabel = SKLabelNode(fontNamed: GameConfig.debugFontName)
    private let platformLabel = SKLabelNode(fontNamed: GameConfig.debugFontName)

    private var frameCount: Int = 0
    private var elapsedTime: TimeInterval = 0

    override init() {
        super.init()
        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }

    func update(deltaTime: TimeInterval, playerY: CGFloat, score: Int, platformCount: Int) {
        frameCount += 1
        elapsedTime += deltaTime

        if elapsedTime >= 1.0 {
            let fps = Double(frameCount) / elapsedTime
            fpsLabel.text = String(format: "fps: %.0f", fps)
            frameCount = 0
            elapsedTime = 0
        }

        playerYLabel.text = "playerY: \(Int(playerY))"
        scoreLabel.text = "score: \(score)"
        platformLabel.text = "platforms: \(platformCount)"
    }

    private func setup() {
        isUserInteractionEnabled = false
        zPosition = 10_000

        let labels = [fpsLabel, playerYLabel, scoreLabel, platformLabel]
        for label in labels {
            label.fontSize = GameConfig.debugFontSize
            label.fontColor = .white
            label.horizontalAlignmentMode = .left
            label.verticalAlignmentMode = .top
        }

        fpsLabel.text = "fps: --"
        playerYLabel.text = "playerY: 0"
        scoreLabel.text = "score: 0"

        fpsLabel.position = CGPoint(x: 0, y: 0)
        playerYLabel.position = CGPoint(x: 0, y: -16)
        scoreLabel.position = CGPoint(x: 0, y: -32)
        platformLabel.position = CGPoint(x: 0, y: -48)

        addChild(fpsLabel)
        addChild(playerYLabel)
        addChild(scoreLabel)
        addChild(platformLabel)
    }
}
