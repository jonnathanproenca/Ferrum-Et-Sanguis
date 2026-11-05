extends RefCounted
## Setup de teste da cena do ludus. Variável de ambiente CENARIO: crua | completo | compra | compra_armaria | feridos
func preparar(arvore: SceneTree) -> void:
	var cen := OS.get_environment("CENARIO") if OS.get_environment("CENARIO") != "" else "completo"
	Jogo.novo(Game.lanistas()[3]["id"], "medio")
	Jogo.e["ouro"] = 5000
	for m in Game.MELHORIAS_LUDUS:
		Jogo.e["melhorias"][m["id"]] = cen not in ["crua"]
	if cen in ["compra", "compra_armaria"]:
		Jogo.e["melhorias"]["enfermaria"] = false
		Jogo.e["melhorias"]["armaria"] = false
	if cen in ["completo", "feridos"]:
		for g in Jogo.e["gladiadores"]:
			g["efeitos"] = [{"tipo": "sangramento", "severidade": 1}]
	Jogo.navegar.emit("jogo")
	await arvore.process_frame
	await arvore.process_frame
	# anfitrião de teste: cobre a janela com a cena (a aba Ludus real ainda é um stub)
	var cl := CanvasLayer.new()
	cl.layer = 50
	arvore.root.add_child(cl)
	var bg := ColorRect.new()
	bg.color = Tema.BG
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	cl.add_child(bg)
	var sc := ScrollContainer.new()
	sc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	cl.add_child(sc)
	var vb := VBoxContainer.new()
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(vb)
	vb.add_child(CenaLudus.new())
	vb.add_child(Tema.rotulo("Gladiadores abaixo da cena (teste)", 20))
	Jogo.abrir_aba.connect(func(a): print("abrir_aba: ", a))
	await arvore.create_timer(0.5).timeout
	if cen == "compra":
		Jogo.e["melhorias"]["enfermaria"] = true
		Jogo.construiu.emit("enfermaria")
		Jogo.mudou.emit()
		await arvore.create_timer(1.55).timeout
	elif cen == "compra_armaria":
		Jogo.e["melhorias"]["armaria"] = true
		Jogo.construiu.emit("armaria")
		Jogo.mudou.emit()
		await arvore.create_timer(1.0).timeout
