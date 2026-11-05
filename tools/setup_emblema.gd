extends RefCounted
## Renderiza só o emblema do menu (para gerar o favicon). Use com resolução 512x512.
func preparar(arvore: SceneTree) -> void:
	var cam := CanvasLayer.new()
	cam.layer = 500
	var fundo := ColorRect.new()
	fundo.color = Color(1, 0, 1)
	fundo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	cam.add_child(fundo)
	var em := TelaMenu.Emblema.new(500.0)
	em.position = Vector2(6, 6)
	cam.add_child(em)
	arvore.root.add_child(cam)
	await arvore.process_frame
