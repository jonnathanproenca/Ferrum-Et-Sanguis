extends RefCounted
## Setup de captura da aba Campanha. Variável PASSO (0..9), FIM=1 para a tela final, VIDEO=1 para tocar o vídeo.
func preparar(arvore: SceneTree) -> void:
	Jogo.novo(Game.lanistas()[3]["id"], "medio")
	var passo := int(OS.get_environment("PASSO")) if OS.get_environment("PASSO") != "" else 0
	var fim := OS.get_environment("FIM") == "1"
	Jogo.e["ouro"] = 5000
	Jogo.e["campanha"] = 10 if fim else passo
	if fim:
		Jogo.e["estat"] = {"ouroGanho": 48210, "mortes": 4, "recrutados": 11, "tempoMs": 5400000 + 23 * 60000}
		Jogo.e["vitoriasTotais"] = 31
		Jogo.e["batalhasTotais"] = 36
		Jogo.e["turno"] = 58
		for g in Jogo.e["gladiadores"]:
			g["vitorias"] = 7
	else:
		Jogo.e["vitoriasTotais"] = int(OS.get_environment("VIT")) if OS.get_environment("VIT") != "" else 2
		Jogo.e["gladiadores"][0]["vitorias"] = int(OS.get_environment("GVIT")) if OS.get_environment("GVIT") != "" else 0
	if not fim:
		var n := 2 if Game.passos()[passo].get("formato", 1) == 2 else 1
		Jogo.equipe = Jogo.e["gladiadores"].filter(func(g): return g["vivo"] and not g.get("semEstilo", false)).slice(0, n).map(func(g): return g["id"])
	Jogo.navegar.emit("jogo")
	await arvore.process_frame
	await arvore.process_frame
	Jogo.abrir_aba.emit("campanha")
	await arvore.process_frame
	if OS.get_environment("VIDEO") == "1":
		var t: Node = arvore.root.find_children("*", "TelaCampanha", true, false)[0]
		t._tocar_video(func(): pass)
		for i in range(90):
			await arvore.process_frame
