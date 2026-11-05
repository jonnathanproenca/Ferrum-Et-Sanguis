extends RefCounted
func preparar(arvore: SceneTree) -> void:
	Jogo.prefs["ludusNovo"] = true
	Jogo.navegar.emit("menu")
	for i in range(30): await arvore.process_frame
	Jogo.novo(Game.lanistas()[3]["id"], "medio")
	Jogo.e["ouro"] = 9000
	for m in Game.MELHORIAS_LUDUS:
		Jogo.e["melhorias"][m["id"]] = true
	Jogo.e["tutorial"] = {"vistos": ["tour", "campanha", "treino", "armeiro", "enfermaria", "alojamentos", "refeitorio"]}
	Jogo.navegar.emit("jogo")
	for i in range(30): await arvore.process_frame
	for aba in ["ludus", "upgrades", "mercado", "armeiro", "enfermaria", "arenas", "campanha", "config", "ludus", "mercado", "ludus"]:
		Jogo.abrir_aba.emit(aba)
		for i in range(60): await arvore.process_frame
	Jogo.navegar.emit("menu")
	for i in range(30): await arvore.process_frame
