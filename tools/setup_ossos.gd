extends RefCounted
## Mostra o doctore por esqueleto grande e salva quadros da chicotada.
func preparar(arvore: SceneTree) -> void:
	var fundo := ColorRect.new()
	fundo.color = Color(0.45, 0.36, 0.26)
	fundo.size = Vector2(1280, 720)
	arvore.root.add_child(fundo)
	var d := DoctoreOssos.new()
	d.escala_base = 0.7
	d.scale = Vector2(0.7, 0.7)
	d.position = Vector2(300, 400)
	arvore.root.add_child(d)
	var saida := OS.get_environment("SAIDA")
	for i in 40:
		await arvore.process_frame
	d.chicotear()
	var n := 0
	for i in range(420):
		await arvore.process_frame
		if i % 3 == 0 and saida != "":
			var img := arvore.root.get_texture().get_image()
			img.save_png("%s_%02d.png" % [saida, n])
			n += 1
