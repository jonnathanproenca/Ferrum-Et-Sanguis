extends RefCounted
## Aba Opções (CHEAT=1 libera os cheats; MODAL=reiniciar abre a confirmação).
func preparar(arvore: SceneTree) -> void:
	if OS.get_environment("CHEAT") == "1":
		Jogo.prefs["cheatLiberado"] = true
	Jogo.novo(Game.lanistas()[3]["id"], "medio")
	Jogo.e["tutorial"] = {"vistos": Tutorial.todos_ids()}
	Jogo.navegar.emit("jogo")
	await arvore.process_frame
	await arvore.process_frame
	Jogo.abrir_aba.emit("config")
	if OS.get_environment("MODAL") == "reiniciar":
		await arvore.process_frame
		arvore.root.find_children("*", "TelaConfig", true, false)[0]._pedir_reinicio()
