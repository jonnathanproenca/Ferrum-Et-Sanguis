extends RefCounted
func preparar(arvore: SceneTree) -> void:
	Jogo.novo(Game.lanistas()[3]["id"], "medio")
	Jogo.e["ouro"] = 1000
	for m in Game.MELHORIAS_LUDUS:
		Jogo.e["melhorias"][m["id"]] = true
	Jogo.e["cheats"] = {"lendario": true}
	Game.gerar_armeiro_mestre(Jogo.e)
	for id in ["gladio_largo", "gladio_largo", "tridente", "peito_leve", "escudo_oval@2", "elmo_murmilo@3", "basico_arma_murmilo", "sandalia@1"]:
		Jogo.e["inventario"].append(id)
	Jogo.navegar.emit("jogo")
	await arvore.process_frame
	await arvore.process_frame
	Jogo.abrir_aba.emit("armeiro")
	var modo := OS.get_environment("MODO")
	if modo == "catalogo":
		await arvore.process_frame
		var t = arvore.root.find_children("*", "TelaArmeiro", true, false)[0]
		t._modo = "catalogo"
		t.atualizar()
