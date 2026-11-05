extends RefCounted
## Campanha com tutorial dispensado, para checar o palco dos lanistas.
func preparar(arvore: SceneTree) -> void:
	Jogo.novo(Game.lanistas()[3]["id"], "medio")
	Jogo.e["tutorial"] = {"vistos": ["tour", "campanha", "treino", "armeiro", "enfermaria", "alojamentos", "refeitorio"]}
	Jogo.e["campanha"] = 2
	Jogo.navegar.emit("jogo")
	await arvore.process_frame
	await arvore.process_frame
	Jogo.abrir_aba.emit("campanha")
	for i in 10:
		await arvore.process_frame
