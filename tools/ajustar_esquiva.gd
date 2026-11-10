extends SceneTree
## Encurta o pulo da esquiva: reduz o deslocamento horizontal do quadril de Sword_Dash.
const FATOR := 0.4

func _init() -> void:
	var lib: AnimationLibrary = ResourceLoader.load("res://assets/3d/glad/anims_novo.res", "", ResourceLoader.CACHE_MODE_IGNORE)
	var a: Animation = lib.get_animation("Sword_Dash")
	for i in a.get_track_count():
		if a.track_get_type(i) == Animation.TYPE_POSITION_3D and String(a.track_get_path(i)).contains("Hips"):
			var p0: Vector3 = a.track_get_key_value(i, 0)
			for k in a.track_get_key_count(i):
				var p: Vector3 = a.track_get_key_value(i, k)
				var n := Vector3(p0.x + (p.x - p0.x) * FATOR, p.y, p0.z + (p.z - p0.z) * FATOR)
				a.track_set_key_value(i, k, n)
			print("ajustado, dz final ", a.track_get_key_value(i, a.track_get_key_count(i) - 1).z - p0.z)
	var err := ResourceSaver.save(lib, "res://assets/3d/glad/anims_novo.res")
	print("SALVO ", err)
	quit()
