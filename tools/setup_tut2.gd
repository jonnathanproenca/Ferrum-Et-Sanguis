extends RefCounted
func preparar(arvore: SceneTree) -> void:
	Jogo.prefs["ludusNovo"] = OS.get_environment("NOVO") != "0"
	Jogo.novo(Game.lanistas()[3]["id"], "medio")
	Jogo.navegar.emit("jogo")
	for i in range(120): await arvore.process_frame
