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

## 6. Cronograma de 5 Semanas (4h / semana)

### Semana 1: O Coração do Jogo (Movimento e Núcleo)
*   **Hora 1-2:** Configurar `CoreMotion` e garantir que o drone se move sem "lag".
*   **Hora 3-4:** Criar o Núcleo central e o sistema básico de vida. Limitar o drone às bordas do ecrã.

### Semana 2: Rondas e Inimigos
*   **Hora 1-2:** Criar o sistema de Rondas (ex: Array que dita o spawn).
*   **Hora 3-4:** Lógica de movimento do inimigo em direção ao Núcleo e colisão que retira vida ao Núcleo.

### Semana 3: Combate e Drop de Torres
*   **Hora 1-2:** Drone dispara lasers automaticamente. Inimigo morre ao ser atingido.
*   **Hora 3-4:** Inimigo específico larga item de "Torre". Jogador apanha o item e muda o estado para `isCarryingTower = true`.

### Semana 4: Implementação e Habilidades
*   **Hora 1-2:** Lógica de tocar no ecrã para largar a torre. A torre dispara para o inimigo mais próximo.
*   **Hora 3-4:** Implementar a chance de 0.01% da **VX-Null Bomb** e a sua funcionalidade básica (remover todos os nós "enemy").

### Semana 5: Morte, UI e Ajustes Final
*   **Hora 1-2:** Lógica de colisão Drone-Inimigo: Explosão, espera de 3 segundos e respawn.
*   **Hora 3-4:** UI básica (Texto da Ronda, Barra de Vida do Núcleo) e ecrã de Game Over. Testes finais em dispositivo físico.
