extends RefCounted
func preparar(arvore: SceneTree) -> void:
	Jogo.novo(Game.lanistas()[3]["id"], "medio")
	Jogo.e["gladiadores"] = []
	Jogo.e["ouro"] = 0
	Jogo.navegar.emit("jogo")
	await arvore.process_frame
	await arvore.process_frame
	Jogo.abrir_aba.emit("ludus")
	Jogo.mudou.emit()
