extends RefCounted
func preparar(arvore: SceneTree) -> void:
	Jogo.prefs["escalaUi"] = 1.4
	Jogo.aplicar_escala()
	var s = load("res://tools/" + OS.get_environment("SETUP") + ".gd").new()
	await s.preparar(arvore)
