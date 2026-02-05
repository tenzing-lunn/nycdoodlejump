//
//  GameScene.swift
//  nycdoodlejump
//
//  Created by Tenzing Lunn on 1/17/26.
//

import SpriteKit
import CoreMotion

class GameScene: SKScene {
    
    private enum RunState {
        case startScreen
        case playing
        case paused
        case gameOver
        case countdown
    }

    private enum ControlMode {
        case tap
        case tilt
    }
    
    private var label : SKLabelNode?
    private var spinnyNode : SKShapeNode?
    private var debugHUD: DebugHUD?
    private var lastUpdateTime: TimeInterval = 0
    private var player: PlayerNode!
    private var moveLeft = false
    private var moveRight = false
    private var platformManager: PlatformManager!
    private var highestPlayerY: CGFloat = 0
    private var previousPlayerY: CGFloat = 0
    private var playerVelocity = CGVector(dx: 0, dy: 0)
    private var startY: CGFloat = 0
    private var currentScore: Int = 0
    private var nextScoreLineY: CGFloat = 0
    private var cameraNode: SKCameraNode?
    private var scoreLabel: SKLabelNode?
    private var scoreBackground: SKShapeNode?
    private var gameOverOverlay: GameOverOverlay?
    private var isGameOver = false
    private var pendingRecycles: [PlatformNode] = []
    private var backgroundManager: BackgroundManager?
    private var baselineCameraY: CGFloat = 0
    private var cameraBasePosition: CGPoint = .zero
    private var cameraShakeRemaining: CGFloat = 0
    private var cameraShakeDuration: CGFloat = 0
    private var cameraShakeAmplitude: CGFloat = 0
    private var runState: RunState = .startScreen
    private var pauseOverlay: PauseOverlay?
    private var countdownOverlay: CountdownOverlay?
    private var pauseButton: SKLabelNode?
    private var resetButton: SKLabelNode?
    private var coinManager: CoinManager?
    private var runCoins: Int = 0
    private var runBonusCoins: Int = 0
    private enum StoreReturnTarget {
        case start
        case game
    }
    private var storeReturnTarget: StoreReturnTarget = .start
    private var streakLabel: SKLabelNode?
    private var streakCount: Int = 0
    private var lastScoreTime: TimeInterval = 0
    private var dangerLine: SKShapeNode?
    private var dangerLineY: CGFloat = 0
    private var dangerLineEnabled = false
    private var dangerLabel: SKLabelNode?
    private var settingsOverlay: SettingsOverlay?
    private var isDraggingSensitivity = false
    private var settingsReturnState: RunState = .paused
    private var controlMode: ControlMode = .tap
    private var controlSensitivity: CGFloat = 1.0
    private let motionManager = CMMotionManager()
    private var tiltValue: CGFloat = 0
    private var startOverlay: StartOverlay?
    
