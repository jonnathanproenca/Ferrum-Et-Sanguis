extends SceneTree
## Lista o deslocamento da raiz (quadril) de cada animação de cada FBX em assets/3d/_mix_tmp.
func _init() -> void:
	var dir := DirAccess.open("res://assets/3d/_mix_tmp")
	for f in dir.get_files():
		if not f.ends_with(".fbx.import") and f.ends_with(".fbx") and f != "gladiador_mixamo.fbx":
			var pk := load("res://assets/3d/_mix_tmp/" + f) as PackedScene
			if pk == null:
				print("FALHA ", f)
				continue
			var inst: Node = pk.instantiate()
			root.add_child(inst)
			var ap: AnimationPlayer = inst.find_children("*", "AnimationPlayer", true, false)[0]
			for n in ap.get_animation_list():
				if n == "RESET":
					continue
				var a := ap.get_animation(n)
				var dz := 0.0
				var dx := 0.0
				var zmin := 0.0
				var zmax := 0.0
				for i in a.get_track_count():
					if a.track_get_type(i) == Animation.TYPE_POSITION_3D and String(a.track_get_path(i)).contains("Hips"):
						var k := a.track_get_key_count(i)
						if k > 1:
							var p0: Vector3 = a.track_get_key_value(i, 0)
							var p1: Vector3 = a.track_get_key_value(i, k - 1)
							dz = p1.z - p0.z
							dx = p1.x - p0.x
							for q in k:
								var pz: Vector3 = a.track_get_key_value(i, q)
								zmin = minf(zmin, pz.z - p0.z)
								zmax = maxf(zmax, pz.z - p0.z)
				print("ANIM ", f, " | ", n, " | dur ", snappedf(a.length, 0.01), " | dz ", snappedf(dz, 0.0001), " dx ", snappedf(dx, 0.0001), " zrange ", snappedf(zmin, 0.0001), " ", snappedf(zmax, 0.0001))
			inst.queue_free()
	quit()
