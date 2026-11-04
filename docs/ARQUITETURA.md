# Arquitetura (Godot 4.4, GDScript)

Porte do jogo de gestão do [Redux](https://github.com/jonnathanproenca/Ferrum-et-sanguis-Redux) (TypeScript + DOM). O código-fonte de referência
está em `/home/claude/ferrum-et-sanguis` (src/ui/ui.ts, src/art/*.ts, index.html para o CSS).

## Regras (já portadas e testadas, NÃO mude comportamento)
- `scripts/core/`: `Rng`, `Combat`, `Model`, `Game`, `Util`. O estado da partida é um `Dictionary` (mesma estrutura do JSON do jogo em TS).
- Ações: `Game.xxx(Jogo.e, ...)` devolvem `String` de erro ("" = ok). Use `Jogo.resultado(erro)`: mostra o aviso ou salva + emite `Jogo.mudou`.
- `Game.lutar_arena` / `Game.lutar_campanha` devolvem um `Dictionary` com `"erro"` ou o payload da luta.
- Testes de paridade: `godot --headless --path . -s tests/executar.gd` (devem continuar com 0 falhas).

## Autoloads
- `Jogo` (scripts/jogo.gd): `e` (estado), `prefs`, `novo()`, `continuar()`, `salvar()`, sinais `mudou`, `aviso`, `navegar`, `abrir_aba`, `iniciar_luta`, `tutorial_pedido`.
- `Som` (scripts/som.gd): `musica(chave)`, `sfx("sfx/moeda")`, `voz("medico")`.

## UI (scripts/ui/)
- `Tema` (cores, fontes Cinzel/EB Garamond, fábricas `botao`, `rotulo`, `titulo`, `painel`, `vbox`, `hbox`, `textura`), `Sprites` (poses, escravos, variantes de cor), `Anim` (animações em folha de sprites: medico, engenheiro, mercador, ferreiro, brasa).
- Cada aba é um `Tela` (`construir()` uma vez, `atualizar()` a cada `Jogo.mudou`, `ao_mostrar()`), arquivo `tela_<aba>.gd`, instanciada pelo `Hud`.
- Telas fora do HUD: `TelaMenu`, `TelaSelecao` (via `Jogo.navegar`).

## Ferramentas
- `tools/captura.sh <setup.gd|-> <saida.png> [frames]`: screenshot headless (xvfb + llvmpipe). Exemplo de setup: `tools/setup_jogo.gd` (variável `ABA`).
- `tools/converter_webp.py`: WebP animado → folha de sprites.
