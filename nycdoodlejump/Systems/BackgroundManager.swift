import SpriteKit

final class BackgroundManager {
    enum Zone {
        case street
        case midrise
        case skyscraper
    }

    private enum LayerKind {
        case far
        case near
    }

    private struct Palette {
        let base: SKColor
        let primary: SKColor
        let secondary: SKColor
        let accent: SKColor
    }

    private unowned let scene: SKScene
    private unowned let camera: SKCameraNode

    private let baseColorNode = SKSpriteNode()
    private let farLayerNode = SKNode()
    private let nearLayerNode = SKNode()
    private let noiseNode = SKSpriteNode()

    private var farPanels: [SKNode] = []
    private var nearPanels: [SKNode] = []
    private var panelHeight: CGFloat = 0
    private var currentZone: Zone = .street

    init(scene: SKScene, camera: SKCameraNode) {
        self.scene = scene
        self.camera = camera
        setupNodes()
        reset()
    }

    func update(score: Int, cameraY: CGFloat) {
        let zone = zoneForScore(score)
        if zone != currentZone {
            currentZone = zone
            rebuildPanels()
        }

        let cameraX = camera.position.x
        baseColorNode.position = CGPoint(x: cameraX, y: cameraY)
        farLayerNode.position = CGPoint(x: cameraX, y: cameraY * 0.25)
        nearLayerNode.position = CGPoint(x: cameraX, y: cameraY * 0.55)
        noiseNode.position = CGPoint(x: cameraX, y: cameraY)

        recyclePanels(panels: farPanels, layerNode: farLayerNode, cameraY: cameraY)
        recyclePanels(panels: nearPanels, layerNode: nearLayerNode, cameraY: cameraY)
    }

    func reset() {
        panelHeight = scene.size.height
        baseColorNode.size = scene.size
        baseColorNode.position = .zero
        currentZone = .street

        setupPanelsIfNeeded()
        layoutPanels()
        rebuildPanels()
        setupNoise()
    }

    func setDimmed(_ dimmed: Bool) {
        baseColorNode.alpha = dimmed ? 0.7 : 1.0
    }

    func updateLayout(sceneSize: CGSize) {
        panelHeight = sceneSize.height
        baseColorNode.size = sceneSize
        layoutPanels()
        rebuildPanels()
        setupNoise()
    }

    private func setupNodes() {
        baseColorNode.zPosition = -10_000
        farLayerNode.zPosition = -9_000
        nearLayerNode.zPosition = -8_000
        noiseNode.zPosition = -7_500

        scene.addChild(baseColorNode)
        scene.addChild(farLayerNode)
        scene.addChild(nearLayerNode)
        scene.addChild(noiseNode)
    }

    private func setupPanelsIfNeeded() {
        if farPanels.isEmpty {
            farPanels = makePanels()
            farPanels.forEach { farLayerNode.addChild($0) }
        }
        if nearPanels.isEmpty {
            nearPanels = makePanels()
            nearPanels.forEach { nearLayerNode.addChild($0) }
        }
    }

    private func makePanels() -> [SKNode] {
        let panels = (0..<3).map { _ in SKNode() }
        return panels
    }

    private func layoutPanels() {
        let positions: [CGFloat] = [-panelHeight, 0, panelHeight]
        for (index, panel) in farPanels.enumerated() {
            panel.position = CGPoint(x: 0, y: positions[index])
        }
        for (index, panel) in nearPanels.enumerated() {
            panel.position = CGPoint(x: 0, y: positions[index])
        }
    }

    private func rebuildPanels() {
        let palette = paletteForZone(currentZone)
        baseColorNode.color = palette.base

        for panel in farPanels {
            panel.removeAllChildren()
            buildPanel(into: panel, layer: .far, palette: palette)
        }
        for panel in nearPanels {
            panel.removeAllChildren()
            buildPanel(into: panel, layer: .near, palette: palette)
        }
    }

    private func buildPanel(into panel: SKNode, layer: LayerKind, palette: Palette) {
        let size = scene.size
        let background = SKSpriteNode(color: palette.base, size: size)
        background.position = CGPoint(x: 0, y: panelHeight * 0.5)
        background.zPosition = -1
        panel.addChild(background)

        switch currentZone {
        case .street:
            buildStreetMotifs(into: panel, layer: layer, palette: palette, size: size)
        case .midrise:
            buildMidriseMotifs(into: panel, layer: layer, palette: palette, size: size)
        case .skyscraper:
            buildSkyscraperMotifs(into: panel, layer: layer, palette: palette, size: size)
        }
    }

