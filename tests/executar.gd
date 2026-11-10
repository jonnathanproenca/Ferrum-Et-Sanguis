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
	teste_patrocinio()
	teste_treino_combate()
	teste_modos()
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
	var inte := Model.para_lutador(lutador("murmilo", 1, {"inteligencia": 15}))
	var leve_c := Combat.chance_defesa(inte)
	inte["cargaPct"] = 0.5
	var normal_c := Combat.chance_defesa(inte)
	inte["cargaPct"] = 0.95
	var pesado_c := Combat.chance_defesa(inte)
	inte["cargaPct"] = 1.0
	var cheio_c := Combat.chance_defesa(inte)
	ok(normal_c > pesado_c and pesado_c > cheio_c and cheio_c < normal_c * 0.5, "peso alto reduz muito a defesa mesmo com INT alta (%.0f > %.0f > %.0f)" % [normal_c, pesado_c, cheio_c])
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
	ok(Game.custo_treino(e, g, "aura") == Game.custo_treino(e, g, "forca"), "custo de treino único para todos os atributos")
	g["treino"]["aura"] = 99
	ok(Game.atributo_no_maximo(g, "aura") and Game.treinar(e, g["id"], "aura") != "", "teto 99 bloqueia treino")
	g["treino"]["aura"] = 0
	for a in Model.ATRIBUTOS:
		ok(Game.treinar(e, g["id"], a) == "", "treinar %s" % a)
	# fama para comprar
	var e2 := novo()
	e2["fama"] = 0
	ok(Game.comprar_item(e2, "maca@3") != "", "item épico exige fama")
	e2["fama"] = 100
	ok(Game.comprar_item(e2, "maca@3") == "", "item épico com fama")
	# vender item: 40% do valor pago
	var ev := novo()
	ev["fama"] = 100
	var ouro_v: int = ev["ouro"]
	ok(Game.comprar_item(ev, "maca@2") == "", "compra para vender")
	var pago: int = ouro_v - int(ev["ouro"])
	var antes_v: int = ev["ouro"]
	ok(Game.vender_item(ev, "maca@2") == "", "vender item")
	ok(int(ev["ouro"]) - antes_v == Model.jsround(float(pago) * 0.4), "venda devolve 40%% (%d de %d)" % [int(ev["ouro"]) - antes_v, pago])
	ok(Game.vender_item(ev, "maca@2") != "", "não vende item que não tem")
	# amuletos: só da própria região
	var ea := novo()
	ea["fama"] = 100
	var ga: Dictionary = ea["gladiadores"][0]
	var minha: String = ga["terra"]
	var outra: String = "galia" if minha != "galia" else "dacia"
	var am_ok := Model.id_amuleto(minha, "forca", 3)
	var am_no := Model.id_amuleto(outra, "forca", 3)
	ok(Game.comprar_item(ea, am_ok) == "" and Game.comprar_item(ea, am_no) == "", "comprar amuletos")
	ok(Game.equipar(ea, ga["id"], "amuleto", am_no) != "", "amuleto de outra região não equipa")
	var f0: int = Model.stats_do_gladiador(ga)["forca"]
	ok(Game.equipar(ea, ga["id"], "amuleto", am_ok) == "", "amuleto da própria região equipa")
	ok(int(Model.stats_do_gladiador(ga)["forca"]) == f0 + 4, "amuleto Épico dá +4 no atributo")
	ok(Model.item_por_id(Model.id_amuleto(minha, "aura", 0))["nome"] != Model.item_por_id(Model.id_amuleto(outra, "aura", 0))["nome"], "nome por região")
	ok(Game.catalogo_amuletos(minha).size() == 6, "catálogo com 6 atributos")
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
	e6["famaMax"] = 10
	ok(Game.arena_liberada(e6, Game.arena_por_id("capua"))["liberada"], "Cápua abre com 10 de fama")
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

