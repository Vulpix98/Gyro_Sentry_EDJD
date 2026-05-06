//
//  GameViewController.swift
//  Gryo_Sentry
//
//  Created by Aluno Tmp on 22/04/2026.
//

import UIKit
import SpriteKit
import GameplayKit

class GameViewController: UIViewController {

    override var canBecomeFirstResponder: Bool { true }

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

        becomeFirstResponder()
    }

    override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        super.pressesBegan(presses, with: event)
        routeKeyboardPresses(presses, isDown: true)
    }

    override func pressesEnded(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        super.pressesEnded(presses, with: event)
        routeKeyboardPresses(presses, isDown: false)
    }

    private func routeKeyboardPresses(_ presses: Set<UIPress>, isDown: Bool) {
        guard
            let view = self.view as? SKView,
            let scene = view.scene as? GameScene
        else { return }

        for press in presses {
            switch press.type {
            case .leftArrow: scene.setArrowKey(.left, isDown: isDown)
            case .rightArrow: scene.setArrowKey(.right, isDown: isDown)
            case .upArrow: scene.setArrowKey(.up, isDown: isDown)
            case .downArrow: scene.setArrowKey(.down, isDown: isDown)
            default: break
            }

            // WASD (hardware keyboard)
            if let key = press.key?.charactersIgnoringModifiers.lowercased() {
                switch key {
                case "w": scene.setArrowKey(.up, isDown: isDown)
                case "a": scene.setArrowKey(.left, isDown: isDown)
                case "s": scene.setArrowKey(.down, isDown: isDown)
                case "d": scene.setArrowKey(.right, isDown: isDown)
                case "t":
                    if isDown { scene.debugDamageCore() }
                case "y":
                    if isDown { scene.debugHealCore() }
                case "u":
                    if isDown { scene.placeTowerIfCarrying() }
                default: break
                }
            }
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
