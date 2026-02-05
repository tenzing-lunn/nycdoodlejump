import SpriteKit

final class StoreScene: SKScene {
    enum ReturnTarget {
        case start
        case game
    }

    var returnTarget: ReturnTarget = .start

    private struct ItemRow {
        let rowRoot: SKNode
        let swatch: SKShapeNode
        let nameLabel: SKLabelNode
        let priceLabel: SKLabelNode
        let actionPlate: SKShapeNode
        let actionLabel: SKLabelNode
        let itemId: String
    }

    private let uiRoot = SKNode()
    private let titleLabel = SKLabelNode(fontNamed: GameConfig.debugFontName)
    private let walletLabel = SKLabelNode(fontNamed: GameConfig.debugFontName)
    private let backButtonPlate = SKShapeNode()
    private let backButtonLabel = SKLabelNode(fontNamed: GameConfig.debugFontName)
    private let toastLabel = SKLabelNode(fontNamed: GameConfig.debugFontName)
    private var itemRows: [ItemRow] = []
    private var isBuilt = false

    override func didMove(to view: SKView) {
        anchorPoint = CGPoint(x: 0.5, y: 0.5)
        backgroundColor = .black
        if uiRoot.parent == nil {
            addChild(uiRoot)
        }
        uiRoot.position = .zero
        buildUIIfNeeded()
        layout()
        refreshUI()
    }

    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        layout()
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let node = atPoint(touch.location(in: self))
        guard let name = node.name else { return }
        if name == "backButton" {
            returnToPreviousScene()
            return
        }
        if name.hasPrefix("action_") {
            let id = String(name.dropFirst("action_".count))
            handleItemTap(id: id)
        }
    }

    private func handleItemTap(id: String) {
        guard let item = SkinCatalog.item(for: id) else { return }
        var wallet = Storage.getWalletCoins()
        var owned = Set(Storage.getOwnedSkins())
        let selected = Storage.getSelectedSkin()

        if owned.contains(id) {
            if selected != id {
                Storage.setSelectedSkin(id)
            }
        } else {
            if wallet >= item.price {
                wallet -= item.price
                Storage.setWalletCoins(wallet)
                owned.insert(id)
                Storage.setOwnedSkins(Array(owned))
                Storage.setSelectedSkin(id)
            } else {
                showToast("Not enough coins")
                return
            }
        }
        SceneRouter.shared.cachedGameScene?.refreshSelectedSkin()
        refreshUI()
    }

    private func refreshUI() {
        let wallet = Storage.getWalletCoins()
        let owned = Set(Storage.getOwnedSkins())
        let selected = Storage.getSelectedSkin()
        walletLabel.text = "Coins: \(wallet)"

        for item in SkinCatalog.items {
            guard let row = itemRows.first(where: { $0.itemId == item.id }) else { continue }
            if selected == item.id {
                row.actionLabel.text = "Selected"
                row.actionPlate.alpha = 0.35
            } else if owned.contains(item.id) {
                row.actionLabel.text = "Select"
                row.actionPlate.alpha = 1.0
            } else {
                row.actionLabel.text = "Buy"
                row.actionPlate.alpha = 1.0
            }
        }
    }

    private func showToast(_ text: String) {
        toastLabel.removeAction(forKey: "toast")
        toastLabel.text = text
        toastLabel.alpha = 1.0
        let sequence = SKAction.sequence([
            SKAction.wait(forDuration: 0.8),
            SKAction.fadeOut(withDuration: 0.2)
        ])
        toastLabel.run(sequence, withKey: "toast")
    }

    private func returnToPreviousScene() {
        guard let view = view else { return }
        switch returnTarget {
        case .game:
            if let cached = SceneRouter.shared.cachedGameScene {
                cached.refreshSelectedSkin()
                cached.scaleMode = SceneRouter.shared.cachedScaleMode
                view.presentScene(cached, transition: SKTransition.fade(withDuration: 0.2))
                SceneRouter.shared.cachedGameScene = nil
            } else {
                presentNewGameScene(view: view)
            }
        case .start:
            presentNewGameScene(view: view)
        }
    }

    private func presentNewGameScene(view: SKView) {
        let scene = (SKScene(fileNamed: "GameScene") as? GameScene) ?? GameScene(size: view.bounds.size)
        scene.scaleMode = SceneRouter.shared.cachedScaleMode
        view.presentScene(scene, transition: SKTransition.fade(withDuration: 0.2))
    }

    private func buildUIIfNeeded() {
        guard !isBuilt else { return }
        isBuilt = true
        uiRoot.zPosition = 1000

        titleLabel.text = "STORE"
        titleLabel.fontSize = 26
        titleLabel.fontColor = .white
        uiRoot.addChild(titleLabel)

        walletLabel.fontSize = 18
        walletLabel.fontColor = .white
        uiRoot.addChild(walletLabel)

        backButtonPlate.path = CGPath(
            roundedRect: CGRect(x: -50, y: -18, width: 100, height: 36),
            cornerWidth: 10,
            cornerHeight: 10,
            transform: nil
        )
        backButtonPlate.fillColor = SKColor(white: 1.0, alpha: 0.15)
        backButtonPlate.strokeColor = SKColor(white: 1.0, alpha: 0.3)
        backButtonPlate.name = "backButton"
        backButtonPlate.zPosition = 1
        uiRoot.addChild(backButtonPlate)

        backButtonLabel.text = "Back"
        backButtonLabel.fontSize = 16
        backButtonLabel.fontColor = .white
        backButtonLabel.name = "backButton"
        uiRoot.addChild(backButtonLabel)

        for item in SkinCatalog.items {
            let rowRoot = SKNode()
            uiRoot.addChild(rowRoot)

            let swatch = SKShapeNode(rectOf: CGSize(width: 28, height: 28), cornerRadius: 5)
            swatch.fillColor = item.color
            swatch.strokeColor = .clear
            rowRoot.addChild(swatch)

            let nameLabel = SKLabelNode(fontNamed: GameConfig.debugFontName)
            nameLabel.text = item.name
            nameLabel.fontSize = 16
            nameLabel.fontColor = .white
            nameLabel.horizontalAlignmentMode = .left
            nameLabel.verticalAlignmentMode = .center
            rowRoot.addChild(nameLabel)

            let priceLabel = SKLabelNode(fontNamed: GameConfig.debugFontName)
            priceLabel.text = "\(item.price)"
            priceLabel.fontSize = 13
            priceLabel.fontColor = .white
            priceLabel.horizontalAlignmentMode = .left
            priceLabel.verticalAlignmentMode = .center
            rowRoot.addChild(priceLabel)

            let actionPlate = SKShapeNode()
            actionPlate.path = CGPath(
                roundedRect: CGRect(x: -60, y: -20, width: 120, height: 40),
                cornerWidth: 10,
                cornerHeight: 10,
                transform: nil
            )
            actionPlate.fillColor = SKColor(white: 1.0, alpha: 0.15)
            actionPlate.strokeColor = SKColor(white: 1.0, alpha: 0.25)
            actionPlate.name = "action_\(item.id)"
            actionPlate.zPosition = 1
            rowRoot.addChild(actionPlate)

            let actionLabel = SKLabelNode(fontNamed: GameConfig.debugFontName)
            actionLabel.fontSize = 14
            actionLabel.fontColor = .white
            actionLabel.horizontalAlignmentMode = .center
            actionLabel.verticalAlignmentMode = .center
            actionLabel.name = "action_\(item.id)"
            rowRoot.addChild(actionLabel)

            let row = ItemRow(
                rowRoot: rowRoot,
                swatch: swatch,
                nameLabel: nameLabel,
                priceLabel: priceLabel,
                actionPlate: actionPlate,
                actionLabel: actionLabel,
                itemId: item.id
            )
            itemRows.append(row)
        }

        toastLabel.fontSize = 14
        toastLabel.fontColor = .white
        toastLabel.alpha = 0
        uiRoot.addChild(toastLabel)
    }

    private func layout() {
        let topY = size.height * 0.5 - 60
        titleLabel.position = CGPoint(x: 0, y: topY)
        walletLabel.position = CGPoint(x: 0, y: topY - 36)

        backButtonPlate.position = CGPoint(x: -size.width * 0.5 + 64, y: size.height * 0.5 - 48)
        backButtonLabel.position = backButtonPlate.position

        let startY = walletLabel.position.y - 70
        let rowSpacing: CGFloat = 62
        let leftX: CGFloat = -140
        let textX: CGFloat = -105
        let buttonX: CGFloat = 140

        for (index, row) in itemRows.enumerated() {
            row.rowRoot.position = CGPoint(x: 0, y: startY - CGFloat(index) * rowSpacing)
            row.swatch.position = CGPoint(x: leftX, y: 0)
            row.nameLabel.position = CGPoint(x: textX, y: 6)
            row.priceLabel.position = CGPoint(x: textX, y: -16)
            row.actionPlate.position = CGPoint(x: buttonX, y: 0)
            row.actionLabel.position = row.actionPlate.position
        }

        toastLabel.position = CGPoint(x: 0, y: -size.height * 0.5 + 70)
    }
}
