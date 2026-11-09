extends SceneTree
## Retarget das animações Quaternius (UAL) para o esqueleto Mixamo do gladiador. Saída: assets/3d/glad/anims.res
const LISTA := ["Sword_Idle", "Idle", "Walk", "Sword_Block", "Idle_Shield", "Sword_Attack", "Sword_Regular_A", "Sword_Regular_B", "Sword_Regular_C", "Sword_Regular_A_Rec", "Sword_Regular_B_Rec", "Hit_Chest", "Sword_Dash", "Shield_OneShot", "Idle_Shield_Break", "Roll", "Sword_Heavy_Combo", "Shield_Dash"]
const FPS := 30.0
## Abdução extra dos braços (graus): o corpo do gladiador é mais largo que o manequim e os braços entravam no tronco.
var ABDUCAO := float(OS.get_environment("ABDUCAO")) if OS.get_environment("ABDUCAO") != "" else 14.0

func _mapa() -> Dictionary:
	var m := {"pelvis": "Hips", "spine_01": "Spine", "spine_02": "Spine1", "spine_03": "Spine2", "neck_01": "Neck", "Head": "Head"}
	for l in [["l", "Left"], ["r", "Right"]]:
		var s: String = l[0]
		var L: String = l[1]
		m["clavicle_" + s] = L + "Shoulder"
		m["upperarm_" + s] = L + "Arm"
		m["lowerarm_" + s] = L + "ForeArm"
		m["hand_" + s] = L + "Hand"
		m["thigh_" + s] = L + "UpLeg"
		m["calf_" + s] = L + "Leg"
		m["foot_" + s] = L + "Foot"
		m["ball_" + s] = L + "ToeBase"
		for dedo in [["thumb", "Thumb"], ["index", "Index"], ["middle", "Middle"], ["ring", "Ring"], ["pinky", "Pinky"]]:
			for i in 3:
				m["%s_0%d_%s" % [dedo[0], i + 1, s]] = "%sHand%s%d" % [L, dedo[1], i + 1]
	return m


