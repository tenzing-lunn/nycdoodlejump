//
//  GameViewController.swift
//  nycdoodlejump
//
//  Created by Tenzing Lunn on 1/17/26.
//

import UIKit
import SpriteKit
import GameplayKit

class GameViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let view = self.view as! SKView? {
            // Load the SKScene from 'GameScene.sks'
            if let scene = SKScene(fileNamed: "GameScene") {
                // Set the scale mode to scale to fit the window
                scene.scaleMode = .aspectFill
                
                // Present the scene
                view.presentScene(scene)
            }
            
            view.ignoresSiblingOrder = true
            
            view.showsFPS = true
            view.showsNodeCount = true
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        becomeFirstResponder()
    }

    override var canBecomeFirstResponder: Bool {
        true
    }

    override var keyCommands: [UIKeyCommand]? {
        [
            UIKeyCommand(input: UIKeyCommand.inputLeftArrow, modifierFlags: [], action: #selector(handleKeyCommand(_:))),
            UIKeyCommand(input: UIKeyCommand.inputRightArrow, modifierFlags: [], action: #selector(handleKeyCommand(_:))),
            UIKeyCommand(input: "a", modifierFlags: [], action: #selector(handleKeyCommand(_:))),
            UIKeyCommand(input: "d", modifierFlags: [], action: #selector(handleKeyCommand(_:)))
        ]
    }

    override func pressesEnded(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        super.pressesEnded(presses, with: event)
        guard let skView = view as? SKView,
              let scene = skView.scene as? GameScene else { return }
        for press in presses {
            guard let key = press.key else { continue }
            switch key.keyCode {
            case .keyboardLeftArrow, .keyboardA:
                scene.setMoveLeft(false)
            case .keyboardRightArrow, .keyboardD:
                scene.setMoveRight(false)
            default:
                break
            }
        }
    }

    @objc private func handleKeyCommand(_ command: UIKeyCommand) {
        guard let skView = view as? SKView,
              let scene = skView.scene as? GameScene else { return }

        switch command.input {
        case UIKeyCommand.inputLeftArrow, "a", "A":
            scene.setMoveLeft(true)
        case UIKeyCommand.inputRightArrow, "d", "D":
            scene.setMoveRight(true)
        default:
            break
        }
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return .allButUpsideDown
        } else {
            return .all
        }
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
}
