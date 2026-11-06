extends RefCounted
## Ficha do gladiador com patrono ativo.
func preparar(arvore: SceneTree) -> void:
	Jogo.prefs["ludusNovo"] = true
	Jogo.novo(Game.lanistas()[3]["id"], "medio")
	var e: Dictionary = Jogo.e
	e["tutorial"] = {"vistos": ["tour", "campanha", "treino", "armeiro", "enfermaria", "alojamentos", "refeitorio"]}
	e["campanha"] = 8
	var g: Dictionary = e["gladiadores"][0]
	var rng := Rng.new(5)
	for i in 400:
		if not Patrocinio.tentar_oferta(e, g, 200, rng).is_empty():
			break
	Game.aceitar_patrocinio(e, Patrocinio.ofertas(e)[0]["id"])
	Jogo.navegar.emit("jogo")
	await arvore.process_frame
	await arvore.process_frame
	Jogo.abrir_aba.emit("ludus")
	for _i in 8:
		await arvore.process_frame
	ModalGladiador.abrir(arvore.root.get_child(arvore.root.get_child_count() - 1), str(g["id"]))
	for _i in 8:
		await arvore.process_frame
