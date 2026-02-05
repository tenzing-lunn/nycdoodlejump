import SpriteKit

final class PlatformManager {
    private unowned let scene: SKScene
    private(set) var active: [PlatformNode] = []
    var activePlatforms: [PlatformNode] { active }
    private var pool: [PlatformNode] = []
    private var highestPlatformY: CGFloat = 0
    private var spawnedCountSinceReset: Int = 0
    private var totalCreated: Int = 0
    private var invalidSpawnCount: Int = 0
    private var recentTypes: [PlatformNode.PlatformType] = []
    private let recentTypesMax: Int = 6
    private var anchorX: CGFloat = 0
    private var anchorY: CGFloat = 0
    private var zigDir: CGFloat = 1
    private var spawnLaneWidth: CGFloat = 0
    private var easyRunRemaining: Int = 0
    private var hardRunRemaining: Int = 0
    private var lastClusterScore: Int = 0
    private var lastGap: CGFloat = 0

    init(scene: SKScene) {
        self.scene = scene
    }

    func bootstrap(in visibleRect: CGRect) {
        highestPlatformY = visibleRect.minY - GameConfig.gapEasyMax
        spawnedCountSinceReset = 0
        totalCreated = active.count + pool.count
        invalidSpawnCount = 0
        recentTypes.removeAll(keepingCapacity: true)
        anchorX = visibleRect.midX
        anchorY = visibleRect.minY
        zigDir = Bool.random() ? 1 : -1
        spawnLaneWidth = min(220, visibleRect.width * 0.32)
        easyRunRemaining = 0
        hardRunRemaining = 0
        lastClusterScore = 0
        lastGap = 0
        spawnPlatforms(upTo: visibleRect.maxY + GameConfig.spawnAhead, visibleRect: visibleRect, score: 0)
    }

    func update(visibleRect: CGRect, topYReference: CGFloat, dt: CGFloat, score: Int) {
        recyclePlatforms(below: visibleRect.minY - GameConfig.recycleBelow)
        let targetTop = topYReference + GameConfig.spawnAhead
        spawnPlatforms(upTo: targetTop, visibleRect: visibleRect, score: score)
        updateMovingPlatforms(visibleRect: visibleRect, dt: dt)
    }

    func reset(in visibleRect: CGRect, startY: CGFloat, score: Int = 0) {
        for platform in active {
            platform.removeFromParent()
            pool.append(platform)
        }
        active.removeAll()
        highestPlatformY = startY - GameConfig.gapEasyMax
        spawnedCountSinceReset = 0
        totalCreated = active.count + pool.count
        invalidSpawnCount = 0
        recentTypes.removeAll(keepingCapacity: true)
        anchorX = visibleRect.midX
        anchorY = startY
        zigDir = Bool.random() ? 1 : -1
        spawnLaneWidth = min(220, visibleRect.width * 0.32)
        easyRunRemaining = 0
        hardRunRemaining = 0
        lastClusterScore = score
        lastGap = 0

        let startingPlatform = pool.popLast() ?? PlatformNode.make()
        startingPlatform.configure(as: .taxi)
        startingPlatform.position = CGPoint(
            x: visibleRect.midX,
            y: startY - GameConfig.playerSize.height * 0.5 - GameConfig.platformSize.height * 0.5
        )
        addPlatform(startingPlatform)

        spawnPlatforms(
            upTo: visibleRect.maxY + GameConfig.spawnAhead,
            visibleRect: visibleRect,
            score: score
        )
    }

    func recycle(_ platform: PlatformNode) {
        if let index = active.firstIndex(of: platform) {
            active.remove(at: index)
        }
        platform.removeAllActions()
        platform.removeFromParent()
        pool.append(platform)
    }

    func pickType(forScore score: Int) -> PlatformNode.PlatformType {
        let ramp = GameConfig.difficultyRamp(forScore: score)
        return pickWeightedType(
            ramp: ramp,
            allowSubway: true,
            preferEasy: false,
            preferHard: false
        )
    }

    func addPlatform(_ platform: PlatformNode) {
        if platform.parent == nil {
            scene.addChild(platform)
        }
        active.append(platform)
        highestPlatformY = max(highestPlatformY, platform.position.y)
    }

    private func recyclePlatforms(below minY: CGFloat) {
        var index = active.count - 1
        while index >= 0 {
            let platform = active[index]
            if platform.position.y < minY {
                platform.removeFromParent()
                pool.append(platform)
                active.remove(at: index)
            }
            index -= 1
        }
    }

