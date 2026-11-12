extends SceneTree
## Checagem de layout headless do editor "Ajustar peças" (padrão godot-ui-control, Pattern 4).
## Uso: godot --headless -s tools/check_ui_editor.gd   (sai com 1 se algum controle estiver fora do painel ou da tela)
func _initialize() -> void:
	var principal: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(principal)
	for i in 4:
		await process_frame
	var Jogo = root.get_node("/root/Jogo")   # autoloads entram na árvore depois da inicialização do -s
	Jogo.novo(Game.lanistas()[3]["id"], "medio")
	Jogo.navegar.emit("jogo")
	await process_frame
	await process_frame
	Jogo.abrir_aba.emit("ludus")
	await process_frame
	var ludus: Node = root.find_children("*", "TelaLudus", true, false)[0]
	var t = TelaTreinoCombate.abrir(ludus, Jogo.e["gladiadores"][0])
	for i in 6:
		await process_frame
	t._alternar_editor()
	for i in 4:
		await process_frame
	var ed: Control = t._ed
	var tela: Rect2 = t.get_viewport_rect()
	var falhas := 0
	print("PAINEL ", ed.get_global_rect(), " TELA ", tela)
	if not tela.encloses(ed.get_global_rect().grow(0.5)):
		falhas += 1
		push_error("painel fora da tela: %s" % ed.get_global_rect())
	for n in ed.find_children("*", "Control", true, false):
		var c := n as Control
		if not c.is_visible_in_tree():
			continue
		var dentro_rolagem := false
		var p := c.get_parent()
		while p != null and p != ed:
			if p is ScrollContainer and (p as ScrollContainer).vertical_scroll_mode != ScrollContainer.SCROLL_MODE_DISABLED:
				dentro_rolagem = true   # rolagem vertical: só checa a largura
			p = p.get_parent()
		var r := c.get_global_rect()
		var pr := ed.get_global_rect()
		if r.size.x > 0.0 and (r.end.x > pr.end.x + 0.5 or r.position.x < pr.position.x - 0.5):
			falhas += 1
			push_error("controle fora do painel (horizontal): %s %s painel=%s" % [c.get_class(), r, pr])
	print("ALVOS ", _menor_altura_botao(ed), " px (mínimo recomendado para toque: 44)")
	print("RESULTADO layout falhas=%d" % falhas)
	t.queue_free()
	principal.queue_free()
	quit(1 if falhas > 0 else 0)

func _menor_altura_botao(ed: Control) -> float:
	var m := 9999.0
	for b in ed.find_children("*", "Button", true, false):
		if (b as Control).is_visible_in_tree():
			m = minf(m, (b as Control).get_global_rect().size.y)
	return m
