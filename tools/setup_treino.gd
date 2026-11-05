extends RefCounted
## Abre o treino de combate e simula: o boneco ataca e o jogador faz parry.
func preparar(arvore: SceneTree) -> void:
	Jogo.novo(Game.lanistas()[3]["id"], "medio")
	var e: Dictionary = Jogo.e
	e["tutorial"] = {"vistos": ["tour", "campanha", "treino", "armeiro", "enfermaria", "alojamentos", "refeitorio"]}
	for m in Game.MELHORIAS_LUDUS:
		e["melhorias"][m["id"]] = true
	Jogo.prefs["treinoCombate"] = true
	Jogo.navegar.emit("jogo")
	await arvore.process_frame
	await arvore.process_frame
	Jogo.abrir_aba.emit("ludus")
	await arvore.process_frame
	var ludus: Node = arvore.root.find_children("*", "TelaLudus", true, false)[0]
	var t := TelaTreinoCombate.abrir(ludus, e["gladiadores"][0])
	for i in 6:
		await arvore.process_frame
	var n: TreinoCombate = t._nucleo
	n.b_prox = 0.0
	var modo := OS.get_environment("MODO")
	var saida := OS.get_environment("SAIDA")
	var fr := 0
	for i in 200:
		await arvore.process_frame
		fr += 1
		if modo == "parry" and n.b_estado == "prepara" and n.b_t > 0.5 and not n.defendendo:
			n.defesa(true)
		if modo == "leve" and fr == 20:
			n.ataque_leve()
		if modo == "pesado" and fr == 20:
			n.atacar_pressionar()
		if modo == "pesado" and fr == 50:
			n.atacar_soltar()
		if saida != "" and fr % 12 == 0:
			arvore.root.get_texture().get_image().save_png("%s_%02d.png" % [saida, fr / 12])
