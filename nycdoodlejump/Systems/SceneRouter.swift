import SpriteKit

final class SceneRouter {
    static let shared = SceneRouter()

    var cachedGameScene: GameScene?
    var cachedScaleMode: SKSceneScaleMode = .resizeFill

    private init() {}
}