    override func didMove(to view: SKView) {
        self.backgroundColor = .black
        physicsWorld.gravity = .zero
        
        // Get label node from scene and store it for use later
        self.label = self.childNode(withName: "//helloLabel") as? SKLabelNode
        if let label = self.label {
            label.isHidden = true
        }
        
        // Create shape node to use during mouse interaction
        let w = (self.size.width + self.size.height) * 0.05
        self.spinnyNode = SKShapeNode.init(rectOf: CGSize.init(width: w, height: w), cornerRadius: w * 0.3)
        
        if let spinnyNode = self.spinnyNode {
            spinnyNode.lineWidth = 2.5
            
            spinnyNode.run(SKAction.repeatForever(SKAction.rotate(byAngle: CGFloat(Double.pi), duration: 1)))
            spinnyNode.run(SKAction.sequence([SKAction.wait(forDuration: 0.5),
                                              SKAction.fadeOut(withDuration: 0.5),
                                              SKAction.removeFromParent()]))
        }

        if self.camera == nil {
            let cam = SKCameraNode()
            addChild(cam)
            self.camera = cam
        }
        self.camera?.position = CGPoint(x: 0, y: 0)
        let cam = self.camera ?? SKCameraNode()
        cameraNode = cam
        if cam.parent == nil {
            addChild(cam)
        }
        baselineCameraY = cam.position.y
        cameraBasePosition = cam.position
        cameraShakeRemaining = 0

        controlSensitivity = Storage.getControlSensitivity()
        controlMode = Storage.getControlMode() == "tilt" ? .tilt : .tap
        if controlMode == .tilt && !motionManager.isDeviceMotionAvailable {
            controlMode = .tap
            Storage.setControlMode("tap")
        }
        if motionManager.isDeviceMotionAvailable {
            motionManager.deviceMotionUpdateInterval = 1.0 / 60.0
            motionManager.startDeviceMotionUpdates()
        }

        backgroundManager = BackgroundManager(scene: self, camera: cam)

        let visibleRect = currentVisibleRect()
        platformManager = PlatformManager(scene: self)
        platformManager.bootstrap(in: visibleRect)
        coinManager = CoinManager(scene: self)
        coinManager?.reset(in: visibleRect)

        let newPlayer = PlayerNode.make()
        newPlayer.position = CGPoint(x: visibleRect.midX, y: visibleRect.minY + 180)
        addChild(newPlayer)
        player = newPlayer
        applySelectedSkin()
        highestPlayerY = newPlayer.position.y
        previousPlayerY = newPlayer.position.y
        playerVelocity = .zero
        startY = newPlayer.position.y
        currentScore = 0
        nextScoreLineY = startY + GameConfig.scoreLineSpacing
        runCoins = 0
        runBonusCoins = 0
        streakCount = 0
        lastScoreTime = 0

        let startingPlatform = PlatformNode.make()
        startingPlatform.configure(as: .taxi)
        startingPlatform.position = CGPoint(
            x: newPlayer.position.x,
            y: newPlayer.position.y - newPlayer.size.height * 0.5 - GameConfig.platformSize.height * 0.5
        )
        platformManager.addPlatform(startingPlatform)

        let score = SKLabelNode(fontNamed: GameConfig.debugFontName)
        score.fontSize = 20
        score.fontColor = .white
        score.horizontalAlignmentMode = .center
        score.verticalAlignmentMode = .top
        score.zPosition = 10_000
        score.text = "Score: 0"
        let scorePlate = SKShapeNode(rectOf: CGSize(width: 140, height: 30), cornerRadius: 6)
        scorePlate.fillColor = SKColor(white: 0, alpha: 0.35)
        scorePlate.strokeColor = .clear
        scorePlate.zPosition = 9_900
        if score.parent == nil {
            cam.addChild(score)
        }
        if scorePlate.parent == nil {
            cam.addChild(scorePlate)
        }
        scoreLabel = score
        scoreBackground = scorePlate
        updateScoreLabelPosition()

        let streak = SKLabelNode(fontNamed: GameConfig.debugFontName)
        streak.fontSize = 12
        streak.fontColor = .white
        streak.horizontalAlignmentMode = .center
        streak.verticalAlignmentMode = .top
        streak.zPosition = 10_000
        streak.text = ""
        streak.alpha = 0
        if streak.parent == nil {
            cam.addChild(streak)
        }
        streakLabel = streak
        updateScoreLabelPosition()

        let danger = SKShapeNode(rectOf: CGSize(width: size.width, height: 2))
        danger.fillColor = .red
        danger.strokeColor = .clear
        danger.zPosition = 5000
        danger.isHidden = true
        addChild(danger)
        dangerLine = danger
        let dangerText = SKLabelNode(fontNamed: GameConfig.debugFontName)
        dangerText.text = "DANGER LINE"
        dangerText.fontSize = 14
        dangerText.fontColor = .red
        dangerText.alpha = 0
        dangerText.zPosition = 10_000
        if dangerText.parent == nil {
            cam.addChild(dangerText)
        }
        dangerLabel = dangerText

        let overlay = GameOverOverlay(size: size)
        cam.addChild(overlay)
        gameOverOverlay = overlay

        let hud = DebugHUD()
        positionHUD(hud)
        addChild(hud)
        debugHUD = hud
        debugHUD?.isHidden = !GameConfig.debugEnabled

        let pause = SKLabelNode(fontNamed: GameConfig.debugFontName)
        pause.name = "pauseButton"
        pause.text = "Pause"
        pause.fontSize = 16
        pause.fontColor = .white
        pause.horizontalAlignmentMode = .center
        pause.verticalAlignmentMode = .center
        pause.zPosition = 10_000
        if pause.parent == nil {
            cam.addChild(pause)
        }
        pauseButton = pause

        let reset = SKLabelNode(fontNamed: GameConfig.debugFontName)
        reset.name = "resetButton"
        reset.text = "Reset"
        reset.fontSize = 16
        reset.fontColor = .white
        reset.horizontalAlignmentMode = .center
        reset.verticalAlignmentMode = .center
        reset.zPosition = 10_000
        if reset.parent == nil {
            cam.addChild(reset)
        }
        resetButton = reset

        let pausePanel = PauseOverlay(size: size)
        cam.addChild(pausePanel)
        pauseOverlay = pausePanel

        let countdown = CountdownOverlay()
        cam.addChild(countdown)
        countdownOverlay = countdown

        let settings = SettingsOverlay(size: size)
        cam.addChild(settings)
        settingsOverlay = settings

        let startScreen = StartOverlay(size: size)
        cam.addChild(startScreen)
        startOverlay = startScreen
        showStartScreen()

        updateScoreLabelPosition()
        updateTopButtonsPosition()
        pauseOverlay?.updateLayout(size: size)
        countdownOverlay?.updateLayout(size: size)
        settingsOverlay?.updateLayout(size: size)
        updateDangerLineLayout()

        print("BOOT size=\(size) anchor=\(anchorPoint) cam=\(String(describing: camera?.position))")
    }
    
    
    func touchDown(atPoint pos : CGPoint) {
        if let n = self.spinnyNode?.copy() as! SKShapeNode? {
            n.position = pos
            n.strokeColor = SKColor.green
            self.addChild(n)
        }
    }
    
