extends SceneTree
## Adiciona ao anims.res as animações Mixamo (mesmo esqueleto do gladiador): copia as trilhas direto.
const ORIG := "res://assets/3d/glad/anims.res"
## Lista acima: animações novas sobre o anims.res atual (rodar com o FBX em PASTA).
const PASTA := "res://assets/3d/_mix_tmp/"
# [arquivo, nome no jogo, loop]
const ITENS := [
	["sword_and_shield_walk", "WalkFrente", true],
	["sword_and_shield_walk_2_", "WalkTras", true],
]

func _init() -> void:
	var lib: AnimationLibrary = load(ORIG).duplicate() if false else ResourceLoader.load(ORIG, "", ResourceLoader.CACHE_MODE_IGNORE)
	var prefixo := "Skeleton3D:"
	for it in ITENS:
		var pk := load(PASTA + it[0] + ".fbx") as PackedScene
		if pk == null:
			push_error("falhou " + it[0])
			continue
		var inst: Node = pk.instantiate()
		root.add_child(inst)
		var ap: AnimationPlayer = inst.find_children("*", "AnimationPlayer", true, false)[0]
		var fonte: Animation = ap.get_animation(ap.get_animation_list()[0])
		var out := Animation.new()
		out.length = fonte.length
		out.loop_mode = Animation.LOOP_LINEAR if it[2] else Animation.LOOP_NONE
		var mapa := {}
		for i in fonte.get_track_count():
			var tipo := fonte.track_get_type(i)
			if tipo != Animation.TYPE_ROTATION_3D and tipo != Animation.TYPE_POSITION_3D:
				continue
			var osso := String(fonte.track_get_path(i).get_concatenated_subnames()).replace(":", "_")
			var nt := out.add_track(tipo)
			out.track_set_path(nt, NodePath(prefixo + osso))
			for k in fonte.track_get_key_count(i):
				var t := fonte.track_get_key_time(i, k)
				var v = fonte.track_get_key_value(i, k)
				if tipo == Animation.TYPE_ROTATION_3D:
					out.rotation_track_insert_key(nt, t, v)
				else:
					# raiz: mantém só o plano do chão, a altura fica no ponto de descanso (sem deslocar o personagem)
					if osso == "mixamorig_Hips" and it[2]:
						v = Vector3(0.0, v.y, 0.0)
					out.position_track_insert_key(nt, t, v)
		lib.add_animation(it[1], out)
		print("OK ", it[1], " trilhas ", out.get_track_count(), " dur ", out.length)
		inst.queue_free()
	var err := ResourceSaver.save(lib, "res://assets/3d/glad/anims_novo.res")
	print("SALVO ", err, " ", lib.get_animation_list())
	quit()
