import SpriteKit

final class CoinManager {
    private weak var scene: SKScene?
    private(set) var active: [CoinNode] = []
    private var pool: [CoinNode] = []
    private var totalCreated: Int = 0
    private var lastProcessedPlatformY: CGFloat = -CGFloat.greatestFiniteMagnitude
    private var platformsSinceSpawn: Int = 0

    init(scene: SKScene) {
        self.scene = scene
    }

    func reset(in visibleRect: CGRect) {
        for coin in active {
            coin.removeAllActions()
            coin.removeFromParent()
            pool.append(coin)
        }
        active.removeAll(keepingCapacity: true)
        lastProcessedPlatformY = visibleRect.minY
        platformsSinceSpawn = 0
    }

    func update(visibleRect: CGRect, platforms: [PlatformNode]) {
        recycleBelow(y: visibleRect.minY - GameConfig.coinRecycleBelow)
        spawnCoinsIfNeeded(visibleRect: visibleRect, platforms: platforms)
    }

    func collect(_ coin: CoinNode) {
        guard let index = active.firstIndex(where: { $0 === coin }) else { return }
        active.remove(at: index)
        coin.isCollected = true
        coin.removeAllActions()
        let pop = SKAction.sequence([
            SKAction.scale(to: 1.2, duration: 0.05),
            SKAction.scale(to: 0.0, duration: 0.05),
            SKAction.run { [weak self, weak coin] in
                guard let coin = coin else { return }
                self?.recycle(coin)
            }
        ])
        coin.run(pop, withKey: "coinPop")
    }

    private func recycleBelow(y: CGFloat) {
        if active.isEmpty { return }
        for i in stride(from: active.count - 1, through: 0, by: -1) {
            let coin = active[i]
            if coin.position.y < y {
                active.remove(at: i)
                recycle(coin)
            }
        }
    }

    private func spawnCoinsIfNeeded(visibleRect: CGRect, platforms: [PlatformNode]) {
        if active.count >= GameConfig.coinCountTarget {
            return
        }
        if platforms.isEmpty { return }
        let sorted = platforms.sorted { $0.position.y < $1.position.y }
        for platform in sorted where platform.position.y > lastProcessedPlatformY {
            platformsSinceSpawn += 1
            if platformsSinceSpawn >= 3 {
                let count = Int.random(in: 0...2)
                if count > 0 {
                    spawnCoins(count, near: platform, visibleRect: visibleRect)
                }
                platformsSinceSpawn = 0
            }
            lastProcessedPlatformY = max(lastProcessedPlatformY, platform.position.y)
            if active.count >= GameConfig.coinCountTarget {
                break
            }
        }
    }

    private func spawnCoins(_ count: Int, near platform: PlatformNode, visibleRect: CGRect) {
        for _ in 0..<count {
            guard let coin = obtainCoin() else { return }
            let xOffset = CGFloat.random(in: -GameConfig.coinSpawnXOffset...GameConfig.coinSpawnXOffset)
            let yOffset = CGFloat.random(in: GameConfig.coinSpawnYMin...GameConfig.coinSpawnYMax)

            let minX = visibleRect.minX + GameConfig.coinRadius + GameConfig.spawnXPadding
            let maxX = visibleRect.maxX - GameConfig.coinRadius - GameConfig.spawnXPadding
            let x = min(max(platform.position.x + xOffset, minX), maxX)
            let y = platform.position.y + yOffset

            coin.prepareForReuse()
            coin.position = CGPoint(x: x, y: y)
            if coin.parent == nil {
                scene?.addChild(coin)
            }
            active.append(coin)
        }
    }

    private func obtainCoin() -> CoinNode? {
        if let coin = pool.popLast() {
            return coin
        }
        if totalCreated >= GameConfig.coinCountCap {
            return nil
        }
        totalCreated += 1
        return CoinNode.make()
    }

    private func recycle(_ coin: CoinNode) {
        coin.removeAllActions()
        coin.removeFromParent()
        pool.append(coin)
    }
}