    func touchMoved(toPoint pos : CGPoint) {
        if let n = self.spinnyNode?.copy() as! SKShapeNode? {
            n.position = pos
            n.strokeColor = SKColor.blue
            self.addChild(n)
        }
    }
    
    func touchUp(atPoint pos : CGPoint) {
        if let n = self.spinnyNode?.copy() as! SKShapeNode? {
            n.position = pos
            n.strokeColor = SKColor.red
            self.addChild(n)
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let cam = cameraNode, let touch = touches.first {
            let node = cam.atPoint(touch.location(in: cam))
            if let name = node.name, name.hasPrefix("skinButton_") {
                let skinId = String(name.dropFirst("skinButton_".count))
                handleSkinButton(id: skinId)
                return
            }
            switch node.name {
            case "startButton":
                if runState == .startScreen {
                    hideStartScreenAndBegin()
                }
                return
            case "pauseButton":
                if runState == .playing { pauseGame() }
                return
            case "resetButton":
                restartRunNoCountdown()
                return
            case "resumeButton":
                resumeFromPauseWithCountdown()
                return
            case "pauseRestartButton":
                pauseOverlay?.hide()
                restartRunNoCountdown()
                return
            case "storeButton":
                if runState == .startScreen {
                    openStoreScene(from: .start)
                } else {
                    openStoreScene(from: .game)
                }
                return
            case "settingsButton":
                openSettings()
                return
            case "settingsToggleButton":
                toggleControlMode()
                return
            case "settingsCloseButton":
                closeSettings()
                return
            case "mainMenuButton":
                showStartScreen()
                return
            case "restartButton":
                restartRunNoCountdown()
                return
            default:
                break
            }

            if node.name == "sensitivityKnob" || node.name == "sensitivityTrack" {
                isDraggingSensitivity = true
                updateSensitivity(at: touch.location(in: cam))
                return
            }
        }

        if runState != .playing {
            return
        }

        if let label = self.label {
            label.run(SKAction.init(named: "Pulse")!, withKey: "fadeInOut")
        }
        
        updateMovementFlags(from: touches)
        for t in touches { self.touchDown(atPoint: t.location(in: self)) }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if isDraggingSensitivity, let cam = cameraNode, let touch = touches.first {
            updateSensitivity(at: touch.location(in: cam))
            return
        }
        if runState != .playing {
            return
        }
        updateMovementFlags(from: touches)
        for t in touches { self.touchMoved(toPoint: t.location(in: self)) }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if isDraggingSensitivity {
            isDraggingSensitivity = false
            return
        }
        if runState != .playing {
            return
        }
        moveLeft = false
        moveRight = false
        for t in touches { self.touchUp(atPoint: t.location(in: self)) }
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        if isDraggingSensitivity {
            isDraggingSensitivity = false
            return
        }
        if runState != .playing {
            return
        }
        moveLeft = false
        moveRight = false
        for t in touches { self.touchUp(atPoint: t.location(in: self)) }
    }

    override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        if runState != .playing {
            return
        }
        for press in presses {
            guard let key = press.key else { continue }
            switch key.keyCode {
            case .keyboardLeftArrow, .keyboardA:
                setMoveLeft(true)
            case .keyboardRightArrow, .keyboardD:
                setMoveRight(true)
            default:
                break
            }
        }
    }

    override func pressesEnded(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        if runState != .playing {
            return
        }
        for press in presses {
            guard let key = press.key else { continue }
            switch key.keyCode {
            case .keyboardLeftArrow, .keyboardA:
                setMoveLeft(false)
            case .keyboardRightArrow, .keyboardD:
                setMoveRight(false)
            default:
                break
            }
        }
    }

