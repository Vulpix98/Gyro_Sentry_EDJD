# Gyro Sentry EDJD

## 1. Conceito do Jogo
**Gyro Sentry** é um jogo de "Action Tower Defense" minimalista para iOS. Ao contrário dos TD tradicionais onde não controlas nenhuma personagem, apenas colocas torres, aqui o jogador controla um drone de defesa através do **giroscópio** do telemóvel. O objetivo é proteger um Núcleo central de rondas de inimigos pré-definidas. A grande diferença é que o jogador obtém recursos (torres e habilidades) diretamente dos inimigos abatidos, tornando o combate mais arriscado e recompensador.

*   **Plataforma:** iOS (iPhone).
*   **Tecnologia:** Swift + SpriteKit + CoreMotion.
*   **Estética:** Estilo Neon/Retro (formas geométricas simples, cores vibrantes sobre fundo escuro).

---

## 2. Ciclo de Jogo (Gameplay Loop)
1. **Navegar:** O jogador inclina o telemóvel para navegar pelo campo de batalha enquanto carrega a torre.
2.  **Combate e Recolha:** O drone do jogador possui um laser básico no qual dispara automaticamente na direção do inimigo mais próximo. Quando inimigos específicos morrem, deixam cair um item, exemplo uma "Tower XPTO". O jogador deve passar por cima para o recolher.
3.  **Implementação:** Com a torre recolhida, o jogador toca no ecrã para a posicionar. A torre ativa-se automaticamente e ataca os inimigos próximos.
4.  **Manutenção:** As torres têm energia limitada. Quando terminar a energia a torre se autodestrói.
5.  **Risco de Colisão:** Se o drone chocar com um inimigo, ambos explodem. O jogador fica fora de combate por 3 segundos antes de reaparecer no Núcleo.
6.  **Rondas:** O jogador deve sobreviver a rondas pré-definidas (ex: Ronda 1: 10 inimigos, Ronda 2: 20 inimigos + 1 portador de torre).
7.  **Sorte Rara:** Chance ínfima (0.01%) de obter a bomba "VX-Null" para limpar o ecrã.

---

## 3. Abordagem Técnica
*   **Movimento:** Uso do `CMMotionManager` (CoreMotion) para detetar a aceleração `x` e `y`. Aplicação desses valores na posição do `SKSpriteNode` do jogador no método `update()`.
*   **Inimigos:** Spawn aleatório nas bordas do ecrã com `SKAction.move(to: corePosition, duration: speed)`.
*   **Torres:** Classe customizada que herda de `SKSpriteNode`, contendo um timer para expiração e lógica de deteção de inimigos (distância euclidiana).
*   **Sistema de Drops:** Inimigos com uma flag `dropsTower = true`. Ao morrerem, criam um `SKSpriteNode` de item no local da morte.
*   **Deteção de Proximidade:** O drone recolhe o item através de colisão simples (`physicsBody`).
*   **Estado de Morte:** Quando o jogador colide, o nó do jogador é escondido (`isHidden = true`) e um `Timer` de 3 segundos é disparado antes de o reativar.
*   **Rondas:** Um ficheiro ou Array de structs que define quantos inimigos de cada tipo aparecem em cada vaga.

---

## 4. Âmbito MVP (Minimum Viable Product)
*   [ ] Movimento fluido por giroscópio.
*   [ ] Sistema de spawn de inimigos básicos em direção ao centro.
*   [ ] Mecânica de "Pegar e Largar" uma torre básica.
*   [ ] Lógica de disparo automático para o inimigo mais próximo.
*   [ ] Condição de derrota (Vida do Núcleo = 0).

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
