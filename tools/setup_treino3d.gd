extends RefCounted
## Treino em 3D (teste). Env: MODO (leve|pesado|parry|esquiva|andar), FRAMES até a captura.
func preparar(arvore: SceneTree) -> void:
	Jogo.novo(Game.lanistas()[3]["id"], "medio")
	var e: Dictionary = Jogo.e
	e["tutorial"] = {"vistos": ["tour", "campanha", "treino", "armeiro", "enfermaria", "alojamentos", "refeitorio"]}
	Jogo.navegar.emit("jogo")
	await arvore.process_frame
	await arvore.process_frame
	Jogo.abrir_aba.emit("ludus")
	await arvore.process_frame
	var ludus: Node = arvore.root.find_children("*", "TelaLudus", true, false)[0]
	var t := TelaTreinoCombate.abrir(ludus, e["gladiadores"][0])
	for i in 6:
		await arvore.process_frame
	t._alternar_3d()
	var n: TreinoCombate = t._nucleo
	n.b_prox = 99.0
	var modo := OS.get_environment("MODO")
	var alvo := int(OS.get_environment("FRAMES")) if OS.get_environment("FRAMES") != "" else 40
	for i in alvo:
		await arvore.process_frame
		if modo == "leve" and i == 10: n.ataque_leve()
		if modo == "pesado" and i == 10: n.ataque_pesado()
		if modo == "esquiva" and i == 10: n.esquiva()
		if modo == "andar": n.definir_direcao(1)
		if modo == "parry" and i == 10: n.defesa(true)