    private func spawnPlatforms(upTo targetTop: CGFloat, visibleRect: CGRect, score: Int) {
        let padding = GameConfig.platformSize.width * 0.5 + GameConfig.spawnXPadding
        let minX = visibleRect.minX + padding
        let maxX = visibleRect.maxX - padding
        let ramp = GameConfig.difficultyRamp(forScore: score)
        let minGapBase = GameConfig.lerp(GameConfig.gapEasyMin, GameConfig.gapHardMin, ramp)
        let maxGapBaseRaw = GameConfig.lerp(GameConfig.gapEasyMax, GameConfig.gapHardMax, ramp)
        let maxGapBase = min(maxGapBaseRaw, GameConfig.maxGapAbsoluteCap)
        let maxVerticalGapCap = GameConfig.maxVerticalGapCap(existingCap: maxGapBase)
        let hardCap = GameConfig.platformCountTarget + 12

        var safetyIterations = 0
        while anchorY < targetTop || active.count < GameConfig.platformCountTarget {
            if pool.isEmpty && totalCreated >= hardCap {
                if let lowest = active.min(by: { $0.position.y < $1.position.y }) {
                    recycle(lowest)
                } else {
                    break
                }
            }
            safetyIterations += 1
            if safetyIterations > GameConfig.platformCountCap * 4 {
                break
            }

            maybeStartCluster(score: score, ramp: ramp)

            let gapBase: CGFloat
            if spawnedCountSinceReset < 6 {
                gapBase = CGFloat.random(in: 60...85)
            } else {
                let gapScale = gapScaleForState()
                let minGap = minGapBase * gapScale
                let maxGap = maxGapBase * gapScale
                gapBase = CGFloat.random(in: minGap...maxGap)
            }
            let clampedGap = min(gapBase, maxVerticalGapCap)
            let smoothedGap = smoothGap(clampedGap)
            anchorY += smoothedGap
            spawnLaneWidth = min(220, visibleRect.width * 0.32)
            if anchorX < minX + 80 { zigDir = 1 }
            if anchorX > maxX - 80 { zigDir = -1 }
            if CGFloat.random(in: 0...1) < 0.70 { zigDir *= -1 }
            let step = CGFloat.random(in: spawnLaneWidth * 0.55...spawnLaneWidth * 1.05)
            var targetX = anchorX + zigDir * step
            targetX += CGFloat.random(in: -40...40)
            let prevX = anchorX
            anchorX = min(max(targetX, minX), maxX)

            let currentMovingCount = active.filter { $0.type == .subway }.count
            let movingCap = movingCapFor(ramp: ramp)
            let allowSubway = currentMovingCount < movingCap
            let spineType: PlatformNode.PlatformType
            if spawnedCountSinceReset < 6 {
                spineType = Bool.random() ? .taxi : .cart
            } else {
                spineType = pickAnchorType(
                    ramp: ramp,
                    allowSubway: allowSubway,
                    preferEasy: easyRunRemaining > 0,
                    preferHard: hardRunRemaining > 0
                )
            }

            let platform: PlatformNode
            if let reused = pool.popLast() {
                platform = reused
            } else {
                platform = PlatformNode.make()
                totalCreated += 1
            }
            platform.configure(as: spineType)
            if platform.type == .subway {
                applySubwaySpeed(platform, ramp: ramp)
            }
            platform.position = CGPoint(x: anchorX, y: anchorY)
            addPlatform(platform)
            spawnedCountSinceReset += 1
            recordRecentType(spineType)

            if GameConfig.debugEnabled {
                let dx = abs(anchorX - prevX)
                let dxLimit = min(
                    GameConfig.spineDxLimitCap,
                    visibleRect.width * GameConfig.spineDxLimitWidthFactor
                )
                if clampedGap > maxVerticalGapCap || dx > dxLimit {
                    invalidSpawnCount += 1
                    print("SPAWN INVALID gap=\(clampedGap) cap=\(maxVerticalGapCap) dx=\(dx) dxLimit=\(dxLimit) score=\(score) count=\(invalidSpawnCount)")
                }
            }

            let extraChance = extraPlatformChance(ramp: ramp)
            if CGFloat.random(in: 0...1) < extraChance {
                let extraY = anchorY + CGFloat.random(in: -30...30)
                let extraX = CGFloat.random(in: minX...maxX)
                if abs(extraX - anchorX) < 90 && abs(extraY - anchorY) < 28 {
                    continue
                }
                if countPlatforms(nearY: extraY, window: 260) >= 6 {
                    continue
                }
                let extraType = pickTypeWithVariety(
                    ramp: ramp,
                    allowSubway: allowSubway,
                    preferEasy: easyRunRemaining > 0,
                    preferHard: hardRunRemaining > 0
                )

                let extra: PlatformNode
                if let reused = pool.popLast() {
                    extra = reused
                } else {
                    extra = PlatformNode.make()
                    totalCreated += 1
                }
                extra.configure(as: extraType)
                if extra.type == .subway {
                    applySubwaySpeed(extra, ramp: ramp)
                }
                extra.position = CGPoint(x: extraX, y: extraY)
                addPlatform(extra)
                recordRecentType(extraType)
            }

            advanceClusterState(score: score)
        }
    }

