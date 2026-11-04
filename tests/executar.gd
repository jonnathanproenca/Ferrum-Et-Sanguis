extends SceneTree
## Roda todos os testes de paridade com o jogo em TypeScript: godot --headless --path . -s tests/executar.gd

var falhas := 0

func _init() -> void:
	teste_combate()
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