func _init() -> void:
	var tinst: Node = (load("res://assets/3d/glad/gladiador.fbx") as PackedScene).instantiate()
	root.add_child(tinst)
	var tsk: Skeleton3D = tinst.find_children("*", "Skeleton3D", true, false)[0]
	var sinst: Node = (load("res://assets/3d/UAL1_Standard.glb") as PackedScene).instantiate()
	root.add_child(sinst)
	var ssk: Skeleton3D = sinst.find_children("*", "Skeleton3D", true, false)[0]
	var anims := {}
	for caminho in ["res://assets/3d/UAL1_Standard.glb", "res://assets/3d/UAL2_Standard.glb"]:
		var inst: Node = (load(caminho) as PackedScene).instantiate()
		var ap: AnimationPlayer = inst.find_children("*", "AnimationPlayer", true, false)[0]
		for n in ap.get_animation_list():
			if not anims.has(n):
				anims[n] = ap.get_animation(n)
	var mapa := _mapa()
	var s_n := ssk.get_bone_count()
	var t_n := tsk.get_bone_count()
	var s_rest_g: Array = []
	for i in s_n:
		s_rest_g.append(ssk.get_bone_global_rest(i).basis.get_rotation_quaternion())
	var t_rest_g: Array = []
	for i in t_n:
		t_rest_g.append(tsk.get_bone_global_rest(i).basis.get_rotation_quaternion())
	var s_para_t := {}
	for sb in mapa:
		var si := ssk.find_bone(sb)
		var ti := tsk.find_bone("mixamorig_" + mapa[sb])
		if si < 0 or ti < 0:
			push_error("sem osso: %s -> %s" % [sb, mapa[sb]])
			continue
		s_para_t[ti] = si
	var razao: float = tsk.get_bone_global_rest(tsk.find_bone("mixamorig_Hips")).origin.y / ssk.get_bone_global_rest(ssk.find_bone("pelvis")).origin.y
	var lib := AnimationLibrary.new()
	for nome in LISTA:
		if not anims.has(nome):
			push_warning("sem anim " + nome)
			continue
		var a: Animation = anims[nome]
		# faixa por osso de origem
		var rot_tr := {}
		var pos_tr := {}
		for i in a.get_track_count():
			var osso := String(a.track_get_path(i).get_concatenated_subnames())
			if a.track_get_type(i) == Animation.TYPE_ROTATION_3D:
				rot_tr[osso] = i
			elif a.track_get_type(i) == Animation.TYPE_POSITION_3D:
				pos_tr[osso] = i
		var out := Animation.new()
		out.length = a.length
		out.loop_mode = a.loop_mode
		var faixa_rot := {}
		for ti in t_n:
			var tr := out.add_track(Animation.TYPE_ROTATION_3D)
			out.track_set_path(tr, NodePath("Skeleton3D:" + tsk.get_bone_name(ti)))
			faixa_rot[ti] = tr
		var tr_pos := out.add_track(Animation.TYPE_POSITION_3D)
		var ti_hips := tsk.find_bone("mixamorig_Hips")
		out.track_set_path(tr_pos, NodePath("Skeleton3D:mixamorig_Hips"))
		var passos := int(ceil(a.length * FPS))
		for k in range(passos + 1):
			var t := minf(k / FPS, a.length)
			# globais de origem
			var sg: Array = []
			sg.resize(s_n)
			for i in s_n:
				var nm := ssk.get_bone_name(i)
				var q: Quaternion = ssk.get_bone_rest(i).basis.get_rotation_quaternion()
				if rot_tr.has(nm):
					q = a.rotation_track_interpolate(rot_tr[nm], t)
				var p := ssk.get_bone_parent(i)
				sg[i] = q if p < 0 else (sg[p] as Quaternion) * q
			var tg: Array = []
			tg.resize(t_n)
			for ti in t_n:
				var p := tsk.get_bone_parent(ti)
				var g: Quaternion
				if s_para_t.has(ti):
					var si: int = s_para_t[ti]
					g = (sg[si] as Quaternion) * (s_rest_g[si] as Quaternion).inverse() * (t_rest_g[ti] as Quaternion)
				else:
					var rl: Quaternion = tsk.get_bone_rest(ti).basis.get_rotation_quaternion()
					g = rl if p < 0 else (tg[p] as Quaternion) * rl
				var nome_t := tsk.get_bone_name(ti)
				if nome_t.contains("LeftArm") or nome_t.contains("LeftForeArm") or nome_t.contains("LeftHand"):
					g = Quaternion(Vector3(0, 0, 1), deg_to_rad(ABDUCAO)) * g
				elif nome_t.contains("RightArm") or nome_t.contains("RightForeArm") or nome_t.contains("RightHand"):
					g = Quaternion(Vector3(0, 0, 1), deg_to_rad(-ABDUCAO)) * g
				tg[ti] = g
				var loc: Quaternion = g if p < 0 else (tg[p] as Quaternion).inverse() * g
				out.rotation_track_insert_key(faixa_rot[ti], t, loc.normalized())
			var pelvis_pos: Vector3 = ssk.get_bone_rest(ssk.find_bone("pelvis")).origin
			if pos_tr.has("pelvis"):
				pelvis_pos = a.position_track_interpolate(pos_tr["pelvis"], t)
			var rest_pos: Vector3 = ssk.get_bone_rest(ssk.find_bone("pelvis")).origin
			var base: Vector3 = tsk.get_bone_rest(ti_hips).origin
			# mantém o plano do chão (x,z em relação ao descanso), altura proporcional
			var d := (pelvis_pos - rest_pos) * razao
			out.position_track_insert_key(tr_pos, t, base + d)
		lib.add_animation(nome, out)
	# animações Mixamo originais (já no esqueleto do gladiador)
	for par in [["morte", "Morte"], ["vitoria", "Vitoria"]]:
		var mi: Node = (load("res://assets/3d/glad/%s.fbx" % par[0]) as PackedScene).instantiate()
		var ap2: AnimationPlayer = mi.find_children("*", "AnimationPlayer", true, false)[0]
		var an := ap2.get_animation(ap2.get_animation_list()[0]).duplicate() as Animation
		lib.add_animation(par[1], an)
		for i in an.get_track_count():
			if i < 2:
				print("MIXPATH ", par[1], " ", an.track_get_path(i))
	print("RAZAO ", razao)
	var err := ResourceSaver.save(lib, "res://assets/3d/glad/anims.res")
	print("SALVO ", err, " ", lib.get_animation_list())
	quit()
