extends RefCounted
func preparar(arvore: SceneTree) -> void:
	Jogo.novo(Game.lanistas()[0]["id"], "facil")
	Jogo.navegar.emit("jogo")
	await arvore.process_frame
	await arvore.process_frame
	var hud = arvore.root.find_children("*", "Hud", true, false)[0]
	var t: Tutorial = Tutorial.verificar(hud)
	print("TUT ativo=", t.ativo(), " topico=", t._topico, " paginas=", t._paginas.size())
	for i in range(20):
		t._proxima()
		await arvore.process_frame
	print("TUT apos fim ativo=", t.ativo(), " vistos=", Jogo.e["tutorial"]["vistos"], " aba=", hud.aba_atual())
	Jogo.e["melhorias"]["palus"] = true
	Tutorial.verificar(hud)
	print("TUT palus ativo=", t.ativo(), " topico=", t._topico)
	t.fechar()
	TelaConfig.definir_cheat("ouro", true)
	print("CHEATS e=", Jogo.e.get("cheats"), " prefs=", Jogo.prefs["cheats"])
	TelaConfig.definir_cheat("ouro", false)
	Jogo.tutorial_pedido.emit("campanha")
	print("TUT pedido ativo=", t.ativo(), " ", t._topico)