    private func pickAnchorType(
        ramp: CGFloat,
        allowSubway: Bool,
        preferEasy: Bool,
        preferHard: Bool
    ) -> PlatformNode.PlatformType {
        var attempts = 0
        while attempts < 6 {
            let candidate = pickWeightedType(
                ramp: ramp,
                allowSubway: allowSubway,
                preferEasy: preferEasy,
                preferHard: preferHard
            )
            if violatesHardRule(candidate) {
                attempts += 1
                continue
            }
            if violatesSoftRule(candidate) {
                attempts += 1
                continue
            }
            return candidate
        }
        return Bool.random() ? .taxi : .cart
    }

    private func countPlatforms(nearY y: CGFloat, window: CGFloat) -> Int {
        active.filter { abs($0.position.y - y) < window }.count
    }

    private func pickTypeWithVariety(
        ramp: CGFloat,
        allowSubway: Bool,
        preferEasy: Bool,
        preferHard: Bool
    ) -> PlatformNode.PlatformType {
        var attempts = 0
        while attempts < 6 {
            let candidate = pickWeightedType(
                ramp: ramp,
                allowSubway: allowSubway,
                preferEasy: preferEasy,
                preferHard: preferHard
            )
            if violatesHardRule(candidate) {
                attempts += 1
                continue
            }
            if violatesSoftRule(candidate) {
                attempts += 1
                continue
            }
            return candidate
        }
        return Bool.random() ? .taxi : .cart
    }

    private func violatesHardRule(_ candidate: PlatformNode.PlatformType) -> Bool {
        guard recentTypes.count >= 2 else { return false }
        let last = recentTypes[recentTypes.count - 1]
        let secondLast = recentTypes[recentTypes.count - 2]
        return last == candidate && secondLast == candidate
    }

    private func violatesSoftRule(_ candidate: PlatformNode.PlatformType) -> Bool {
        let count = recentTypes.filter { $0 == candidate }.count
        return count >= 3
    }

    private func recordRecentType(_ type: PlatformNode.PlatformType) {
        recentTypes.append(type)
        if recentTypes.count > recentTypesMax {
            recentTypes.removeFirst(recentTypes.count - recentTypesMax)
        }
    }

    private func updateMovingPlatforms(visibleRect: CGRect, dt: CGFloat) {
        let padding = GameConfig.platformSize.width * 0.5 + GameConfig.spawnXPadding
        let minX = visibleRect.minX + padding
        let maxX = visibleRect.maxX - padding

        for platform in active {
            guard platform.type == .subway else { continue }
            platform.position.x += platform.vx * dt
            if platform.position.x < minX {
                platform.position.x = minX
                platform.vx *= -1
            } else if platform.position.x > maxX {
                platform.position.x = maxX
                platform.vx *= -1
            }
        }
    }

    /// Continuous ramp-based weight interpolation — no discrete zone jumps.
    /// At ramp=0: mostly taxi/cart, no subway/pigeon.
    /// At ramp=1: dominated by subway/pigeon, few safe platforms.
    /// Subway fades in at ramp ~0.12 (score ~300), pigeon at ~0.16 (score ~400).
    private func pickWeightedType(
        ramp: CGFloat,
        allowSubway: Bool,
        preferEasy: Bool,
        preferHard: Bool
    ) -> PlatformNode.PlatformType {
        if preferEasy {
            return weightedPick([
                (.taxi, 60),
                (.cart, 40)
            ])
        }

        // Continuous interpolation from easy → hard
        let taxiW   = Int(round(GameConfig.lerp(55, 8, ramp)))
        let cartW   = Int(round(GameConfig.lerp(40, 8, ramp)))
        let manholeW = Int(round(GameConfig.lerp(5, 16, ramp)))

        // Subway fades in after ramp 0.12 (≈ score 300)
        let subwayW: Int
        if ramp > 0.12 {
            let subRamp = (ramp - 0.12) / 0.88  // normalize 0.12→1.0 into 0→1
            subwayW = Int(round(GameConfig.lerp(2, 42, subRamp)))
        } else {
            subwayW = 0
        }

        // Pigeon fades in after ramp 0.16 (≈ score 400)
        let pigeonW: Int
        if ramp > 0.16 {
            let pigRamp = (ramp - 0.16) / 0.84  // normalize 0.16→1.0 into 0→1
            pigeonW = Int(round(GameConfig.lerp(1, 28, pigRamp)))
        } else {
            pigeonW = 0
        }

        var weights: [(PlatformNode.PlatformType, Int)] = [
            (.taxi, taxiW),
            (.cart, cartW),
            (.subway, subwayW),
            (.pigeon, pigeonW),
            (.manhole, manholeW)
        ]

        if preferHard {
            weights = weights.map { type, w in
                switch type {
                case .subway, .pigeon:
                    return (type, w + 12)
                case .manhole:
                    return (type, w + 4)
                case .taxi, .cart:
                    return (type, max(1, w - 10))
                }
            }
        }

        // Filter disallowed types and zero-weights
        weights = weights.filter { type, w in
            if w <= 0 { return false }
            switch type {
            case .subway: return allowSubway
            case .pigeon: return true
            case .manhole: return true
            default: return true
            }
        }

        if weights.isEmpty {
            return .taxi
        }
        return weightedPick(weights)
    }

