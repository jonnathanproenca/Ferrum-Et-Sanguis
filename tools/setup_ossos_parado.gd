extends RefCounted
func preparar(arvore: SceneTree) -> void:
	var fundo := ColorRect.new()
	fundo.color = Color(0.45, 0.36, 0.26)
	fundo.size = Vector2(1280, 720)
	arvore.root.add_child(fundo)
	var d := DoctoreOssos.new()
	d.escala_base = 0.5
	d.scale = Vector2(1.3, 1.3)
	d.position = Vector2(260, 700)
	d.congelar = true
	d._proximo = 999.0
	arvore.root.add_child(d)
	d._t = float(OS.get_environment("FASE")) if OS.get_environment("FASE") != "" else 0.0
	for i in 5:
		await arvore.process_frame
