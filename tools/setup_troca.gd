extends RefCounted
## Reproduz a troca de estilo com ludus (novo) e modal abertos.
func g_campeao_off(g: Dictionary) -> void:
	g["campeao"] = false

func preparar(arvore: SceneTree) -> void:
	Jogo.prefs["ludusNovo"] = OS.get_environment("VELHO") == ""
	Jogo.novo(Game.lanistas()[3]["id"], "medio")
	var e: Dictionary = Jogo.e
	e["ouro"] = 5000
	e["energia"] = 20
	for m in Game.MELHORIAS_LUDUS:
		e["melhorias"][m["id"]] = true
	if OS.get_environment("TUT") == "":
		e["tutorial"] = {"vistos": ["tour", "campanha", "treino", "armeiro", "enfermaria", "alojamentos", "refeitorio"]}
	var g: Dictionary = e["gladiadores"][0]
	g_campeao_off(e["gladiadores"][0])
	if OS.get_environment("SEMESTILO") != "":
		g["semEstilo"] = true
	Jogo.navegar.emit("jogo")
	await arvore.process_frame
	await arvore.process_frame
	Jogo.abrir_aba.emit("ludus")
	await arvore.process_frame
	ModalGladiador.abrir(arvore.root.find_children("*", "TelaLudus", true, false)[0], g["id"])
	for _i in 6:
		await arvore.process_frame
	print("classe antes: ", g["classe"])
	var alvo := "Definir estilo (grátis)" if g.get("semEstilo", false) else "Trocar estilo"
	var n := 0
	for b in arvore.root.find_children("*", "Button", true, false):
		if b is Button and (b as Button).text == alvo and b.is_visible_in_tree():
			print("clicando ", alvo, " em ", b.get_path())
			(b as Button).pressed.emit()
			n += 1
			break
	print("botoes: ", n)
	for _i in 30:
		await arvore.process_frame
	print("classe depois: ", g["classe"])