    private func weightedPick(_ weights: [(PlatformNode.PlatformType, Int)]) -> PlatformNode.PlatformType {
        let total = weights.reduce(0) { $0 + max(0, $1.1) }
        if total <= 0 {
            return weights.first?.0 ?? .taxi
        }
        var roll = Int.random(in: 1...total)
        for (type, w) in weights {
            let weight = max(0, w)
            roll -= weight
            if roll <= 0 {
                return type
            }
        }
        return weights.last?.0 ?? .taxi
    }

    /// Continuous moving platform cap — scales smoothly from low to high+1.
    private func movingCapFor(ramp: CGFloat) -> Int {
        let base = GameConfig.lerp(
            CGFloat(GameConfig.maxSimultaneousMovingPlatformsLow),
            CGFloat(GameConfig.maxSimultaneousMovingPlatformsHigh) + 1.0,
            ramp
        )
        return max(1, Int(round(base)))
    }

    /// Continuous extra platform chance — smoothly decreases with ramp.
    private func extraPlatformChance(ramp: CGFloat) -> CGFloat {
        GameConfig.lerp(GameConfig.extraPlatformChanceLow, GameConfig.extraPlatformChanceHigh, ramp)
    }

    private func gapScaleForState() -> CGFloat {
        if hardRunRemaining > 0 {
            return 1.15
        }
        if easyRunRemaining > 0 {
            return 0.88
        }
        return 1.0
    }

    private func smoothGap(_ raw: CGFloat) -> CGFloat {
        if lastGap == 0 {
            lastGap = raw
            return raw
        }
        let smoothed = GameConfig.lerp(lastGap, raw, 0.65)
        lastGap = smoothed
        return smoothed
    }

    /// Assigns ramp-scaled subway speed — smooth from base to late speed.
    private func applySubwaySpeed(_ platform: PlatformNode, ramp: CGFloat) {
        let minSpeed = GameConfig.lerp(GameConfig.subwaySpeedMin, GameConfig.subwaySpeedLateMin, ramp)
        let maxSpeed = GameConfig.lerp(GameConfig.subwaySpeedMax, GameConfig.subwaySpeedLateMax, ramp)
        let speed = CGFloat.random(in: minSpeed...maxSpeed)
        platform.vx = Bool.random() ? speed : -speed
    }

    /// Continuous cluster probability — scales smoothly with ramp.
    private func maybeStartCluster(score: Int, ramp: CGFloat) {
        if hardRunRemaining > 0 || easyRunRemaining > 0 {
            return
        }
        // No clusters below ramp 0.10 (≈ score 250)
        if ramp < 0.10 { return }

        let cooldown = Int(GameConfig.lerp(500, 150, ramp))
        if score - lastClusterScore < cooldown { return }

        let chance = GameConfig.lerp(0.06, 0.30, ramp)
        if CGFloat.random(in: 0...1) < chance {
            let minRun = max(2, Int(round(GameConfig.lerp(2, 4, ramp))))
            let maxRun = max(3, Int(round(GameConfig.lerp(3, 8, ramp))))
            hardRunRemaining = Int.random(in: minRun...maxRun)
        }
    }

    private func advanceClusterState(score: Int) {
        if hardRunRemaining > 0 {
            hardRunRemaining -= 1
            if hardRunRemaining == 0 {
                easyRunRemaining = Int.random(in: 1...2)
            }
            return
        }
        if easyRunRemaining > 0 {
            easyRunRemaining -= 1
            if easyRunRemaining == 0 {
                lastClusterScore = score
            }
        }
    }
}
