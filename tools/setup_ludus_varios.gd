extends RefCounted
## 5-6 gladiadores variados; ABERTO=1 abre o equipamento do primeiro; SEM_ARMARIA=1 sem melhorias.
func preparar(arvore: SceneTree) -> void:
	Jogo.novo(Game.lanistas()[3]["id"], "facil")
	var e: Dictionary = Jogo.e
	e["ouro"] = 5000
	if OS.get_environment("SEM_ARMARIA") == "":
		for m in Game.MELHORIAS_LUDUS:
			e["melhorias"][m["id"]] = true
	var rng := Rng.new(99)
	# escravo sem estilo
	var a := Model.gerar_escravo(rng, Game.novo_id(e)); e["gladiadores"].append(a)
	# escravo com estilo, ferido
	var b := Model.gerar_gladiador(rng, Game.novo_id(e), "retiario", 3, "escravo", false, 2)
	b["condicao"] = "maduro"; b["efeitos"] = [{"tipo": "sangramento", "severidade": 2}, {"tipo": "queimadura", "severidade": 1}]
	b["vitorias"] = 2; b["derrotas"] = 1; b["vitoriasPoco"] = 4
	e["gladiadores"].append(b)
	# lenda
	var c := Model.gerar_gladiador(rng, Game.novo_id(e), "tracio", 9, "escravo", false, 4)
	c["lenda"] = true; c["vitorias"] = 20; c["lutasComoLenda"] = 3; c["condicao"] = "maduro"
	e["gladiadores"].append(c)
	var d := Model.gerar_gladiador(rng, Game.novo_id(e), "samnita", 5, "livre", false, 3); d["vitorias"] = 7
	e["gladiadores"].append(d)
	var f := Model.gerar_escravo(rng, Game.novo_id(e)); f["terra"] = "tracia"; e["gladiadores"].append(f)
	var h := Model.gerar_gladiador(rng, Game.novo_id(e), "murmilo", 2, "escravo", false, 1); h["condicao"] = "jovem"
	e["gladiadores"].append(h)
	for it in ["gladio_largo", "gladio_largo@3", "maca", "sica", "escudo_oval", "elmo_viseira@2"]:
		e["inventario"].append(it)
	for it in Model.itens():
		if "retiario" in it["classes"] or "samnita" in it["classes"]:
			e["inventario"].append(it["id"])
	Jogo.navegar.emit("jogo")
	await arvore.process_frame
	await arvore.process_frame
	Jogo.abrir_aba.emit("ludus")
	await arvore.process_frame
	if OS.get_environment("ABERTO") != "":
		var tela: TelaLudus = arvore.root.find_children("*", "TelaLudus", true, false)[0]
		for k in tela._cartas:
			tela._cartas[k]._alternar()
			if OS.get_environment("ABERTO") == "1": break
	if OS.get_environment("SCROLL") != "":
		await arvore.process_frame
		await arvore.process_frame
		var sc: ScrollContainer = arvore.root.find_children("*", "ScrollContainer", true, false)[0]
		sc.scroll_vertical = int(OS.get_environment("SCROLL"))
