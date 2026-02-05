import Foundation
import CoreGraphics

struct GameConfig {
    static let gravity: CGFloat = -1800
    static let targetFPS: Double = 60
    static var debugEnabled: Bool = false
    static var showHitboxes: Bool = false
    static let debugFontName: String = "Menlo"
    static let debugFontSize: CGFloat = 12
    static let dtMax: CGFloat = 1.0 / 30.0
    static let maxFallSpeed: CGFloat = 1400
    static let landingTolerance: CGFloat = 4
    static let horizontalLandingSlack: CGFloat = 1
    static let playerSize = CGSize(width: 34, height: 34)
    static let playerMoveAccel: CGFloat = 2600
    static let playerMaxSpeed: CGFloat = 420
    static let playerFriction: CGFloat = 2200
    static let playerAccelMaxDelta: CGFloat = 60
    static let wrapMargin: CGFloat = 20
    static let jumpVelocity: CGFloat = 820
    static let springJumpVelocity: CGFloat = 1100
    static let platformSize = CGSize(width: 78, height: 16)
    static let manholeSize = CGSize(width: 120, height: 24)
    static let platformCountTarget: Int = 24
    static let platformCountCap: Int = 34
    static let spawnAhead: CGFloat = 900
    static let recycleBelow: CGFloat = 260
    static let minPlatformGapLow: CGFloat = 90
    static let maxPlatformGapLow: CGFloat = 145
    static let minPlatformGapHigh: CGFloat = 115
    static let maxPlatformGapHigh: CGFloat = 175
    static let maxPlatformGapCap: CGFloat = 180
    static let subwaySpeedMin: CGFloat = 60
    static let subwaySpeedMax: CGFloat = 100
    static let subwaySpeedLateMin: CGFloat = 90
    static let subwaySpeedLateMax: CGFloat = 150
    static let difficultyRampStartScore: Int = 0
    static let difficultyRampEndScore: Int = 2500
    static let gapEasyMin: CGFloat = 60
    static let gapEasyMax: CGFloat = 95
    static let gapHardMin: CGFloat = 130
    static let gapHardMax: CGFloat = 185
    static let maxGapAbsoluteCap: CGFloat = 185
    static let spawnXPadding: CGFloat = 18
    static let scoreLineSpacing: CGFloat = 90
    static let bounceSquashX: CGFloat = 1.06
    static let bounceSquashY: CGFloat = 0.92
    static let coinRadius: CGFloat = 8
    static let coinCountTarget: Int = 14
    static let coinCountCap: Int = 22
    static let coinSpawnXOffset: CGFloat = 40
    static let coinSpawnYMin: CGFloat = 35
    static let coinSpawnYMax: CGFloat = 85
    static let coinRecycleBelow: CGFloat = 140
    static let streakWindow: TimeInterval = 0.75
    static let streakMax: Int = 10
    static let streakMultiplierStep: CGFloat = 0.1
    static let dangerLineStartScore: Int = 300
    static let dangerLineBaseSpeed: CGFloat = 55
    static let dangerLineSpeedupStartScore: Int = 800
    static let dangerLineSpeedupEndScore: Int = 2500
    static let dangerLineMaxMultiplier: CGFloat = 2.8
    static let extraPlatformChanceLow: CGFloat = 0.50
    static let extraPlatformChanceHigh: CGFloat = 0.08
    static let maxSimultaneousMovingPlatformsLow: Int = 1
    static let maxSimultaneousMovingPlatformsHigh: Int = 5
    static let spineDxLimitCap: CGFloat = 160
    static let spineDxLimitWidthFactor: CGFloat = 0.28

    enum DifficultyZone {
        case intro
        case early
        case mid
        case late
    }

    static func difficultyZone(forScore score: Int) -> DifficultyZone {
        if score < 400 {
            return .intro
        } else if score < 1000 {
            return .early
        } else if score < 2000 {
            return .mid
        } else {
            return .late
        }
    }

    static func timeToApex() -> CGFloat {
        jumpVelocity / abs(gravity)
    }

    static func maxApexHeight() -> CGFloat {
        (jumpVelocity * jumpVelocity) / (2 * abs(gravity))
    }

    static func maxVerticalGapCap(existingCap: CGFloat) -> CGFloat {
        min(existingCap, maxApexHeight() * 0.78)
    }

    static func descendingTime(forGap gap: CGFloat) -> CGFloat {
        let g = abs(gravity)
        let v = jumpVelocity
        let discriminant = max(0, v * v - 2 * g * gap)
        return (v + sqrt(discriminant)) / g
    }

    static func maxReachableDX(forGap gap: CGFloat) -> CGFloat {
        let t = descendingTime(forGap: gap)
        return playerMaxSpeed * t * 0.85
    }

    static func ramp(score: Int) -> CGFloat {
        let s = CGFloat(score - difficultyRampStartScore)
        let d = CGFloat(max(1, difficultyRampEndScore - difficultyRampStartScore))
        return min(1, max(0, s / d))
    }

    static func difficultyRamp(forScore score: Int) -> CGFloat {
        smoothstep(ramp(score: score))
    }

    static func smoothstep(_ t: CGFloat) -> CGFloat {
        let clamped = min(1, max(0, t))
        return clamped * clamped * (3 - 2 * clamped)
    }

    static func lerp(_ a: CGFloat, _ b: CGFloat, _ t: CGFloat) -> CGFloat {
        a + (b - a) * t
    }

    static func clamp(_ value: CGFloat, _ minValue: CGFloat, _ maxValue: CGFloat) -> CGFloat {
        min(maxValue, max(minValue, value))
    }
}
