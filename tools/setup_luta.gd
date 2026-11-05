extends RefCounted
## Abre a tela de luta direto. Variáveis de ambiente: ARENA (pompeia|capua|coliseu|poco), N (1|2), CHEAT (vencer), DERROTA=1, FIM=1, ACAO=<frames até ...>
func preparar(arvore: SceneTree) -> void:
	Jogo.novo(Game.lanistas()[3]["id"], "medio")
	Jogo.e["ouro"] = 5000
	Jogo.e["batalhasTotais"] = 40
	for m in Game.MELHORIAS_LUDUS:
		Jogo.e["melhorias"][m["id"]] = true
	if OS.get_environment("CHEAT") != "":
		Jogo.e["cheats"] = {OS.get_environment("CHEAT"): true}
	if int(OS.get_environment("N")) == 2 and Jogo.e["gladiadores"].size() < 2:
		var erro := Game.recrutar(Jogo.e, Jogo.e["mercado"][0]["id"])
		if erro != "":
			push_error(erro)
	var cls := ["murmilo", "retiario", "tracio", "samnita"]
	var k := 0
	for g in Jogo.e["gladiadores"]:
		if g.get("semEstilo", false):
			Game.escolher_estilo(Jogo.e, g["id"], cls[k % 4])
			k += 1
	var n := int(OS.get_environment("N")) if OS.get_environment("N") != "" else 1
	var vivos: Array = Jogo.e["gladiadores"].filter(func(g): return g["vivo"] and not g.get("semEstilo", false))
	var ids: Array = vivos.slice(0, n).map(func(g): return g["id"])
	var arena := OS.get_environment("ARENA") if OS.get_environment("ARENA") != "" else "pompeia"
	var payload: Dictionary = Game.lutar_arena(Jogo.e, ids, arena)
	if payload.has("erro"):
		push_error(payload["erro"])
		return
	if OS.get_environment("DERROTA") != "":
		payload["vitoriaA"] = false
		payload["ouro"] = 0
		payload["moedas"] = 0
	Jogo.navegar.emit("jogo")
	await arvore.process_frame
	await arvore.process_frame
	var hud: Node = arvore.root.find_children("*", "Hud", true, false)[0]
	var t := TelaLuta.abrir(hud, payload, func(): print("ao_fim"), func(): print("ao_desistir"), func() -> int: return 3)
	if OS.get_environment("VEL") != "":
		t._alternar_vel()
	if OS.get_environment("FIM") != "":
		await arvore.create_timer(0.5).timeout
		t._encerrado = true
		t._terminar()
	if OS.get_environment("TS") != "":
		Engine.time_scale = float(OS.get_environment("TS"))
		while is_instance_valid(t) and not t._fim_mostrado:
			await arvore.process_frame
		print("fim mostrado")
		await arvore.create_timer(4.0).timeout
		if OS.get_environment("CLICAR") != "":
			t._fechar()
			await arvore.process_frame
			await arvore.process_frame
			print("fechou, camadas restantes: ", arvore.root.find_children("*", "TelaLuta", true, false).size())
