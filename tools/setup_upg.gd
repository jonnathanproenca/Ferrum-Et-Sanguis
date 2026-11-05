extends RefCounted
func preparar(arvore: SceneTree) -> void:
	Jogo.novo(Game.lanistas()[3]["id"], "medio")
	var modo := OS.get_environment("MODO")
	Jogo.e["ouro"] = 5000 if modo.contains("rico") or modo.contains("tudo") else 250
	if modo.contains("tudo"):
		for m in Game.MELHORIAS_LUDUS:
			Jogo.e["melhorias"][m["id"]] = true
	if modo.contains("enf"):
		Jogo.e["melhorias"]["enfermaria"] = true
	if modo.contains("feridos"):
		var gs: Array = Jogo.e["gladiadores"]
		if gs.size() < 2:
			var d: Dictionary = gs[0].duplicate(true)
			d["id"] = "teste-2"
			d["nome"] = "Marcus Ferox"
			gs.append(d)
		gs[0]["efeitos"] = [{"tipo": "sangramento", "severidade": 2}]
		gs[1]["efeitos"] = [{"tipo": "queimadura", "severidade": 1}, {"tipo": "contusao", "severidade": 3}]
	Jogo.navegar.emit("jogo")
	await arvore.process_frame
	await arvore.process_frame
	Jogo.abrir_aba.emit(OS.get_environment("ABA"))
