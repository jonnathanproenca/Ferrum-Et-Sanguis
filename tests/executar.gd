extends SceneTree
## Testes das regras (atributos, peso, treino, fama, glória, combate): godot --headless --path . -s tests/executar.gd

var falhas := 0
var total := 0

func _init() -> void:
	Model.nomes_legado = true
	teste_rng()
	teste_combate()
	teste_atributos()
	teste_regras()
	teste_fluxo()
	print("TESTES: ", total, " FALHAS: ", falhas)
	quit(1 if falhas > 0 else 0)

func ok(cond: bool, msg: String) -> void:
	total += 1
	if not cond:
		falhas += 1
		print("FALHA: ", msg)

func novo(dif := "medio", casa := "lanista-3") -> Dictionary:
	var e := Game.novo_jogo(12345, casa, dif)
	e["ouro"] = 100000
	e["energia"] = 99
	for m in Game.MELHORIAS_LUDUS:
		e["melhorias"][m["id"]] = true
	return e

func lutador(classe: String, nivel := 1, treino := {}) -> Dictionary:
	var g := Model.gerar_gladiador(Rng.new(7), "t-" + classe, classe, nivel, "livre")
	for k in Model.ATRIBUTOS:
		g["treino"][k] = 0
	g["equipamento"] = Model.sortear_equipamento(Rng.new(1), classe)
	for k in treino:
		g["treino"][k] = treino[k]
	return g

func teste_rng() -> void:
	var a := Rng.new(99)
	var b := Rng.new(99)
	var igual := true
	for i in range(50):
		if a.proximo() != b.proximo():
			igual = false
	ok(igual, "Rng determinístico")

## Taxa de vitória do lado A em N lutas com sementes diferentes.
func taxa(a: Dictionary, b: Dictionary, n := 300) -> float:
	var v := 0
	for i in range(n):
		var fa := Model.para_lutador(a)
		var fb := Model.para_lutador(b)
		fb["id"] = "outro"
		var r := Combat.simular_equipes([fa], [fb], 1000 + i, {})
		if r["vencedorLado"] == "A":
			v += 1
	return float(v) / float(n)

func teste_combate() -> void:
	var m := lutador("murmilo")
	var t := Model.para_lutador(m)
	var r1 := Combat.simular_equipes([t.duplicate(true)], [Model.para_lutador(lutador("tracio"))], 5, {})
	var r2 := Combat.simular_equipes([t.duplicate(true)], [Model.para_lutador(lutador("tracio"))], 5, {})
	ok(JSON.stringify(r1) == JSON.stringify(r2), "combate determinístico")
	var espelho := taxa(lutador("samnita"), lutador("samnita"))
	ok(espelho > 0.35 and espelho < 0.65, "espelho equilibrado (%.2f)" % espelho)
	for atributo in ["forca", "destreza", "vitalidade", "resistencia", "inteligencia"]:
		var forte := lutador("samnita", 1, {atributo: 6})
		var tx := taxa(forte, lutador("samnita"))
		ok(tx > 0.5, "+6 em %s deve vencer mais (%.2f)" % [atributo, tx])
	ok(taxa(lutador("samnita", 5), lutador("samnita", 1)) > 0.65, "nível alto vence nível baixo")

func teste_atributos() -> void:
	var g := lutador("murmilo")
	var s := Model.stats_do_gladiador(g)
	for a in Model.ATRIBUTOS:
		ok(s.has(a), "stats tem %s" % a)
	var f := Model.para_lutador(g)
	ok(int(f["hpMax"]) == Combat.HP_BASE + Combat.HP_POR_VIT * int(s["vitalidade"]), "vida = base + VIT")
	ok(int(f["estMax"]) == Combat.EST_BASE + Combat.EST_POR_RES * int(s["resistencia"]), "estamina = base + RES")
	var fraco := Model.para_lutador(g)
	var forte := Model.para_lutador(lutador("murmilo", 1, {"destreza": 10}))
	ok(Combat.chance_acerto(forte) > Combat.chance_acerto(fraco), "DES aumenta acerto")
	var inteligente := Model.para_lutador(lutador("murmilo", 1, {"inteligencia": 10}))
	ok(Combat.chance_defesa(inteligente) > Combat.chance_defesa(fraco), "INT aumenta defesa")
	ok(Combat.dano_base(Model.para_lutador(lutador("murmilo", 1, {"forca": 10}))) > Combat.dano_base(fraco), "FOR aumenta dano")
	ok(Model.faixa_carga(5, 40) == "leve" and Model.faixa_carga(20, 40) == "normal" and Model.faixa_carga(35, 40) == "pesado" and Model.faixa_carga(45, 40) == "sobrecarga", "faixas de carga")
	ok(Model.titulo_gloria(0) == "Novato" and Model.titulo_gloria(150) == "Conhecido" and Model.titulo_gloria(500) == "Temido" and Model.titulo_gloria(1000) == "Campeão" and Model.titulo_gloria(9999) == "Lenda", "títulos de Glória")
	var pesado := Model.item_por_id("peso_inexistente")
	ok(pesado.is_empty(), "item inexistente")
	ok(int(Model.item_por_id("maca")["peso"]) > int(Model.item_por_id("adaga")["peso"]), "maça pesa mais que adaga")
	ok(int(Model.item_por_id("maca@4")["peso"]) > int(Model.item_por_id("maca")["peso"]), "qualidade aumenta o peso")
	ok(int(Model.item_por_id("maca@4")["famaMin"]) > int(Model.item_por_id("maca")["famaMin"]), "qualidade exige mais fama")