    override func pressesCancelled(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        pressesEnded(presses, with: event)
    }
    
    
    override func update(_ currentTime: TimeInterval) {
        if runState != .playing {
            return
        }

        if lastUpdateTime == 0 {
            lastUpdateTime = currentTime
        }
        var dt = currentTime - lastUpdateTime
        lastUpdateTime = currentTime
        if dt > Double(GameConfig.dtMax) { dt = Double(GameConfig.dtMax) }

        let dtf = CGFloat(dt)
        let visibleRect = currentVisibleRect()

        var vx = playerVelocity.dx
        let inputDirection = (moveRight ? 1 : 0) - (moveLeft ? 1 : 0)
        let targetAccel = computeTargetAccel(inputDirection: inputDirection)
        let deltaV = GameConfig.clamp(targetAccel * dtf, -GameConfig.playerAccelMaxDelta, GameConfig.playerAccelMaxDelta)
        vx += deltaV

        if !hasActiveInput(inputDirection: inputDirection) {
            if vx > 0 { vx = max(0, vx - GameConfig.playerFriction * dtf) }
            if vx < 0 { vx = min(0, vx + GameConfig.playerFriction * dtf) }
        }

        vx = max(-GameConfig.playerMaxSpeed, min(GameConfig.playerMaxSpeed, vx))
        playerVelocity.dx = vx

        playerVelocity.dy += GameConfig.gravity * dtf
        playerVelocity.dy = max(playerVelocity.dy, -GameConfig.maxFallSpeed)

        let prevPos = player.position
        var nextPos = CGPoint(
            x: prevPos.x + playerVelocity.dx * dtf,
            y: prevPos.y + playerVelocity.dy * dtf
        )
        if !nextPos.x.isFinite || !nextPos.y.isFinite {
            resetRunState()
            return
        }

        if nextPos.x < visibleRect.minX - GameConfig.wrapMargin {
            nextPos.x = visibleRect.maxX + GameConfig.wrapMargin
        } else if nextPos.x > visibleRect.maxX + GameConfig.wrapMargin {
            nextPos.x = visibleRect.minX - GameConfig.wrapMargin
        }

        if playerVelocity.dy <= 0 {
            let prevBottom = prevPos.y - GameConfig.playerSize.height / 2
            let nextBottom = nextPos.y - GameConfig.playerSize.height / 2
            var bestLanding: (platform: PlatformNode, top: CGFloat)? = nil

            for p in platformManager.activePlatforms {
                let platformTop = p.position.y + p.size.height / 2
                let crossedDown = (prevBottom >= platformTop)
                    && (nextBottom <= platformTop + GameConfig.landingTolerance)
                if !crossedDown { continue }

                let halfW = max(
                    0,
                    GameConfig.playerSize.width / 2 + p.size.width / 2
                        - GameConfig.horizontalLandingSlack
                )
                let dx = abs(nextPos.x - p.position.x)
                if dx > halfW { continue }

                if bestLanding == nil || platformTop > bestLanding!.top {
                    bestLanding = (p, platformTop)
                }
            }

            if let landing = bestLanding {
                nextPos.y = landing.top + GameConfig.playerSize.height / 2
                let jump = landing.platform.type == .manhole
                    ? GameConfig.springJumpVelocity
                    : GameConfig.jumpVelocity
                playerVelocity.dy = jump
                runLandingJuice(on: landing.platform)
                SfxManager.shared.playLand(isSpring: landing.platform.type == .manhole)
                if landing.platform.type == .manhole {
                    triggerCameraShake(amplitude: 4, duration: 0.08)
                }

                if landing.platform.type == .pigeon, !landing.platform.used {
                    landing.platform.used = true
                    landing.platform.run(
                        SKAction.group([
                            SKAction.moveBy(x: 0, y: 26, duration: 0.12),
                            SKAction.fadeOut(withDuration: 0.12)
                        ])
                    )
                    pendingRecycles.append(landing.platform)
                }
            }
        }

        player.position = nextPos

        var didScore = false
        if nextPos.y > prevPos.y {
            while nextPos.y >= nextScoreLineY {
                currentScore += 1
                nextScoreLineY += GameConfig.scoreLineSpacing
                handleStreak(at: currentTime)
                didScore = true
            }
        }
        if didScore {
            pulseScoreLabel()
        }

        highestPlayerY = max(highestPlayerY, player.position.y)
        updateCameraPosition()
        if !cameraBasePosition.x.isFinite || !cameraBasePosition.y.isFinite {
            resetRunState()
            return
        }
        applyCameraShake(deltaTime: dtf)
        let cameraRect = currentVisibleRect()

        let scoreInt = currentScore
        scoreLabel?.text = "Score: \(currentScore)"
        updateScoreBackground()
        updateStreakLabel()
        backgroundManager?.update(score: scoreInt, cameraY: cameraNode?.position.y ?? 0)
        platformManager.update(
            visibleRect: cameraRect,
            topYReference: max(highestPlayerY, cameraRect.maxY),
            dt: dtf,
            score: scoreInt
        )
        coinManager?.update(visibleRect: cameraRect, platforms: platformManager.activePlatforms)
        checkCoinCollection()
        updateDangerLine(score: scoreInt, deltaTime: dtf)

        if GameConfig.debugEnabled {
            debugHUD?.update(
                deltaTime: dt,
                playerY: player.position.y,
                score: scoreInt,
                platformCount: platformManager.activePlatforms.count
            )
        }

        for platform in pendingRecycles {
            platformManager.recycle(platform)
        }
        pendingRecycles.removeAll(keepingCapacity: true)

        if dangerLineEnabled {
            if player.position.y < dangerLineY {
                endGame(finalScore: scoreInt)
            }
        } else if player.position.y < cameraRect.minY - 120 {
            endGame(finalScore: scoreInt)
        }

        previousPlayerY = player.position.y
    }

    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        if let hud = debugHUD {
            positionHUD(hud)
        }
        updateScoreLabelPosition()
        updateTopButtonsPosition()
        gameOverOverlay?.updateLayout(size: size)
        pauseOverlay?.updateLayout(size: size)
        countdownOverlay?.updateLayout(size: size)
        settingsOverlay?.updateLayout(size: size)
        startOverlay?.updateLayout(size: size)
        updateDangerLineLayout()
        backgroundManager?.updateLayout(sceneSize: size)
    }

    private func positionHUD(_ hud: DebugHUD) {
        let w = size.width
        let h = size.height
        let visibleRect = CGRect(
            x: -w * anchorPoint.x,
            y: -h * anchorPoint.y,
            width: w,
            height: h
        )

        hud.position = CGPoint(x: visibleRect.minX + 12, y: visibleRect.maxY - 20)
    }

    private func currentVisibleRect() -> CGRect {
        let w = size.width
        let h = size.height
        let cx = cameraNode == nil ? 0 : cameraBasePosition.x
        let cy = cameraNode == nil ? 0 : cameraBasePosition.y
        return CGRect(x: cx - w * 0.5, y: cy - h * 0.5, width: w, height: h)
    }

    private func computeStartPosition() -> CGPoint {
        let visibleRect = currentVisibleRect()
        return CGPoint(x: visibleRect.midX, y: visibleRect.minY + 180)
    }

    private func updateMovementFlags(from touches: Set<UITouch>) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let visibleRect = currentVisibleRect()
        if location.x < visibleRect.midX {
            moveLeft = true
            moveRight = false
        } else {
            moveRight = true
            moveLeft = false
        }
    }

    private func updatePlayerWrap() {
        let visibleRect = currentVisibleRect()
        if player.position.x < visibleRect.minX - GameConfig.wrapMargin {
            player.position.x = visibleRect.maxX + GameConfig.wrapMargin
        } else if player.position.x > visibleRect.maxX + GameConfig.wrapMargin {
            player.position.x = visibleRect.minX - GameConfig.wrapMargin
        }
    }

    private func updateCameraPosition() {
        guard let cam = cameraNode else { return }
        let desired = max(cam.position.y, player.position.y - size.height * 0.15)
        cameraBasePosition = CGPoint(x: 0, y: desired)
        cam.position = cameraBasePosition
    }

    private func updateScoreLabelPosition() {
        guard cameraNode != nil, let score = scoreLabel else { return }
        score.position = CGPoint(
            x: 0,
            y: size.height * 0.5 - 34
        )
        scoreBackground?.position = CGPoint(
            x: score.position.x,
            y: score.position.y - score.frame.height * 0.5
        )
        streakLabel?.position = CGPoint(
            x: 0,
            y: score.position.y - 26
        )
        updateScoreBackground()
    }

    private func updateTopButtonsPosition() {
        guard let cam = cameraNode else { return }
        pauseButton?.position = CGPoint(x: -size.width * 0.5 + 60, y: size.height * 0.5 - 34)
        resetButton?.position = CGPoint(x: size.width * 0.5 - 60, y: size.height * 0.5 - 34)
        pauseButton?.zPosition = 10_000
        resetButton?.zPosition = 10_000
        if let pause = pauseButton, pause.parent == nil {
            cam.addChild(pause)
        }
        if let reset = resetButton, reset.parent == nil {
            cam.addChild(reset)
        }
    }

    private func updateScoreBackground() {
        guard let score = scoreLabel, let plate = scoreBackground else { return }
        let padding = CGSize(width: 16, height: 10)
        let width = score.frame.width + padding.width
        let height = score.frame.height + padding.height
        plate.path = CGPath(
            roundedRect: CGRect(x: -width * 0.5, y: -height * 0.5, width: width, height: height),
            cornerWidth: 6,
            cornerHeight: 6,
            transform: nil
        )
        plate.position = CGPoint(
            x: score.position.x,
            y: score.position.y - score.frame.height * 0.5
        )
    }

    private func endGame(finalScore: Int) {
        if isGameOver {
            return
        }
        flushRunCoinsToWallet()
        isGameOver = true
        runState = .gameOver
        if finalScore > Storage.getHighScore() {
            Storage.setHighScore(finalScore)
        }
        let highScore = Storage.getHighScore()
        player.removeAction(forKey: "playerFade")
        player.run(SKAction.fadeOut(withDuration: 0.15), withKey: "playerFade")
        backgroundManager?.setDimmed(true)
        run(
            SKAction.sequence([
                SKAction.wait(forDuration: 0.15),
                SKAction.run { [weak self] in
                    self?.gameOverOverlay?.show(score: finalScore, highScore: highScore)
                }
            ]),
            withKey: "showOverlay"
        )
    }

    private func restartGame() {
        resetRunState()
    }

    private func restartRunNoCountdown() {
        flushRunCoinsToWallet()
        resetRunState()
        runState = .playing
    }

    private func pulseScoreLabel() {
        guard let score = scoreLabel else { return }
        score.removeAction(forKey: "scorePulse")
        let up = SKAction.scale(to: 1.15, duration: 0.06)
        let down = SKAction.scale(to: 1.0, duration: 0.08)
        score.run(SKAction.sequence([up, down]), withKey: "scorePulse")
    }

    private func resetRunState() {
        isGameOver = false
        gameOverOverlay?.hide()
        pauseOverlay?.hide()
        countdownOverlay?.hide()
        settingsOverlay?.hide()
        removeAction(forKey: "showOverlay")
        cameraNode?.removeAllActions()
        cameraNode?.position = CGPoint(x: 0, y: baselineCameraY)
        cameraBasePosition = CGPoint(x: 0, y: baselineCameraY)
        cameraShakeRemaining = 0

        let startPos = computeStartPosition()
        player.position = startPos
        playerVelocity = .zero
        moveLeft = false
        moveRight = false
        lastUpdateTime = 0
        previousPlayerY = player.position.y
        highestPlayerY = player.position.y
        startY = player.position.y
        currentScore = 0
        nextScoreLineY = startY + GameConfig.scoreLineSpacing
        runCoins = 0
        runBonusCoins = 0
        streakLabel?.text = ""
        streakLabel?.alpha = 0
        streakCount = 0
        lastScoreTime = 0
        player.alpha = 1.0
        player.removeAllActions()
        if let outline = player.childNode(withName: "hitboxOutline") {
            outline.isHidden = !GameConfig.showHitboxes
        }

        let visibleRect = currentVisibleRect()
        platformManager.reset(in: visibleRect, startY: startY, score: currentScore)
        coinManager?.reset(in: visibleRect)
        scoreLabel?.text = "Score: 0"
        pendingRecycles.removeAll()
        backgroundManager?.reset()
        backgroundManager?.setDimmed(false)
        applySelectedSkin()
        dangerLineEnabled = false
        dangerLineY = currentVisibleRect().minY - 200
        dangerLine?.isHidden = true
        dangerLabel?.alpha = 0
        updateDangerLineLayout()
    }

    private func startCountdown() {
        runState = .countdown
        countdownOverlay?.start { [weak self] in
            self?.runState = .playing
        }
    }

    private func startNewRunNoCountdown() {
        resetRunState()
        runState = .playing
    }

    private func pauseGame() {
        runState = .paused
        moveLeft = false
        moveRight = false
        pauseOverlay?.show()
    }

    private func resumeFromPauseWithCountdown() {
        pauseOverlay?.hide()
        startCountdown()
    }

    private func openSettings() {
        settingsReturnState = runState
        runState = .paused
        pauseOverlay?.hide()
        updateSettingsOverlay()
        settingsOverlay?.show(modeText: controlModeText(), sensitivity: controlSensitivity)
    }

    private func closeSettings() {
        settingsOverlay?.hide()
        if settingsReturnState == .paused {
            pauseOverlay?.show()
        }
        runState = settingsReturnState
    }

    private func showStartScreen() {
        runState = .startScreen
        pauseOverlay?.hide()
        gameOverOverlay?.hide()
        countdownOverlay?.hide()
        settingsOverlay?.hide()
        startOverlay?.show(highScore: Storage.getHighScore(), wallet: Storage.getWalletCoins())
    }

    private func hideStartScreenAndBegin() {
        startOverlay?.fadeOut { [weak self] in
            self?.startNewRunNoCountdown()
        }
    }

    private func toggleControlMode() {
        if controlMode == .tap {
            if motionManager.isDeviceMotionAvailable {
                controlMode = .tilt
                Storage.setControlMode("tilt")
            } else {
                controlMode = .tap
                Storage.setControlMode("tap")
            }
        } else {
            controlMode = .tap
            Storage.setControlMode("tap")
        }
        updateSettingsOverlay()
    }

    private func updateSettingsOverlay() {
        settingsOverlay?.update(modeText: controlModeText(), sensitivity: controlSensitivity)
    }

    private func updateSensitivity(at location: CGPoint) {
        guard let overlay = settingsOverlay else { return }
        let value = overlay.sensitivityFromTouch(x: location.x)
        controlSensitivity = value
        Storage.setControlSensitivity(value)
        updateSettingsOverlay()
    }

    private func handleSkinButton(id: String) {
        guard let skin = StoreOverlay.skin(for: id) else { return }
        var owned = Set(Storage.getOwnedSkins())
        var wallet = Storage.getWalletCoins()

        if owned.contains(id) {
            Storage.setSelectedSkin(id)
        } else if wallet >= skin.price {
            wallet -= skin.price
            owned.insert(id)
            Storage.setWalletCoins(wallet)
            Storage.setOwnedSkins(Array(owned))
            Storage.setSelectedSkin(id)
        }

        applySelectedSkin()
    }

    private func applySelectedSkin() {
        let skinId = Storage.getSelectedSkin()
        player.color = StoreOverlay.color(for: skinId)
    }

    func refreshSelectedSkin() {
        applySelectedSkin()
    }

    private func openStoreScene(from target: StoreReturnTarget) {
        guard let view = self.view else { return }
        storeReturnTarget = target
        if target == .game {
            runState = .paused
            pauseOverlay?.hide()
        }
        let storeScene = StoreScene(size: size)
        storeScene.scaleMode = scaleMode
        storeScene.returnTarget = target == .game ? .game : .start
        if target == .game {
            SceneRouter.shared.cachedGameScene = self
            SceneRouter.shared.cachedScaleMode = scaleMode
        } else {
            SceneRouter.shared.cachedGameScene = nil
        }
        view.presentScene(storeScene, transition: SKTransition.fade(withDuration: 0.2))
    }

    private func controlModeText() -> String {
        controlMode == .tilt ? "Tilt" : "Tap"
    }

    private func computeTargetAccel(inputDirection: Int) -> CGFloat {
        if controlMode == .tilt {
            guard motionManager.isDeviceMotionAvailable, let motion = motionManager.deviceMotion else {
                controlMode = .tap
                Storage.setControlMode("tap")
                return CGFloat(inputDirection) * GameConfig.playerMoveAccel
            }
            let gx = CGFloat(motion.gravity.x)
            tiltValue = tiltValue * 0.9 + gx * 0.1
            return tiltValue * controlSensitivity * GameConfig.playerMoveAccel
        }
        return CGFloat(inputDirection) * GameConfig.playerMoveAccel
    }

    private func hasActiveInput(inputDirection: Int) -> Bool {
        if controlMode == .tilt {
            return abs(tiltValue) > 0.02
        }
        return inputDirection != 0
    }

    private func handleStreak(at time: TimeInterval) {
        if lastScoreTime == 0 {
            streakCount = 0
            lastScoreTime = time
            return
        }
        let elapsed = time - lastScoreTime
        if elapsed <= GameConfig.streakWindow {
            streakCount += 1
            runBonusCoins += 1
        } else {
            streakCount = 0
        }
        lastScoreTime = time
    }

    private func updateStreakLabel() {
        guard let label = streakLabel else { return }
        if streakCount <= 0 {
            label.removeAction(forKey: "streakFade")
            let fade = SKAction.fadeOut(withDuration: 0.2)
            label.run(fade, withKey: "streakFade")
            return
        }
        let capped = min(streakCount, GameConfig.streakMax)
        let multiplier = 1.0 + CGFloat(capped) * GameConfig.streakMultiplierStep
        label.removeAction(forKey: "streakFade")
        label.alpha = 1.0
        label.text = String(format: "Streak x%.1f", multiplier)
    }

    private func updateDangerLine(score: Int, deltaTime: CGFloat) {
        guard let line = dangerLine else { return }
        if !dangerLineEnabled && score >= GameConfig.dangerLineStartScore {
            dangerLineEnabled = true
            dangerLineY = currentVisibleRect().minY - 120
            line.isHidden = false
            showDangerLineWarning()
        }
        guard dangerLineEnabled else { return }
        var speedMultiplier: CGFloat = 1.0
        if score >= GameConfig.dangerLineSpeedupStartScore {
            let t = GameConfig.clamp(
                CGFloat(score - GameConfig.dangerLineSpeedupStartScore)
                    / CGFloat(max(1, GameConfig.dangerLineSpeedupEndScore - GameConfig.dangerLineSpeedupStartScore)),
                0,
                1
            )
            speedMultiplier = 1.0 + (GameConfig.dangerLineMaxMultiplier - 1.0) * t
        }
        let speed = GameConfig.dangerLineBaseSpeed * speedMultiplier
        dangerLineY += speed * deltaTime
        line.position = CGPoint(x: cameraBasePosition.x, y: dangerLineY)
    }

    private func updateDangerLineLayout() {
        guard let line = dangerLine else { return }
        line.path = CGPath(rect: CGRect(x: -size.width * 0.5, y: -1, width: size.width, height: 2), transform: nil)
        dangerLabel?.position = CGPoint(x: 0, y: size.height * 0.5 - 70)
    }

    private func checkCoinCollection() {
        guard let coinManager = coinManager else { return }
        let halfW = GameConfig.playerSize.width * 0.5
        let halfH = GameConfig.playerSize.height * 0.5
        let radius = GameConfig.coinRadius
        for coin in coinManager.active {
            if coin.isCollected { continue }
            let dx = abs(player.position.x - coin.position.x)
            let dy = abs(player.position.y - coin.position.y)
            if dx <= halfW + radius && dy <= halfH + radius {
                runCoins += 1
                spawnPickupText(text: "+1", at: coin.position, color: .yellow)
                SfxManager.shared.playCoin()
                coinManager.collect(coin)
            }
        }
    }

    private func spawnPickupText(text: String, at position: CGPoint, color: SKColor) {
        let label = SKLabelNode(fontNamed: GameConfig.debugFontName)
        label.text = text
        label.fontSize = 14
        label.fontColor = color
        label.position = position
        label.zPosition = 2000
        addChild(label)
        let rise = SKAction.moveBy(x: 0, y: 22, duration: 0.35)
        let fade = SKAction.fadeOut(withDuration: 0.35)
        let scale = SKAction.scale(to: 1.15, duration: 0.15)
        let group = SKAction.group([rise, fade, scale])
        label.run(SKAction.sequence([group, .removeFromParent()]))
    }

    private func showDangerLineWarning() {
        guard let label = dangerLabel, let line = dangerLine else { return }
        label.removeAction(forKey: "dangerPulse")
        label.alpha = 1.0
        label.position = CGPoint(x: 0, y: size.height * 0.5 - 70)
        SfxManager.shared.playDanger()
        let flash = SKAction.sequence([
            SKAction.fadeAlpha(to: 0.2, duration: 0.12),
            SKAction.fadeAlpha(to: 1.0, duration: 0.12)
        ])
        let pulse = SKAction.sequence([
            SKAction.repeat(flash, count: 4),
            SKAction.fadeOut(withDuration: 0.3)
        ])
        label.run(pulse, withKey: "dangerPulse")

        line.removeAction(forKey: "dangerFlash")
        let lineFlash = SKAction.sequence([
            SKAction.fadeAlpha(to: 0.15, duration: 0.1),
            SKAction.fadeAlpha(to: 1.0, duration: 0.1)
        ])
        line.run(SKAction.repeat(lineFlash, count: 6), withKey: "dangerFlash")
    }

    private func flushRunCoinsToWallet() {
        if runCoins <= 0 && runBonusCoins <= 0 { return }
        let wallet = Storage.getWalletCoins()
        Storage.setWalletCoins(wallet + runCoins + runBonusCoins)
        runCoins = 0
        runBonusCoins = 0
    }

    private func runLandingJuice(on platform: PlatformNode) {
        player.removeAction(forKey: "squash")
        let squash = SKAction.scaleX(to: GameConfig.bounceSquashX, y: GameConfig.bounceSquashY, duration: 0.04)
        let stretch = SKAction.scaleX(to: 1.0, y: 1.0, duration: 0.08)
        player.run(SKAction.sequence([squash, stretch]), withKey: "squash")

        let original = platform.color
        platform.removeAction(forKey: "platformFlash")
        platform.color = darkenColor(original, amount: 0.1)
        platform.run(
            SKAction.sequence([
                SKAction.wait(forDuration: 0.05),
                SKAction.run { platform.color = original }
            ]),
            withKey: "platformFlash"
        )
    }

    private func triggerCameraShake(amplitude: CGFloat, duration: CGFloat) {
        guard !isGameOver else { return }
        cameraShakeAmplitude = amplitude
        cameraShakeDuration = duration
        cameraShakeRemaining = duration
    }

    private func applyCameraShake(deltaTime: CGFloat) {
        guard let cam = cameraNode, cameraShakeRemaining > 0 else { return }
        cameraShakeRemaining = max(0, cameraShakeRemaining - deltaTime)
        let progress = cameraShakeDuration > 0 ? cameraShakeRemaining / cameraShakeDuration : 0
        let strength = cameraShakeAmplitude * progress
        let offsetX = (Bool.random() ? 1 : -1) * strength
        let offsetY = (Bool.random() ? 1 : -1) * strength
        cam.position = CGPoint(x: cameraBasePosition.x + offsetX, y: cameraBasePosition.y + offsetY)
        if cameraShakeRemaining == 0 {
            cam.position = cameraBasePosition
        }
    }

    private func darkenColor(_ color: SKColor, amount: CGFloat) -> SKColor {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        if color.getRed(&r, green: &g, blue: &b, alpha: &a) {
            return SKColor(
                red: max(0, r - amount),
                green: max(0, g - amount),
                blue: max(0, b - amount),
                alpha: a
            )
        }
        return color
    }

    func setMoveLeft(_ isDown: Bool) {
        moveLeft = isDown
        if isDown { moveRight = false }
    }

    func setMoveRight(_ isDown: Bool) {
        moveRight = isDown
        if isDown { moveLeft = false }
    }
}