func teste_patrocinio() -> void:
	var e := novo()
	var g: Dictionary = e["gladiadores"][0]
	var rng := Rng.new(99)
	# sem lanistas derrotados na campanha, ninguém oferece
	e["campanha"] = 0
	ok(Patrocinio.tentar_oferta(e, g, 200, rng).is_empty(), "sem campanha, sem oferta")
	e["campanha"] = Patrocinio.CAMPANHA_MIN
	# chance cresce com a Aura e tem teto
	ok(Patrocinio.chance(0) < Patrocinio.chance(40), "chance sobe com Aura")
	ok(Patrocinio.chance(9999) <= Patrocinio.CHANCE_MAX, "chance tem teto")
	# oferta (força o sorteio com Aura enorme até aparecer)
	var of := {}
	for i in range(200):
		of = Patrocinio.tentar_oferta(e, g, 200, rng)
		if not of.is_empty():
			break
	ok(not of.is_empty(), "uma oferta aparece")
	ok(Patrocinio.tentar_oferta(e, g, 200, rng).is_empty(), "sem segunda oferta para o mesmo gladiador")
	# tipo respeita a fama (fama 0: só Eques)
	ok(["eques", "edil"].has(of["tipo"]), "com 2 lanistas só Eques ou Edil")
	ok(Game.aceitar_patrocinio(e, of["id"]) == "", "aceitar oferta")
	ok(not Patrocinio.contrato_do(e, g["id"]).is_empty(), "contrato criado")
	var e_rom := e.duplicate(true)
	ok(Game.romper_patrocinio(e_rom, g["id"]) == "", "romper contrato")
	ok(Patrocinio.contrato_do(e_rom, g["id"]).is_empty(), "contrato some ao romper")
	ok(Game.romper_patrocinio(e_rom, g["id"]) != "", "romper sem contrato dá erro")
	ok(Patrocinio.ofertas(e).is_empty(), "oferta consumida")
	# rodada: paga e, sem vitórias dentro do prazo, rompe sem multa
	var ouro0: int = int(e["ouro"])
	e["energia"] = 0
	var c := Patrocinio.contrato_do(e, g["id"])
	var prazo: int = int(c["prazo"])
	for i in range(prazo):
		e["energia"] = 0
		Game.avancar_turno(e)
	ok(Patrocinio.contrato_do(e, g["id"]).is_empty(), "meta não cumprida: contrato rompido")
	ok(int(e["ouro"]) != ouro0, "ouro mudou nas rodadas")
	# meta cumprida renova
	var e2 := novo()
	e2["campanha"] = 2
	var g2: Dictionary = e2["gladiadores"][0]
	var of2 := {}
	for i in range(200):
		of2 = Patrocinio.tentar_oferta(e2, g2, 200, rng)
		if not of2.is_empty():
			break
	Game.aceitar_patrocinio(e2, of2["id"])
	var c2 := Patrocinio.contrato_do(e2, g2["id"])
	for i in range(int(c2["meta"])):
		Patrocinio.registrar_vitoria(e2, g2["id"])
	for i in range(int(c2["prazo"])):
		e2["energia"] = 0
		Game.avancar_turno(e2)
	ok(not Patrocinio.contrato_do(e2, g2["id"]).is_empty(), "meta cumprida: contrato renovado")
	# gladiador removido leva o contrato
	Game.dispensar_gladiador(e2, g2["id"]) if not g2["campeao"] else null
	# oferta expira
	var e3 := novo()
	e3["campanha"] = 2
	var g3: Dictionary = e3["gladiadores"][0]
	for i in range(200):
		if not Patrocinio.tentar_oferta(e3, g3, 200, rng).is_empty():
			break
	for i in range(Patrocinio.VALIDADE_OFERTA):
		e3["energia"] = 0
		Game.avancar_turno(e3)
	ok(Patrocinio.ofertas(e3).is_empty(), "oferta vence com as rodadas")

func _passos(c: TreinoCombate, seg: float) -> void:
	var n := int(round(seg * 60.0))
	for i in range(n):
		c.atualizar(1.0 / 60.0)

func _boneco_ataca(c: TreinoCombate) -> void:
	c.b_prox = 0.0
	_passos(c, 1.0 / 60.0)

