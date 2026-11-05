extends SceneTree
## Simulação de economia/progressão com um "jogador" automático.
## godot --headless --path . -s tools/balance.gd -- [turnos] [semente] [dificuldade]
## Imprime, a cada 10 turnos: ouro, fama, níveis, atributos e arena usada.

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var turnos := int(args[0]) if args.size() > 0 else 120
	var semente := int(args[1]) if args.size() > 1 else 7
	var dif := str(args[2]) if args.size() > 2 else "medio"
	var e := Game.novo_jogo(semente, Game.lanistas()[3]["id"], dif)
	print("T   ouro  fama  glad  nivel  somaAtr  treinos  vit/der  arena     custoTreino  gastos(c/t/i)")
	var vit := 0
	var der := 0
	var arena_uso := {}
	var vit_a := {}
	var gasto := {"construir": 0, "treino": 0, "itens": 0, "recrutar": 0}
	for t in range(1, turnos + 1):
		_construir(e, gasto)
		_recrutar(e, gasto)
		_equipar(e, gasto)
		var guard := 0
		while int(e["energia"]) > 0 and guard < 12:
			guard += 1
			var viv: Array = e["gladiadores"].filter(func(g: Dictionary) -> bool: return g["vivo"] and not g.get("semEstilo", false) and not g["pocoOnly"])
			if viv.is_empty():
				break
			viv.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return _poder(a) > _poder(b))
			var g: Dictionary = viv[0]
			var arena_id := _melhor_arena(e, g)
			var treina := Game.tem_melhoria(e, "palus") and _vale_treinar(e, g, arena_id)
			if treina:
				var atr := _atributo_a_treinar(g)
				var custo := Game.custo_treino(e, g, atr)
				if int(e["ouro"]) >= custo + 20:
					gasto["treino"] += custo
					Game.treinar(e, g["id"], atr)
					continue
			var p: Dictionary = Game.lutar_arena(e, [g["id"]], arena_id)
			if p.has("erro"):
				break
			arena_uso[arena_id] = int(arena_uso.get(arena_id, 0)) + 1
			vit_a[arena_id] = int(vit_a.get(arena_id, 0)) + (1 if p["vitoriaA"] else 0)
			if p["vitoriaA"]:
				vit += 1
			else:
				der += 1
			_equipar(e, gasto)
		Game.avancar_turno(e)
		if e["gladiadores"].filter(func(x: Dictionary) -> bool: return x["vivo"]).is_empty():
			print("GAME OVER no turno ", t)
			break
		if t % 10 == 0 or t == 1:
			var melhor := _melhor(e)
			print("    taxas de vitória: ", _taxas(e, melhor))
			var soma := 0
			var st := Model.stats_sem_itens(melhor)
			for a in Model.ATRIBUTOS:
				soma += int(st[a])
			print("%-3d %-5d %-5d %-5d %-6d %-8d %-8d %d/%-6d %-9s %-12d %d/%d/%d" % [t, int(e["ouro"]), int(e.get("fama", 0)), e["gladiadores"].size(), int(melhor["nivel"]), soma, Model.soma_treino(melhor), vit, der, _arena_top(arena_uso), Game.custo_treino(e, melhor), gasto["construir"], gasto["treino"], gasto["itens"]])
	print("arenas usadas: ", arena_uso, "  vitórias por arena: ", vit_a, "  vit/der ", vit, "/", der)
	quit()


func _poder(g: Dictionary) -> float:
	var s := Model.stats_do_gladiador(g)
	var t := 0.0
	for a in Model.ATRIBUTOS:
		t += float(s[a])
	return t


func _melhor(e: Dictionary) -> Dictionary:
	var m: Dictionary = e["gladiadores"][0]
	for g in e["gladiadores"]:
		if g["vivo"] and _poder(g) > _poder(m):
			m = g
	return m


func _arena_top(uso: Dictionary) -> String:
	var b := ""
	var n := -1
	for k in uso:
		if int(uso[k]) > n:
			n = int(uso[k])
			b = str(k)
	return b


func _construir(e: Dictionary, gasto: Dictionary) -> void:
	for id in ["palus", "armaria", "alojamentos", "refeitorio", "enfermaria"]:
		if Game.tem_melhoria(e, id):
			continue
		var custo := Game.custo_melhoria(e, id)
		if int(e["ouro"]) >= custo + 60:
			if Game.construir_melhoria(e, id) == "":
				gasto["construir"] += custo
		return


