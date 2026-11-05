extends RefCounted
func preparar(arvore: SceneTree) -> void:
	Jogo.navegar.emit("selecao")
	for _i in 6:
		await arvore.process_frame
	var t: Node = arvore.root.find_children("*", "TelaSelecao", true, false)[0]
	var itens: Array = t._itens
	var c0: Control = itens[0]["raiz"]
	var c2: Control = itens[2]["raiz"]
	var p0: Vector2 = c0.get_global_rect().get_center()
	var p2: Vector2 = c2.get_global_rect().get_center()
	var ev := InputEventMouseButton.new()
	ev.button_index = MOUSE_BUTTON_LEFT; ev.pressed = true; ev.position = p0; ev.global_position = p0
	Input.parse_input_event(ev)
	await arvore.process_frame
	var mv := InputEventMouseMotion.new()
	mv.position = p2; mv.global_position = p2; mv.relative = p2 - p0; mv.button_mask = MOUSE_BUTTON_MASK_LEFT
	Input.parse_input_event(mv)
	await arvore.process_frame
	print("sel durante arrasto: ", t._sel, " hovers: ", itens.map(func(x): return x["hover"]))
	var up := InputEventMouseButton.new()
	up.button_index = MOUSE_BUTTON_LEFT; up.pressed = false; up.position = p2; up.global_position = p2
	Input.parse_input_event(up)
	for _i in 10:
		await arvore.process_frame
	print("sel final: ", t._sel, " hovers: ", itens.map(func(x): return x["hover"]))
