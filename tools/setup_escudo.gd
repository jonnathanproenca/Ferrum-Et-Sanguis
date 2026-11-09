extends RefCounted
func preparar(arvore: SceneTree) -> void:
	var cl := CanvasLayer.new()
	cl.layer = 100
	arvore.root.add_child(cl)
	var vp := SubViewport.new()
	vp.size = Vector2i(1280, 720)
	vp.own_world_3d = true
	cl.add_child(vp)
	var tr := TextureRect.new()
	tr.texture = vp.get_texture()
	cl.add_child(tr)
	var cam := Camera3D.new()
	vp.add_child(cam)
	cam.position = Vector3(0, 0, 3)
	var luz := DirectionalLight3D.new()
	vp.add_child(luz)
	var n: Node3D = (load("res://assets/3d/escudo_redondo.fbx") as PackedScene).instantiate()
	vp.add_child(n)
	n.scale = Vector3.ONE * 0.8
	n.rotation_degrees.y = float(OS.get_environment("RY"))
	await arvore.process_frame
