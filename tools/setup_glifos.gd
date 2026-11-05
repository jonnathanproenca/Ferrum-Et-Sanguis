extends RefCounted
func preparar(arvore: SceneTree) -> void:
	var fundo := ColorRect.new()
	fundo.color = Color(0.1, 0.07, 0.06)
	fundo.size = Vector2(1280, 720)
	arvore.root.add_child(fundo)
	var h := HBoxContainer.new()
	h.position = Vector2(40, 40)
	h.add_theme_constant_override("separation", 24)
	arvore.root.add_child(h)
	for t in ["peso", "coroa_fama", "coroa", "aura", "forca"]:
		for tam in [96.0, 22.0]:
			h.add_child(Glifo.novo(t, tam, Color("e8c36a")))
	await arvore.process_frame
