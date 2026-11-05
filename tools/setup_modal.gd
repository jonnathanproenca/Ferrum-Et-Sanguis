extends RefCounted
## Abre a modal do primeiro gladiador com itens; SEL=<slot> abre o seletor; NOARM=1 sem armaria.
func preparar(arvore: SceneTree) -> void:
	Jogo.novo(Game.lanistas()[3]["id"], "medio")
	var e: Dictionary = Jogo.e
	e["ouro"] = 5000
	for m in Game.MELHORIAS_LUDUS:
		e["melhorias"][m["id"]] = true
	e["tutorial"] = {"vistos": ["tour", "campanha", "treino", "armeiro", "enfermaria", "alojamentos", "refeitorio"]}
	var g: Dictionary = e["gladiadores"][0]
	g["gloria"] = 140
	g["treino"]["forca"] = 10
	for it in Model.itens():
		if g["classe"] in it["classes"]:
			e["inventario"].append(Model.com_qualidade(it["id"], 2))
	e["inventario"].append(Model.id_amuleto(g["terra"], "aura", 1))
	e["inventario"].append(Model.id_amuleto(g["terra"], "forca", 0))
	e["inventario"].append(Model.id_amuleto("galia" if g["terra"] != "galia" else "tracia", "aura", 0))
	for sl in ["elmo", "arma", "amuleto", "peito"]:
		for id in e["inventario"]:
			var it := Model.item_por_id(id)
			if it["slot"] == sl and Game.equipar(e, g["id"], sl, id) == "":
				break
	Jogo.navegar.emit("jogo")
	await arvore.process_frame
	await arvore.process_frame
	Jogo.abrir_aba.emit("ludus")
	await arvore.process_frame
	var m := ModalGladiador.abrir(arvore.root.find_children("*", "TelaLudus", true, false)[0], g["id"])
	for _i in 6:
		await arvore.process_frame
	if OS.get_environment("SEL") != "":
		for b in arvore.root.find_children("*", "BonecoEquipamento", true, false):
			b.slot_clicado.emit(OS.get_environment("SEL"))