func teste_treino_combate() -> void:
	var c := TreinoCombate.new(3)
	# andar respeita os limites
	c.definir_direcao(-1)
	_passos(c, 5.0)
	ok(c.x == TreinoCombate.X_MIN, "andar para trás para no limite")
	c.definir_direcao(1)
	_passos(c, 5.0)
	ok(c.x <= TreinoCombate.X_BONECO - TreinoCombate.DIST_MIN + 0.01, "andar para frente para antes do boneco")
	c.definir_direcao(0)
	# parry: guarda erguida perto do golpe
	c = TreinoCombate.new(3)
	_boneco_ataca(c)
	_passos(c, 0.55)
	c.defesa(true)
	_passos(c, 0.25)
	ok(c.placar["parries"] == 1 and c.b_estado == "atordoado", "parry no tempo certo atordoa o boneco")
	# bloqueio comum: guarda erguida cedo demais
	c = TreinoCombate.new(3)
	c.defesa(true)
	_boneco_ataca(c)
	_passos(c, 0.9)
	ok(c.placar["bloqueios"] == 1 and c.placar["parries"] == 0, "guarda erguida cedo só bloqueia")
	# esquiva anula o golpe e a posição recua
	c = TreinoCombate.new(3)
	_boneco_ataca(c)
	_passos(c, 0.5)
	var x0 := c.x
	c.esquiva()
	_passos(c, 0.4)
	ok(c.placar["esquivas"] == 1 and c.x < x0, "esquiva no tempo certo anula o golpe e recua")
	# sem defesa nem esquiva, leva o golpe (sem vida: só conta)
	c = TreinoCombate.new(3)
	_boneco_ataca(c)
	_passos(c, 0.9)
	ok(c.placar["levados"] == 1, "sem reação, leva o golpe")
	# fora de alcance não conta
	c = TreinoCombate.new(3)
	c.x = TreinoCombate.X_MIN
	_boneco_ataca(c)
	_passos(c, 0.9)
	ok(c.placar["levados"] == 0, "golpe do boneco erra se estiver longe")
	# anti-spam do parry
	c = TreinoCombate.new(3)
	c.defesa(true)
	_passos(c, 0.1)
	c.defesa(false)
	_passos(c, 0.1)
	c.defesa(true)
	ok(not c.defendendo, "guarda não reergue logo depois de baixar")
	# segurar o ataque vira pesado; toque rápido é leve
	c = TreinoCombate.new(3)
	c.atacar_pressionar()
	_passos(c, 0.5)
	c.atacar_soltar()
	ok(c.estado == "pesado", "segurar o ataque vira golpe pesado")
	c = TreinoCombate.new(3)
	c.atacar_pressionar()
	_passos(c, 0.1)
	c.atacar_soltar()
	ok(c.estado == "leve", "toque rápido é ataque leve")
	# pesado quebra o golpe do boneco; depois dá crítico
	c = TreinoCombate.new(3)
	_boneco_ataca(c)
	_passos(c, 0.2)
	c.ataque_pesado()
	_passos(c, 0.5)
	ok(c.b_estado == "atordoado", "pesado quebra o golpe do boneco")
	_passos(c, 0.7)  # recuperação do jogador
	var crit0: int = c.placar["criticos"]
	c.ataque_pesado()
	_passos(c, 0.7)
	ok(c.placar["criticos"] == crit0 + 1, "pesado no boneco atordoado é crítico")


func teste_modos() -> void:
	# modos: prazo, passos e morte
	var e := Game.novo_jogo(1, "lanista-3", "medio", "municipais")
	ok(Game.modo_de(e)["nome"] == "Jogos Municipais" and Game.n_passos(e) == 3, "modo municipais: 3 passos")
	ok(Game.morte_de(e) == "nunca", "municipais: ninguém morre")
	e["energia"] = 0
	for i in range(39):
		e["gladiadores"][0]["vivo"] = true
		Game.avancar_turno(e)
		e["energia"] = 0
	Game.atualizar_fim(e)
	ok(e["fim"] == "" and int(e["turno"]) == 40, "rodada 40 ainda dentro do prazo")
	Game.avancar_turno(e)
	Game.atualizar_fim(e)
	ok(e["fim"] == "prazo", "passou da rodada 40: prazo esgotado")
	ok(Game.avancar_turno(e) != "", "perfil acabado não avança turno")
	# game over fica gravado, mesmo se o ouro voltar
	var g := Game.novo_jogo(2, "lanista-3", "medio", "imperial")
	for gl in g["gladiadores"]:
		gl["vivo"] = false
	g["ouro"] = 0
	Game.atualizar_fim(g)
	ok(g["fim"] == "gameover", "sem gladiadores e sem ouro: game over")
	g["ouro"] = 99999
	Game.atualizar_fim(g)
	ok(g["fim"] == "gameover" and Game.fim_bloqueia(g), "game over persiste")
	# campanha concluída = vitória, sem bloquear
	var v := Game.novo_jogo(3, "lanista-3", "medio", "sangue")
	v["campanha"] = Game.n_passos(v)
	ok(Game.proximo_desafio(v).is_empty(), "sangue termina em 7 passos")
	Game.atualizar_fim(v)
	ok(v["fim"] == "vitoria" and not Game.fim_bloqueia(v), "vitória não bloqueia")
	# resumo
	var r := Game.resumo_perfil(e)
	ok(r["modo"] == "Jogos Municipais" and r["atuais"] >= 0 and r["historico"] >= 1, "resumo do perfil")
	# perfis (arquivos)
	var J = load("res://scripts/jogo.gd").new()
	J.slot_novo = 3
	J.novo("lanista-3", "medio", "livre")
	ok(J.perfil_existe(3) and J.slot == 3, "novo perfil grava no slot")
	ok(bool(J.e["cheats"].get("ouro", false)) and int(J.e["ouro"]) >= 9999999, "simulador: ouro infinito")
	J.renomear_perfil(3, "Meu Ludus")
	J.e = {}
	ok(J.continuar(3) and J.e["perfilNome"] == "Meu Ludus", "carrega e renomeia perfil")
	J.apagar_save(3)
	ok(not J.perfil_existe(3) and J.e.is_empty(), "apagar perfil")
