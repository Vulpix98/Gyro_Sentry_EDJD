# Gyro Sentry EDJD

## 1. Conceito do Jogo
**Sentinela Gyro** é um jogo de "Action Tower Defense" minimalista para iOS. Ao contrário dos TD tradicionais onde o jogador é estático, aqui o jogador controla um drone de defesa através do **giroscópio** do telemóvel. O objetivo é proteger um "Núcleo de Dados" central de ondas de vírus geométricos, transportando torres de defesa para posições estratégicas.

*   **Plataforma:** iOS (iPhone).
*   **Tecnologia:** Swift + SpriteKit + CoreMotion.
*   **Estética:** Estilo Neon/Retro (formas geométricas simples, cores vibrantes sobre fundo escuro).

---

## 2. Ciclo de Jogo (Gameplay Loop)
1.  **Recolha:** O jogador move o drone (giroscópio) até ao Núcleo central para "pegar" numa torre disponível.
2.  **Posicionamento:** O jogador inclina o telemóvel para navegar pelo campo de batalha enquanto carrega a torre.
3.  **Implementação:** Tocar no ecrã para largar a torre. A torre ativa-se automaticamente e ataca os inimigos próximos.
4.  **Combate Ativo:** O drone do jogador possui um laser básico automático para ajudar na defesa enquanto se move.
5.  **Manutenção:** As torres têm energia limitada. Quando desaparecem, o jogador deve voltar ao centro para colocar uma nova.
6.  **Progressão:** Sobreviver a vagas (waves) sucessivas de inimigos cada vez mais fortes.

---

## 3. Abordagem Técnica
*   **Movimento:** Uso do `CMMotionManager` (CoreMotion) para detetar a aceleração `x` e `y`. Aplicação desses valores na posição do `SKSpriteNode` do jogador no método `update()`.
*   **Inimigos:** Spawn aleatório nas bordas do ecrã com `SKAction.move(to: corePosition, duration: speed)`.
*   **Torres:** Classe customizada que herda de `SKSpriteNode`, contendo um timer para expiração e lógica de deteção de inimigos (distância euclidiana).
*   **Colisões:** `SKPhysicsContactDelegate` para gerir o impacto de projéteis nos inimigos e de inimigos no núcleo.
*   **Estado do Jogo:** Máquina de estados simples (`MainMenu`, `Playing`, `GameOver`).

---

## 4. Âmbito MVP (Minimum Viable Product)
*   [ ] Movimento do jogador via inclinação do dispositivo (Giroscópio).
*   [ ] Sistema de spawn de inimigos básicos em direção ao centro.
*   [ ] Mecânica de "Pegar e Largar" uma torre básica.
*   [ ] Lógica de disparo automático da torre para o inimigo mais próximo.
*   [ ] Barra de vida do Núcleo e ecrã de Game Over.

---

## 5. Ideias Futuras (Stretch Goals)
*   **Sumidouro de Energia:** Inimigos deixam "bits" (moedas) que o jogador tem de recolher para comprar torres melhores.
*   **Variação de Torres:** Torre de Gelo (abranda inimigos) e Torre de Área (dano de explosão).
*   **Sumo Visual:** Adição de `SKEmitterNode` para explosões de partículas e rasto no drone do jogador.
*   **Haptics:** Feedback vibratório ao sofrer dano ou destruir inimigos grandes.
*   **Calibração:** Opção no menu para definir a posição "zero" do giroscópio.

---

## 6. Cronograma Previsto (3 Semanas)

### Semana 1: Estrutura Base e Movimento
*   Configuração do projeto e `CoreMotion`.
*   Implementação do movimento do drone e limites do ecrã.
*   Criação do Núcleo central e lógica de spawn de inimigos.

### Semana 2: Mecânicas de Combate
*   Sistema de "Carry & Drop" (agarrar torre no centro e largar no mapa).
*   Lógica de tiro das torres (procura de alvo e spawn de projéteis).
*   Deteção de colisões e destruição de inimigos.

### Semana 3: Interface e Polimento
*   Criação do HUD (Vida, Vaga atual, Indicador de torre).
*   Menu Principal e Ecrã de derrota.
*   Ajuste de dificuldade (balancing) e correção de bugs.
