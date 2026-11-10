extends SceneTree
## Cria "Esquiva" a partir de Sword_Dash: só a fase do pulo (0..CORTE s), sem deslocamento horizontal da raiz
## (a distância percorrida é controlada pelo jogo).
const CORTE := 0.9

func _init() -> void:
	var lib: AnimationLibrary = ResourceLoader.load("res://assets/3d/glad/anims.res", "", ResourceLoader.CACHE_MODE_IGNORE)
	var a: Animation = lib.get_animation("Sword_Dash").duplicate()
	a.length = CORTE
	a.loop_mode = Animation.LOOP_NONE
	for i in a.get_track_count():
		var n := a.track_get_key_count(i)
		for k in range(n - 1, -1, -1):
			if a.track_get_key_time(i, k) > CORTE:
				a.track_remove_key(i, k)
		if a.track_get_type(i) == Animation.TYPE_POSITION_3D and String(a.track_get_path(i)).contains("Hips"):
			var p0: Vector3 = a.track_get_key_value(i, 0)
			for k in a.track_get_key_count(i):
				var p: Vector3 = a.track_get_key_value(i, k)
				a.track_set_key_value(i, k, Vector3(p0.x, p.y, p0.z))
	if lib.has_animation("Esquiva"):
		lib.remove_animation("Esquiva")
	lib.add_animation("Esquiva", a)
	print("SALVO ", ResourceSaver.save(lib, "res://assets/3d/glad/anims.res"))
	quit()
