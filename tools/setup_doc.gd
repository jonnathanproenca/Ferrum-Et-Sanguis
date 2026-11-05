extends RefCounted
func preparar(arvore: SceneTree) -> void:
	Jogo.prefs["ludusNovo"] = true
	Jogo.novo(Game.lanistas()[3]["id"], "medio")
	Jogo.e["tutorial"] = {"vistos": ["tour", "campanha", "treino", "armeiro", "enfermaria", "alojamentos", "refeitorio"]}
	Jogo.navegar.emit("jogo")
	await arvore.process_frame
	await arvore.process_frame
	Jogo.abrir_aba.emit("ludus")
