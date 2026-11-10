extends RefCounted
## Grade com os acessórios 3D (ponta do eixo mais longo marcada por esfera vermelha no +eixo).
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
	cam.size = 14.0
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
	var lista := ["res://assets/3d/gladio.glb"]
	var d := DirAccess.open("res://assets/3d/acc")
	for f in d.get_files():
		if f.ends_with(".fbx"):
			lista.append("res://assets/3d/acc/" + f)
	var i := 0
	for p in lista:
		var n: Node3D = (load(p) as PackedScene).instantiate()
		vp.add_child(n)
		var bb := AABB()
		var pr := true
		for mi in n.find_children("*", "MeshInstance3D", true, false):
			var a: AABB = (mi as MeshInstance3D).global_transform * (mi as MeshInstance3D).get_aabb()
			bb = a if pr else bb.merge(a)
			pr = false
		var mx := maxf(bb.size.x, maxf(bb.size.y, bb.size.z))
		var k := 3.0 / mx
		n.scale = Vector3.ONE * k
		var c := bb.get_center() * k
		var col := i % 5
		var lin := i / 5
		n.position = Vector3(-6.0 + col * 3.0, 4.0 - lin * 3.4, 0) - c
		# marca eixos: vermelho +X, verde +Y, azul +Z a partir do centro
		for ax in [[Vector3.RIGHT, Color.RED], [Vector3.UP, Color.GREEN], [Vector3.BACK, Color.BLUE]]:
			var s := MeshInstance3D.new()
			var sm := SphereMesh.new()
			sm.radius = 0.1
			sm.height = 0.2
			s.mesh = sm
			var m := StandardMaterial3D.new()
			m.albedo_color = ax[1]
			m.shaded = false if false else true
			s.material_override = m
			s.position = Vector3(-6.0 + col * 3.0, 4.0 - lin * 3.4, 0) + ax[0] * 1.7
			vp.add_child(s)
		var l := Label3D.new()
		l.text = p.get_file().get_basename()
		l.pixel_size = 0.012
		l.position = Vector3(-6.0 + col * 3.0, 4.0 - lin * 3.4 - 1.6, 0)
		vp.add_child(l)
		i += 1
