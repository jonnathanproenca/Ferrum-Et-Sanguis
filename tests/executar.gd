extends SceneTree
## Roda todos os testes de paridade com o jogo em TypeScript: godot --headless --path . -s tests/executar.gd

var falhas := 0

func _init() -> void:
	Model.nomes_legado = true
	teste_combate()
	teste_jogo()
	print("FALHAS: ", falhas)
	quit(1 if falhas > 0 else 0)

func conferir(ok: bool, msg: String) -> void:
	if not ok:
		falhas += 1
		print("FALHA: ", msg)

func teste_combate() -> void:
	var v: Dictionary = Util.ler_json("res://tests/vetores/combate.json")
	var r := Rng.new(777)
	for i in range(v["seq"].size()):
		var x: float = r.proximo()
		if absf(x - float(v["seq"][i])) > 1e-12:
			conferir(false, "rng seq[%d] %s != %s" % [i, x, v["seq"][i]])
			break
	var r2 := Rng.new(42)
	for i in range(v["ints"].size()):
		var n: int = r2.inteiro(1, 20)
		if n != int(v["ints"][i]):
			conferir(false, "rng int[%d] %d != %d" % [i, n, v["ints"][i]])
			break
	var ruins := 0
	for c in v["casos"]:
		var a: Array = []
		var b: Array = []
		for f in c["A"]:
			a.append(Combat.criar_lutador(f["id"], f["nome"], f["stats"], f.get("passiva", "")))
		for f in c["B"]:
			b.append(Combat.criar_lutador(f["id"], f["nome"], f["stats"], f.get("passiva", "")))
		var res: Dictionary = Combat.simular_equipes(a, b, int(c["semente"]), c["opcoes"])
		if Util.canon(res) != Util.canon(c["saida"]):
			ruins += 1
			if ruins == 1:
				print("primeiro caso divergente, semente ", c["semente"])
	conferir(ruins == 0, "combate: %d de %d casos divergentes" % [ruins, v["casos"].size()])
	print("combate: %d casos, %d divergentes" % [v["casos"].size(), ruins])

func _executar_passo(e: Dictionary, p: Dictionary, ctx: Dictionary) -> Dictionary:
	var a: Array = p["args"]
	var erro := ""
	var ret: Variant = null
	match p["acao"]:
		"construir": erro = Game.construir_melhoria(e, a[0])
		"recrutar": erro = Game.recrutar(e, a[0])
		"escolherEstilo": erro = Game.escolher_estilo(e, a[0], a[1])
		"trocarClasse": erro = Game.trocar_classe(e, a[0], a[1])
		"treinar": erro = Game.treinar(e, a[0], a[1])
		"tratar": erro = Game.tratar(e, a[0])
		"comprarMestre": erro = Game.comprar_mestre(e, a[0])
		"comprarItem": erro = Game.comprar_item(e, a[0])
		"equipar": erro = Game.equipar(e, a[0], a[1], "" if a[2] == null else a[2])
		"vender": erro = Game.vender_gladiador(e, a[0])
		"dispensar": erro = Game.dispensar_gladiador(e, a[0])
		"avancarTurno": erro = Game.avancar_turno(e)
		"lutarArena", "lutarCampanha":
			var pl: Dictionary = Game.lutar_arena(e, a[0], a[1]) if p["acao"] == "lutarArena" else Game.lutar_campanha(e, a[0])
			if pl.has("erro"):
				erro = pl["erro"]
			else:
				ret = pl
				ctx["payload"] = pl
		"pularLuta": ret = Game.pular_luta(e, ctx["payload"])
		_: erro = "ACAO DESCONHECIDA " + str(p["acao"])
	return {"erro": erro, "ret": ret}

func teste_jogo() -> void:
	var cenarios: Array = Util.ler_json("res://tests/vetores/jogo.json")
	var total := 0
	var ruins := 0
	for ci in range(cenarios.size()):
		var c: Dictionary = cenarios[ci]
		var e: Dictionary = Game.novo_jogo(int(c["semente"]), c["casa"], c["dif"])
		e["cheats"] = c["cheats"]
		var ctx := {}
		for pi in range(c["passos"].size()):
			var p: Dictionary = c["passos"][pi]
			var r := _executar_passo(e, p, ctx)
			total += 1
			var erro_esp = p["erro"]
			var erro_ok: bool = (erro_esp == null and r["erro"] == "") or (erro_esp != null and erro_esp == r["erro"])
			var ret_s: String = "null" if r["ret"] == null else _canon_ts(r["ret"])
			var est_s: String = _canon_ts(e)
			var est_esp: String = _canon_ts(JSON.parse_string(p["estado"]))
			var ret_esp: String = _canon_ts(JSON.parse_string(p["ret"]))
			if not erro_ok or ret_s != ret_esp or est_s != est_esp:
				ruins += 1
				print("DIVERGE cenario %d passo %d (%s %s)" % [ci, pi, p["acao"], str(p["args"])])
				if not erro_ok:
					print("  erro esperado: ", erro_esp, " obtido: ", r["erro"])
				if ret_s != ret_esp:
					print("  ret: ", _diff(ret_s, ret_esp))
				if est_s != est_esp:
					print("  estado: ", _diff(est_s, est_esp))
				break
	conferir(ruins == 0, "jogo: %d cenarios divergentes" % ruins)
	print("jogo: %d cenarios, %d passos, %d cenarios divergentes" % [cenarios.size(), total, ruins])

func _canon_ts(v: Variant) -> String:
	return Util.canon(v)

func _diff(a: String, b: String) -> String:
	var n := mini(a.length(), b.length())
	var i := 0
	while i < n and a[i] == b[i]:
		i += 1
	var ini := maxi(0, i - 80)
	return "pos %d\n   obtido:   ...%s\n   esperado: ...%s" % [i, a.substr(ini, 200), b.substr(ini, 200)]