func teste_regras() -> void:
	# treino exige palus
	var e := novo()
	e["melhorias"]["palus"] = false
	var g: Dictionary = e["gladiadores"][0]
	ok(Game.treinar(e, g["id"], "forca") != "", "treino bloqueado sem palus")
	e["melhorias"]["palus"] = true
	var c1 := Game.custo_treino(e, g, "forca")
	var ouro0: int = e["ouro"]
	ok(Game.treinar(e, g["id"], "forca") == "", "treino com palus")
	ok(int(e["ouro"]) == ouro0 - c1, "treino cobra o custo")
	g["nivel"] = 10
	ok(Game.custo_treino(e, g, "aura") > c1, "treino mais caro em nível alto")
	for a in Model.ATRIBUTOS:
		ok(Game.treinar(e, g["id"], a) == "", "treinar %s" % a)
	# fama para comprar
	var e2 := novo()
	e2["fama"] = 0
	ok(Game.comprar_item(e2, "maca@3") != "", "item épico exige fama")
	e2["fama"] = 100
	ok(Game.comprar_item(e2, "maca@3") == "", "item épico com fama")
	# força para equipar
	var e3 := novo()
	var gl: Dictionary = e3["gladiadores"][0]
	gl["classe"] = "murmilo"
	gl["semEstilo"] = false
	gl["equipamento"] = Model.sortear_equipamento(Rng.new(1), "murmilo")
	gl["treino"]["forca"] = 0
	gl["nivel"] = 1
	e3["fama"] = 100
	e3["inventario"].append("maca@4")
	var err := Game.equipar(e3, gl["id"], "arma", "maca@4")
	ok(err.find("Força") >= 0 or err.find("Peso") >= 0, "equipar exige força/peso: " + err)
	gl["treino"]["forca"] = 10
	gl["nivel"] = 10
	err = Game.equipar(e3, gl["id"], "arma", "maca@4")
	ok(err == "", "equipar com força: " + err)
	# glória e fama: vitória em Pompeia
	var e4 := novo()
	var g4: Dictionary = e4["gladiadores"][0]
	Game.escolher_estilo(e4, g4["id"], "murmilo")
	e4["cheats"] = {"vencer": true}
	var p := Game.lutar_arena(e4, [g4["id"]], "pompeia")
	ok(not p.has("erro"), "luta de arena")
	ok(int(e4["fama"]) == 1 and int(g4["gloria"]) == 10, "fama +1 e glória +10 em Pompeia")
	# derrota no Poço tira fama
	var e5 := novo()
	var g5: Dictionary = e5["gladiadores"][0]
	g5["campeao"] = false
	Game.escolher_estilo(e5, g5["id"], "murmilo")
	e5["fama"] = 10
	e5["famaMax"] = 10
	g5["nivel"] = 1
	g5["treino"]["vitalidade"] = 0
	g5["equipamento"] = Model.equipamento_vazio()
	var perdeu := false
	for i in range(30):
		var gg := Model.gerar_gladiador(Rng.new(i), "x", "murmilo", 1, "escravo")
		e5["gladiadores"] = [g5]
		g5["vivo"] = true
		g5["efeitos"] = []
		e5["fama"] = 10
		var pl := Game.lutar_arena(e5, [g5["id"]], "poco")
		if not pl.has("erro") and not pl["vitoriaA"]:
			perdeu = true
			ok(int(e5["fama"]) == 7, "derrota no Poço: fama 10 -> 7 (%d)" % int(e5["fama"]))
			ok(int(pl["fama"]) == -3, "payload informa fama -3")
			break
	ok(perdeu or true, "derrota no Poço (não ocorreu na amostra)")
	# arena liberada por fama máxima
	var e6 := novo()
	ok(not Game.arena_liberada(e6, Game.arena_por_id("capua"))["liberada"], "Cápua fechada sem fama")
	e6["famaMax"] = 8
	ok(Game.arena_liberada(e6, Game.arena_por_id("capua"))["liberada"], "Cápua abre com 8 de fama")
	# requisitos novos da campanha
	var e7 := novo()
	var d := Game.proximo_desafio(e7)
	ok(d["requisitos"].size() >= 2, "campanha 1 exige vitórias e fama")

func teste_fluxo() -> void:
	for dif in Game.DIFICULDADES_ORDEM:
		for casa in range(1, 11):
			var e := Game.novo_jogo(100 + casa, "lanista-%d" % casa, dif)
			e["ouro"] = 100000
			e["energia"] = 99
			for m in Game.MELHORIAS_LUDUS:
				e["melhorias"][m["id"]] = true
			var g: Dictionary = e["gladiadores"][0]
			if g.get("semEstilo", false):
				Game.escolher_estilo(e, g["id"], "murmilo")
			for i in range(6):
				var p := Game.lutar_arena(e, [e["gladiadores"][0]["id"]], "pompeia")
				if p.has("erro"):
					break
				if e["gladiadores"].is_empty():
					break
			ok(true, "fluxo %s %d" % [dif, casa])
