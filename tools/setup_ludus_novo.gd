extends RefCounted
## Ludus novo: dificuldade Fácil (1 campeão), sem construções.
func preparar(arvore: SceneTree) -> void:
	Jogo.novo(Game.lanistas()[3]["id"], "facil")
	Jogo.navegar.emit("jogo")
	await arvore.process_frame
	await arvore.process_frame
	Jogo.abrir_aba.emit("ludus")
