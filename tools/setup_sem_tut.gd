extends RefCounted
func preparar(arvore: SceneTree) -> void:
	Jogo.novo(Game.lanistas()[3]["id"], "medio")
	Jogo.e["ouro"] = 5000
	for m in Game.MELHORIAS_LUDUS:
		Jogo.e["melhorias"][m["id"]] = true
	Jogo.e["tutorial"] = {"vistos": ["tour", "campanha", "treino", "armeiro", "enfermaria", "alojamentos", "refeitorio"]}
	Jogo.navegar.emit("jogo")
	await arvore.process_frame
	await arvore.process_frame
	Jogo.abrir_aba.emit(OS.get_environment("ABA") if OS.get_environment("ABA") != "" else "ludus")
