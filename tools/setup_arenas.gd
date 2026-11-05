extends RefCounted
## Aba Arenas. Ambiente: N (0|1|2 escalados), BAT (batalhas disputadas), POCO=1 (marca um gladiador como pocoOnly), LUTAR=<arena> (clica em Lutar)
func preparar(arvore: SceneTree) -> void:
	Jogo.novo(Game.lanistas()[3]["id"], "medio")
	Jogo.e["ouro"] = 5000
	Jogo.e["batalhasTotais"] = int(OS.get_environment("BAT")) if OS.get_environment("BAT") != "" else 10
	for m in Game.MELHORIAS_LUDUS:
		Jogo.e["melhorias"][m["id"]] = true
	var cls := ["murmilo", "retiario", "tracio", "samnita"]
	for i in range(3):
		var erro := Game.recrutar(Jogo.e, Jogo.e["mercado"][0]["id"])
		if erro != "":
			push_error(erro)
	var k := 0
	for g in Jogo.e["gladiadores"]:
		if g.get("semEstilo", false):
			Game.escolher_estilo(Jogo.e, g["id"], cls[k % 4])
			k += 1
	var n := int(OS.get_environment("N")) if OS.get_environment("N") != "" else 0
	Jogo.equipe = Jogo.e["gladiadores"].slice(0, n).map(func(g): return g["id"])
	if OS.get_environment("POCO") != "":
		Jogo.e["gladiadores"][0]["pocoOnly"] = true
	Jogo.navegar.emit("jogo")
	await arvore.process_frame
	await arvore.process_frame
	Jogo.abrir_aba.emit("arenas")
	Jogo.mudou.emit()
	if OS.get_environment("LUTAR") != "":
		await arvore.process_frame
		var t = arvore.root.find_children("*", "TelaArenas", true, false)[0]
		t._lutar(OS.get_environment("LUTAR"))
	if OS.get_environment("ROLAR") != "":
		await arvore.process_frame
		var t2 = arvore.root.find_children("*", "TelaArenas", true, false)[0]
		for sc in t2.find_children("*", "ScrollContainer", false, false):
			sc.scroll_vertical = int(OS.get_environment("ROLAR"))
	if OS.get_environment("ACAO") != "":
		await arvore.create_timer(1.5).timeout
		var tl = arvore.root.find_children("*", "TelaLuta", true, false)[0]
		print("ouro antes: ", Jogo.e["ouro"], " energia ", Jogo.e["energia"], " derrotas: ", Jogo.e["gladiadores"][0]["derrotas"])
		if OS.get_environment("ACAO") == "pular":
			tl._pular()
			await arvore.create_timer(1.0).timeout
			print("pulou; ouro: ", Jogo.e["ouro"])
		else:
			tl._confirmar_desistencia()
			await arvore.process_frame
			for b in tl._sobreposicao.find_children("*", "Button", true, false):
				if b.text == "Desistir":
					b.pressed.emit()
			await arvore.process_frame
			await arvore.process_frame
			print("desistiu; ouro: ", Jogo.e["ouro"], " energia ", Jogo.e["energia"], " derrotas: ", Jogo.e["gladiadores"][0]["derrotas"], " telas: ", arvore.root.find_children("*", "TelaLuta", true, false).size())
