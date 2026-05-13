import SpriteKit

class MainMenuScene: SKScene {
    
    // Propriedade para referenciar o botão de Play
    private var playButton: SKNode?
    
    override func didMove(to view: SKView) {
        // O "//" ajuda a encontrar o nó mesmo que ele esteja dentro de outros grupos
        playButton = self.childNode(withName: "//playButton")
        
        // Dica: Podes mudar a cor de fundo do menu aqui se quiseres testar visualmente
        self.backgroundColor = .black
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        
        // 1. Removido o cast desnecessário (resolve o warning)
        // 2. Simplificada a verificação do nó tocado
        let tappedNode = self.atPoint(location)
        
        if tappedNode == playButton || tappedNode.name == "playButton" {
            loadGameScene()
        }
    }
    
    private func loadGameScene() {
        // Carrega a cena principal onde estão os teus inimigos e o drone
        if let gameScene = SKScene(fileNamed: "GameScene") {
            gameScene.scaleMode = .aspectFill
            
            // Transição de 1 segundo para não ser um corte abrupto
            let transition = SKTransition.fade(withDuration: 1.0)
            
            self.view?.presentScene(gameScene, transition: transition)
        }
    }
}
