extends RefCounted
## Mostra a modal de oferta de patrocínio sobre o ludus.
func preparar(arvore: SceneTree) -> void:
	Jogo.prefs["ludusNovo"] = true
	Jogo.novo(Game.lanistas()[3]["id"], "medio")
	var e: Dictionary = Jogo.e
	e["tutorial"] = {"vistos": ["tour", "campanha", "treino", "armeiro", "enfermaria", "alojamentos", "refeitorio"]}
	e["campanha"] = 3
	var g: Dictionary = e["gladiadores"][0]
	var rng := Rng.new(5)
	for i in 400:
		if not Patrocinio.tentar_oferta(e, g, 200, rng).is_empty():
			break
	Jogo.navegar.emit("jogo")
	await arvore.process_frame
	await arvore.process_frame
	Jogo.abrir_aba.emit("ludus")
	for _i in 8:
		await arvore.process_frame