func _recrutar(e: Dictionary, gasto: Dictionary) -> void:
	var cap := Game.capacidade_ludus(e)
	var alvo := mini(cap, 3)
	while e["gladiadores"].size() < alvo:
		var melhor: Dictionary = {}
		for m in e["mercado"]:
			var pr := Game.preco_recruta(e, m)
			if pr <= int(e["ouro"]) - 40 and (melhor.is_empty() or pr < Game.preco_recruta(e, melhor)):
				melhor = m
		if melhor.is_empty():
			return
		gasto["recrutar"] += Game.preco_recruta(e, melhor)
		Game.recrutar(e, melhor["id"])
	for g in e["gladiadores"]:
		if g.get("semEstilo", false) and int(e["energia"]) >= 0:
			Game.escolher_estilo(e, g["id"], "murmilo")


func _equipar(e: Dictionary, gasto: Dictionary) -> void:
	if not Game.tem_melhoria(e, "armaria"):
		return
	var viv: Array = e["gladiadores"].filter(func(g: Dictionary) -> bool: return g["vivo"] and not g.get("semEstilo", false))
	for g: Dictionary in viv:
		for slot in Model.SLOTS:
			var atual = g["equipamento"][slot]
			var val_atual := _valor_item(atual) if atual != null else -1.0
			var melhor_id := ""
			var melhor_val := val_atual
			for base in Model.itens():
				if base["slot"] != slot or not (g["classe"] in base["classes"]):
					continue
				for q in range(0, 5):
					var id := Model.com_qualidade(base["id"], q)
					var it := Model.item_por_id(id)
					if it.is_empty():
						continue
					var v := _valor_item(id)
					if v <= melhor_val:
						continue
					var preco := Game.preco_item(e, it)
					if preco > int(e["ouro"]) * 0.6 or Game.fama_efetiva(e) < int(it["famaMin"]):
						continue
					var copia := e.duplicate(true)
					copia["inventario"].append(id)
					if Game.equipar(copia, g["id"], slot, id) == "":
						melhor_id = id
						melhor_val = v
			if melhor_id != "":
				var it2 := Model.item_por_id(melhor_id)
				var preco2 := Game.preco_item(e, it2)
				if Game.comprar_item(e, melhor_id) == "":
					gasto["itens"] += preco2
					Game.equipar(e, g["id"], slot, melhor_id)


func _valor_item(id) -> float:
	var it := Model.item_por_id(str(id))
	if it.is_empty():
		return 0.0
	var v := 0.0
	for a in Model.ATRIBUTOS:
		v += float(it["bonus"].get(a, 0))
	return v


func _taxas(e: Dictionary, g: Dictionary) -> String:
	var out := ""
	for a in Game.arenas():
		if not a["honra"] or not Game.arena_liberada(e, a)["liberada"]:
			continue
		var vit := 0
		for i in range(30):
			var copia := e.duplicate(true)
			copia["semente"] = 1000 + i * 7919
			var p: Dictionary = Game.lutar_arena(copia, [g["id"]], a["id"])
			if not p.has("erro") and p["vitoriaA"]:
				vit += 1
		out += "%s %d%%  " % [a["id"], vit * 100 / 30]
	return out


func _melhor_arena(e: Dictionary, g: Dictionary) -> String:
	var escolhida := "pompeia"
	for a in Game.arenas():
		if not a["honra"]:
			continue
		if not Game.arena_liberada(e, a)["liberada"]:
			continue
		var vit := 0
		var n := 10
		for i in range(n):
			var copia := e.duplicate(true)
			copia["semente"] = 5000 + i * 104729
			var p: Dictionary = Game.lutar_arena(copia, [g["id"]], a["id"])
			if not p.has("erro") and p["vitoriaA"]:
				vit += 1
		if float(vit) / float(n) >= 0.6:
			escolhida = a["id"]
	return escolhida


## Treina quando a arena atual já está "fácil" demais ou o ouro sobra; senão luta para ganhar ouro.
func _vale_treinar(e: Dictionary, g: Dictionary, arena_id: String) -> bool:
	var custo := Game.custo_treino(e, g)
	return int(e["ouro"]) >= int(custo * 1.5)


func _atributo_a_treinar(g: Dictionary) -> String:
	var st := Model.stats_sem_itens(g)
	var ordem := ["vitalidade", "forca", "destreza", "inteligencia", "resistencia"]
	var menor: String = ordem[0]
	for a in ordem:
		if int(st[a]) < int(st[menor]) - 2 or (a == "vitalidade" and int(st[a]) < int(st["forca"]) + 4):
			menor = a
			break
		if int(st[a]) < int(st[menor]):
			menor = a
	return menor
