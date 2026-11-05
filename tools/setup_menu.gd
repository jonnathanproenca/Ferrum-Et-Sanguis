extends RefCounted
## Menu principal. MODO=save (com save), emjogo (aberto de dentro da partida), padrão: sem save. OPCOES=1 abre o painel de opções.
func preparar(arvore: SceneTree) -> void:
	var modo := OS.get_environment("MODO")
	Jogo.apagar_save()
	Jogo.e = {}
	if modo == "save" or modo == "emjogo":
		Jogo.novo(Game.lanistas()[3]["id"], "medio")
		if modo == "save":
			Jogo.e = {}
	if OS.get_environment("CHEAT") == "1":
		Jogo.prefs["cheatLiberado"] = true
	Jogo.navegar.emit("menu")
	await arvore.process_frame
	await arvore.process_frame
	if OS.get_environment("OPCOES") == "1":
		var m = arvore.root.find_children("*", "TelaMenu", true, false)[0]
		m._abrir_opcoes()
