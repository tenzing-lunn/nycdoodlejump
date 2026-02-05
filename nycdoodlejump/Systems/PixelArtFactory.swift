import SpriteKit
import UIKit

enum PixelArtFactory {
    private static var playerCache: SKTexture?
    private static var coinCache: SKTexture?
    private static var noiseCache: SKTexture?
    private static var platformCache: [PlatformNode.PlatformType: SKTexture] = [:]

    static func playerTexture() -> SKTexture {
        if let cached = playerCache { return cached }
        let texture = makeTexture(size: CGSize(width: 16, height: 16)) { ctx, size in
            let body = CGRect(x: 3, y: 2, width: 10, height: 12)
            ctx.setFillColor(UIColor.white.cgColor)
            ctx.fill(body)

            ctx.setFillColor(UIColor(white: 0.0, alpha: 0.35).cgColor)
            ctx.fill(CGRect(x: 3, y: 2, width: 10, height: 2))
            ctx.fill(CGRect(x: 3, y: 12, width: 10, height: 2))

            ctx.setFillColor(UIColor(white: 0.0, alpha: 0.55).cgColor)
            ctx.fill(CGRect(x: 5, y: 9, width: 2, height: 2))
            ctx.fill(CGRect(x: 9, y: 9, width: 2, height: 2))
        }
        playerCache = texture
        return texture
    }

    static func coinTexture() -> SKTexture {
        if let cached = coinCache { return cached }
        let texture = makeTexture(size: CGSize(width: 10, height: 10)) { ctx, size in
            ctx.setFillColor(UIColor(red: 0.98, green: 0.84, blue: 0.28, alpha: 1.0).cgColor)
            ctx.fill(CGRect(x: 1, y: 1, width: 8, height: 8))
            ctx.setFillColor(UIColor(red: 0.88, green: 0.64, blue: 0.2, alpha: 1.0).cgColor)
            ctx.fill(CGRect(x: 1, y: 7, width: 8, height: 1))
            ctx.fill(CGRect(x: 1, y: 1, width: 8, height: 1))
        }
        coinCache = texture
        return texture
    }

    static func platformTexture(for type: PlatformNode.PlatformType) -> SKTexture {
        if let cached = platformCache[type] { return cached }
        let texture: SKTexture
        switch type {
        case .taxi:
            texture = makeTexture(size: CGSize(width: 20, height: 6)) { ctx, _ in
                ctx.setFillColor(UIColor(red: 0.96, green: 0.82, blue: 0.2, alpha: 1.0).cgColor)
                ctx.fill(CGRect(x: 0, y: 0, width: 20, height: 6))
                ctx.setFillColor(UIColor(white: 0.15, alpha: 0.9).cgColor)
                ctx.fill(CGRect(x: 2, y: 2, width: 4, height: 2))
                ctx.fill(CGRect(x: 14, y: 2, width: 4, height: 2))
            }
        case .cart:
            texture = makeTexture(size: CGSize(width: 20, height: 6)) { ctx, _ in
                ctx.setFillColor(UIColor(red: 0.9, green: 0.55, blue: 0.2, alpha: 1.0).cgColor)
                ctx.fill(CGRect(x: 0, y: 0, width: 20, height: 6))
                ctx.setFillColor(UIColor(white: 0.15, alpha: 0.7).cgColor)
                ctx.fill(CGRect(x: 1, y: 1, width: 18, height: 1))
            }
        case .subway:
            texture = makeTexture(size: CGSize(width: 20, height: 6)) { ctx, _ in
                ctx.setFillColor(UIColor(red: 0.65, green: 0.67, blue: 0.7, alpha: 1.0).cgColor)
                ctx.fill(CGRect(x: 0, y: 0, width: 20, height: 6))
                ctx.setFillColor(UIColor(white: 0.15, alpha: 0.8).cgColor)
                ctx.fill(CGRect(x: 2, y: 2, width: 6, height: 2))
                ctx.fill(CGRect(x: 12, y: 2, width: 6, height: 2))
            }
        case .pigeon:
            texture = makeTexture(size: CGSize(width: 20, height: 6)) { ctx, _ in
                ctx.setFillColor(UIColor(white: 0.85, alpha: 1.0).cgColor)
                ctx.fill(CGRect(x: 0, y: 0, width: 20, height: 6))
                ctx.setFillColor(UIColor(white: 0.6, alpha: 0.9).cgColor)
                ctx.fill(CGRect(x: 8, y: 2, width: 4, height: 2))
            }
        case .manhole:
            texture = makeTexture(size: CGSize(width: 26, height: 8)) { ctx, _ in
                ctx.setFillColor(UIColor(white: 0.16, alpha: 1.0).cgColor)
                ctx.fill(CGRect(x: 0, y: 0, width: 26, height: 8))
                ctx.setFillColor(UIColor(white: 0.32, alpha: 1.0).cgColor)
                ctx.fill(CGRect(x: 4, y: 3, width: 18, height: 2))
            }
        }
        platformCache[type] = texture
        return texture
    }

    static func noiseTexture() -> SKTexture {
        if let cached = noiseCache { return cached }
        let texture = makeTexture(size: CGSize(width: 64, height: 64)) { ctx, size in
            for y in 0..<Int(size.height) {
                for x in 0..<Int(size.width) {
                    let alpha = CGFloat.random(in: 0.05...0.25)
                    ctx.setFillColor(UIColor(white: 1.0, alpha: alpha).cgColor)
                    ctx.fill(CGRect(x: x, y: y, width: 1, height: 1))
                }
            }
        }
        noiseCache = texture
        return texture
    }

    private static func makeTexture(size: CGSize, draw: (CGContext, CGSize) -> Void) -> SKTexture {
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        format.opaque = false
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        let image = renderer.image { ctx in
            draw(ctx.cgContext, size)
        }
        let texture = SKTexture(image: image)
        texture.filteringMode = .nearest
        return texture
    }
}
