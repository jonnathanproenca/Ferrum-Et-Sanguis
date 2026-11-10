extends RefCounted
## Vistas (0/90/180/270° em Y) de cada capacete para descobrir a frente. +Z do modelo aponta para a câmera em 0°.
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
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = 15.0
	vp.add_child(cam)
	cam.position = Vector3(0, 0, 10)
	var luz := DirectionalLight3D.new()
	luz.rotation_degrees = Vector3(-30, 20, 0)
	vp.add_child(luz)
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color("555555")
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(1, 1, 1)
	env.environment = e
	vp.add_child(env)
	var m := StandardMaterial3D.new()
	m.albedo_color = Color("9a7b3a")
	m.metallic = 0.4
	m.roughness = 0.5
	var lista := ["h_gladiador", "h_metal", "h_espartano", "h_espartano2", "h_grego"]
	var lin := 0
	for nome in lista:
		for k in 4:
			var raiz := Node3D.new()
			vp.add_child(raiz)
			var n: Node3D = (load("res://assets/3d/cap/%s.fbx" % nome) as PackedScene).instantiate()
			raiz.add_child(n)
			var bb := AABB()
			var pr := true
			for mi in n.find_children("*", "MeshInstance3D", true, false):
				(mi as MeshInstance3D).material_override = m
				var a: AABB = (mi as MeshInstance3D).global_transform * (mi as MeshInstance3D).get_aabb()
				bb = a if pr else bb.merge(a)
				pr = false
			var mx := maxf(bb.size.x, maxf(bb.size.y, bb.size.z))
			var f := 2.6 / mx
			n.scale = Vector3.ONE * f
			n.position = -bb.get_center() * f
			raiz.rotation_degrees.y = k * 90.0
			raiz.position = Vector3(-4.5 + k * 3.0, 5.6 - lin * 2.9, 0)
		var l := Label3D.new()
		l.text = nome
		l.pixel_size = 0.012
		l.position = Vector3(-7.4, 5.6 - lin * 2.9, 0)
		vp.add_child(l)
		lin += 1
