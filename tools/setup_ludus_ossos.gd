extends RefCounted
func preparar(arvore: SceneTree) -> void:
	Jogo.prefs["doctoreOssos"] = true
	Jogo.prefs["ludusNovo"] = true
	var s = load("res://tools/setup_doc.gd").new()
	await s.preparar(arvore)