    private func buildStreetMotifs(into panel: SKNode, layer: LayerKind, palette: Palette, size: CGSize) {
        let yBase: CGFloat = 30
        let width = size.width
        let height = panelHeight

        if layer == .near {
            let shopWidth: CGFloat = width / 4
            for i in 0..<4 {
                let rect = SKShapeNode(rectOf: CGSize(width: shopWidth - 12, height: 60))
                rect.fillColor = palette.primary
                rect.strokeColor = .clear
                rect.position = CGPoint(x: -width / 2 + shopWidth * (CGFloat(i) + 0.5),
                                        y: yBase + 40)
                panel.addChild(rect)
            }
        } else {
            for i in 0..<3 {
                let pole = SKShapeNode(rectOf: CGSize(width: 6, height: 80))
                pole.fillColor = palette.secondary
                pole.strokeColor = .clear
                pole.position = CGPoint(x: -width / 3 + CGFloat(i) * (width / 3),
                                        y: yBase + 40)
                panel.addChild(pole)
            }
        }

        let asphalt = SKShapeNode(rectOf: CGSize(width: width, height: height * 0.15))
        asphalt.fillColor = palette.accent
        asphalt.strokeColor = .clear
        asphalt.position = CGPoint(x: 0, y: height * 0.15 * 0.5)
        panel.addChild(asphalt)
    }

    private func buildMidriseMotifs(into panel: SKNode, layer: LayerKind, palette: Palette, size: CGSize) {
        let width = size.width
        let height = panelHeight

        for i in 0..<3 {
            let rect = SKShapeNode(rectOf: CGSize(width: width / 3.2, height: height * 0.5))
            rect.fillColor = palette.primary
            rect.strokeColor = .clear
            rect.position = CGPoint(x: -width / 3 + CGFloat(i) * (width / 3),
                                    y: height * 0.35)
            panel.addChild(rect)

            if layer == .near {
                for row in 0..<3 {
                    let win = SKShapeNode(rectOf: CGSize(width: 10, height: 10))
                    win.fillColor = palette.accent
                    win.strokeColor = .clear
                    win.position = CGPoint(x: rect.position.x - 20 + CGFloat(row) * 20,
                                           y: rect.position.y - 40 + CGFloat(row) * 18)
                    panel.addChild(win)
                }
            }
        }
    }

    private func buildSkyscraperMotifs(into panel: SKNode, layer: LayerKind, palette: Palette, size: CGSize) {
        let width = size.width
        let height = panelHeight

        for i in 0..<4 {
            let rect = SKShapeNode(rectOf: CGSize(width: width / 5, height: height * 0.7))
            rect.fillColor = palette.primary
            rect.strokeColor = .clear
            rect.position = CGPoint(x: -width / 2 + CGFloat(i + 1) * (width / 5),
                                    y: height * 0.45)
            panel.addChild(rect)

            if layer == .far {
                let stripe = SKShapeNode(rectOf: CGSize(width: rect.frame.width * 0.7, height: 6))
                stripe.fillColor = palette.secondary
                stripe.strokeColor = .clear
                stripe.position = CGPoint(x: rect.position.x, y: rect.position.y + 40)
                panel.addChild(stripe)
            }
        }
    }

    private func recyclePanels(panels: [SKNode], layerNode: SKNode, cameraY: CGFloat) {
        let threshold = cameraY - panelHeight * 1.5
        for panel in panels {
            let worldY = layerNode.position.y + panel.position.y
            if worldY < threshold {
                panel.position.y += panelHeight * 3
            }
        }
    }

    private func zoneForScore(_ score: Int) -> Zone {
        if score < 1000 {
            return .street
        } else if score < 3000 {
            return .midrise
        } else {
            return .skyscraper
        }
    }

    private func paletteForZone(_ zone: Zone) -> Palette {
        switch zone {
        case .street:
            return Palette(
                base: SKColor(red: 0.18, green: 0.2, blue: 0.22, alpha: 1.0),
                primary: SKColor(red: 0.78, green: 0.65, blue: 0.2, alpha: 1.0),
                secondary: SKColor(red: 0.58, green: 0.25, blue: 0.18, alpha: 1.0),
                accent: SKColor(red: 0.1, green: 0.12, blue: 0.13, alpha: 1.0)
            )
        case .midrise:
            return Palette(
                base: SKColor(red: 0.2, green: 0.18, blue: 0.22, alpha: 1.0),
                primary: SKColor(red: 0.55, green: 0.32, blue: 0.2, alpha: 1.0),
                secondary: SKColor(red: 0.28, green: 0.4, blue: 0.45, alpha: 1.0),
                accent: SKColor(red: 0.72, green: 0.58, blue: 0.28, alpha: 1.0)
            )
        case .skyscraper:
            return Palette(
                base: SKColor(red: 0.12, green: 0.16, blue: 0.25, alpha: 1.0),
                primary: SKColor(red: 0.28, green: 0.42, blue: 0.65, alpha: 1.0),
                secondary: SKColor(red: 0.62, green: 0.7, blue: 0.78, alpha: 1.0),
                accent: SKColor(red: 0.18, green: 0.55, blue: 0.5, alpha: 1.0)
            )
        }
    }

    private func setupNoise() {
        noiseNode.texture = PixelArtFactory.noiseTexture()
        noiseNode.size = scene.size
        noiseNode.alpha = 0.12
        noiseNode.color = SKColor(white: 1.0, alpha: 1.0)
        noiseNode.colorBlendFactor = 1.0
        noiseNode.blendMode = .alpha
    }
}
