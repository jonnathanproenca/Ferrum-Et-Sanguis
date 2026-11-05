extends RefCounted
func preparar(arvore: SceneTree) -> void:
	Jogo.novo(Game.lanistas()[3]["id"], "facil")
	Jogo.e["ouro"] = 5000
	for m in Game.MELHORIAS_LUDUS: Jogo.e["melhorias"][m["id"]] = true
	Jogo.e["inventario"].append("gladio_largo@2")
	Jogo.navegar.emit("jogo")
	await arvore.process_frame
	await arvore.process_frame
	var tela: TelaLudus = arvore.root.find_children("*", "TelaLudus", true, false)[0]
	var id: String = Jogo.e["gladiadores"][0]["id"]
	var c = tela._cartas[id]
	c._alternar()
	var antes = c
	print("A")
	var obs = c.find_children("*", "OptionButton", true, false)
	# achar o OptionButton do slot arma (tem item gladio_largo)
	for ob in obs:
		for i in range(ob.item_count):
			if str(ob.get_item_metadata(i)) == "gladio_largo@2":
				ob.selected = i
				ob.item_selected.emit(i)
	await arvore.process_frame
	print("EQ=", Jogo.e["gladiadores"][0]["equipamento"]["arma"], " inv=", Jogo.e["inventario"], " mesma carta=", tela._cartas[id] == antes, " aberto=", tela._cartas[id].aberto)
	var b := Game.treinar(Jogo.e, id, "forca"); print("treino:", b)
