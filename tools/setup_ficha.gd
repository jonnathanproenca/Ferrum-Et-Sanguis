extends RefCounted
func preparar(arvore: SceneTree) -> void:
	Jogo.novo(Game.lanistas()[3]["id"], "medio")
	Jogo.e["ouro"] = 5000
	var palus := OS.get_environment("PALUS") != "0"
	for m in Game.MELHORIAS_LUDUS:
		Jogo.e["melhorias"][m["id"]] = palus or m["id"] != "palus"
	Jogo.e["tutorial"] = {"vistos": ["tour", "campanha", "treino", "armeiro", "enfermaria", "alojamentos", "refeitorio"]}
	if Jogo.e["gladiadores"].size() > 0:
		Jogo.e["gladiadores"][0]["gloria"] = 140
		Jogo.e["gladiadores"][0]["treino"]["forca"] = 10
	Jogo.navegar.emit("jogo")
	await arvore.process_frame
	await arvore.process_frame
	Jogo.abrir_aba.emit(OS.get_environment("ABA") if OS.get_environment("ABA") != "" else "ludus")
	var rol := int(OS.get_environment("ROL")) if OS.get_environment("ROL") != "" else 0
	if rol > 0:
		for _i in 10:
			await arvore.process_frame
		for sc in arvore.root.find_children("*", "ScrollContainer", true, false):
			if sc.is_visible_in_tree():
				sc.scroll_vertical = rol
				break
