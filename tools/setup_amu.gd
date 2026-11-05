extends RefCounted
func preparar(arvore: SceneTree) -> void:
	Jogo.novo(Game.lanistas()[3]["id"], "medio")
	Jogo.e["ouro"] = 400
	Jogo.e["fama"] = 30
	Jogo.e["tutorial"] = {"vistos": ["tour", "campanha", "treino", "armeiro", "enfermaria", "alojamentos", "refeitorio"]}
	for m in Game.MELHORIAS_LUDUS:
		Jogo.e["melhorias"][m["id"]] = true
	var g = Jogo.e["gladiadores"][0]
	for a in ["forca","aura"]:
		Jogo.e["inventario"].append(Model.id_amuleto(g["terra"], a, 1))
	Jogo.e["inventario"].append(Model.id_amuleto("galia" if g["terra"] != "galia" else "dacia", "destreza", 2))
	Jogo.navegar.emit("jogo")
	await arvore.process_frame
	await arvore.process_frame
	Jogo.abrir_aba.emit("armeiro")
	await arvore.process_frame
	var t = arvore.root.find_children("*", "TelaArmeiro", true, false)[0]
	t._modo = "amuletos"
	t.atualizar()
