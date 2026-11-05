extends SceneTree
func _initialize() -> void:
	var falhas := 0
	for a in Model.CLASSES_IDS:
		for b in Model.CLASSES_IDS:
			if a == b: continue
			var e := Game.novo_jogo(5, Game.lanistas()[3]["id"], "medio")
			e["ouro"] = 99999; e["energia"] = 99
			for m in Game.MELHORIAS_LUDUS: e["melhorias"][m["id"]] = true
			var g: Dictionary = e["gladiadores"][0]
			g["campeao"] = false
			g["classe"] = a
			g["equipamento"] = Model.sortear_equipamento(Game.proximo_rng(e), a)
			# equipa itens comprados da classe a
			for it in Model.itens():
				if a in it["classes"] and g["equipamento"].get(it["slot"]) != null:
					var id := Model.com_qualidade(it["id"], 2)
					e["inventario"].append(id)
					Game.equipar(e, g["id"], it["slot"], id)
			var err := Game.trocar_classe(e, g["id"], b)
			var ruim := []
			for slot in Model.SLOTS:
				var id = g["equipamento"][slot]
				if id != null and Model.item_por_id(str(id)).is_empty():
					ruim.append("%s=%s" % [slot, id])
			var st := Model.stats_do_gladiador(g)
			if err != "" or not ruim.is_empty():
				falhas += 1
				print(a, "->", b, " err=", err, " ruim=", ruim)
	print("falhas: ", falhas)
	quit()
