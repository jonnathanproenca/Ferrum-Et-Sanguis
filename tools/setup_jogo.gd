extends RefCounted
## Exemplo de setup para tools/captura.gd: nova partida (lanista 4, Médio), com ouro e construções, e abre a aba pedida na variável de ambiente ABA.
func preparar(arvore: SceneTree) -> void:
	Jogo.novo(Game.lanistas()[3]["id"], "medio")
	Jogo.e["ouro"] = 5000
	for m in Game.MELHORIAS_LUDUS:
		Jogo.e["melhorias"][m["id"]] = true
	Jogo.navegar.emit("jogo")
	await arvore.process_frame
	await arvore.process_frame
	Jogo.abrir_aba.emit(OS.get_environment("ABA") if OS.get_environment("ABA") != "" else "ludus")
