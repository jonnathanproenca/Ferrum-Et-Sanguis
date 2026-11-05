extends RefCounted
## Tutorial sobre o HUD. PAG=n avança n páginas. Instancia o Tutorial como o Hud fará.
func preparar(arvore: SceneTree) -> void:
	Jogo.novo(Game.lanistas()[3]["id"], "medio")
	Jogo.navegar.emit("jogo")
	await arvore.process_frame
	await arvore.process_frame
	var hud = arvore.root.find_children("*", "Hud", true, false)[0]
	var t: Tutorial = Tutorial.verificar(hud)
	await arvore.process_frame
	for i in range(int(OS.get_environment("PAG"))):
		t._proxima()
		await arvore.process_frame
