import SpriteKit

class MainMenuScene: SKScene {
    
    // Propriedade para referenciar o botão de Play
    private var playButton: SKNode?
    
    override func didMove(to view: SKView) {
            self.backgroundColor = .black // Garante que não é um preto "vazio"
            
            // Tenta encontrar o botão do ficheiro .sks
            playButton = self.childNode(withName: "//playButton")
            
            // SE NÃO ENCONTRAR (Plano B via Código), vamos criar um texto simples:
            if playButton == nil {
                let label = SKLabelNode(fontNamed: "Menlo-Bold")
                label.text = "START GAME"
                label.name = "playButton" // Importante para o touchesBegan reconhecer
                label.fontSize = 40
                label.fontColor = .cyan
                label.position = CGPoint(x: frame.midX, y: frame.midY)
                addChild(label)
                playButton = label
                print("Aviso: playButton criado via código pois não foi encontrado no .sks")
            }
        }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
            guard let touch = touches.first else { return }
            let location = touch.location(in: self)
            let nodesAtPoint = self.nodes(at: location)
            
            for node in nodesAtPoint {
                if node == playButton || node.name == "playButton" {
                    loadGameScene()
                    return
                }
            }
        }
    
    private func loadGameScene() {
            // Se o teu jogo é feito via código:
            let gameScene = GameScene(size: self.size)
            gameScene.scaleMode = .aspectFill
            
            let transition = SKTransition.fade(withDuration: 1.0)
            self.view?.presentScene(gameScene, transition: transition)
        }
}
