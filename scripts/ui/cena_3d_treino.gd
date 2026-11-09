class_name Cena3DTreino
extends SubViewportContainer
## Versão 3D (teste) da mini-arena de treino: manequim Quaternius com animações de espada, gládio e escudo nas mãos,
## boneco de treino. Só desenha: quem decide golpe, parry e esquiva continua em TreinoCombate.

const BONECA_GLB := "res://assets/3d/UAL1_Standard.glb"
const ANIMS_EXTRA := "res://assets/3d/UAL2_Standard.glb"
const GLADIO := "res://assets/3d/gladio.glb"
const ESCUDO := "res://assets/3d/escudo_redondo.fbx"
const GLAD_FBX := "res://assets/3d/glad/gladiador.scn"
const GLAD_TEX := "res://assets/3d/glad/gladiador_0.png"
const GLAD_MALHA := "res://assets/3d/glad/malha.res"
const GLAD_ANIMS := "res://assets/3d/glad/anims.res"
const FUNDO := "res://assets/arenas/novo/pompeia_vazia.jpg"
const MUNDO_POR_PX := 1.0 / 150.0

var _vp: SubViewport
var _jog: Node3D
var _bon: Node3D
var _ap_j: AnimationPlayer
var _ap_b: AnimationPlayer
var _bon_mats: Array = []
var _x0 := 575.0
var _fixo_j := ""            ## animação que não deve ser interrompida pelo andar
var _atual_j := ""
var _defendendo := false


var _cam: Camera3D
var _fundo: Sprite3D


func _init() -> void:
	stretch = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _ready() -> void:
	_vp = SubViewport.new()
	_vp.size = Vector2i(1280, 720)
	_vp.own_world_3d = true
	_vp.msaa_3d = Viewport.MSAA_2X
	add_child(_vp)
	_montar_mundo()
	var animas := {}
	_jog = _criar_personagem(animas, Color(0.93, 0.85, 0.72), true)
	_bon = _criar_personagem(animas, Color(0.85, 0.65, 0.45), false)
	var giro := float(OS.get_environment('GIRO')) if OS.get_environment('GIRO') != '' else 90.0
	_jog.rotation_degrees.y = giro
	_bon.rotation_degrees.y = giro
	_bon.scale.z = -1.0  # espelhado em X do mundo (após o giro): olha p/ esquerda e mantém a espada do lado da câmera
	_ap_j = _achar_ap(_jog)
	_ap_b = _achar_ap(_bon)
	_ap_j.animation_finished.connect(func(n): _fim_anim_j(String(n)))
	_tocar(_ap_j, "Sword_Idle", 0.0)
	_tocar(_ap_b, "Idle", 0.0)
	if OS.get_environment("DBG") != "":
		print("FACE_J ", _jog.global_transform.basis * Vector3(0, 0, 1), " pos ", _jog.position, " BON ", _bon.global_transform.basis * Vector3(0, 0, 1), _bon.position)
	if OS.get_environment("ANIM") != "":
		_ap_j.play(OS.get_environment("ANIM"))
		_ap_j.seek(float(OS.get_environment("ANIMT")), true)
		_ap_j.speed_scale = 0.0
	if OS.get_environment("ANIMB") != "":
		_ap_b.play(OS.get_environment("ANIMB"))
		_ap_b.seek(float(OS.get_environment("ANIMT")), true)
		_ap_b.speed_scale = 0.0


func _montar_mundo() -> void:
	var cam := Camera3D.new()
	cam.fov = 34.0
	cam.position = Vector3(0.95, 1.35, 7.0)
	if OS.get_environment("CAMPOS") != "":
		var cp := OS.get_environment("CAMPOS").split(",")
		cam.position = Vector3(float(cp[0]), float(cp[1]), float(cp[2]))
	_vp.add_child(cam)
	_cam = cam
	cam.look_at(Vector3(0.95, 0.95, 0.0) if OS.get_environment("CAMPOS") == "" else Vector3(_ENV_ALVO(), 0.95, 0.0), Vector3.UP)
	var chao := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(60, 24)
	chao.mesh = pm
	chao.position = Vector3(0, 0, -4.0)
	var cm := StandardMaterial3D.new()
	cm.albedo_color = Color("5a4630")
	cm.roughness = 1.0
	chao.material_override = cm
	_vp.add_child(chao)
	var tex := load(FUNDO) as Texture2D
	if tex != null:
		var s := Sprite3D.new()
		s.texture = tex
		s.shaded = false
		s.pixel_size = 0.0138
		s.position = Vector3(0, 4.2, -9.0)
		_fundo = s
		_vp.add_child(s)
	var sol := DirectionalLight3D.new()
	sol.rotation_degrees = Vector3(-48, 35, 0)
	sol.light_energy = 0.8
	sol.light_color = Color("ffe2b0")
	sol.shadow_enabled = true
	_vp.add_child(sol)
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color("3a2a20")
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color("b9a58a")
	e.ambient_light_energy = 0.7
	env.environment = e
	_vp.add_child(env)


func _achar_ap(n: Node) -> AnimationPlayer:
	return n.find_children("*", "AnimationPlayer", true, false)[0] as AnimationPlayer


## Animações do pacote 2 (mesmo esqueleto) entram na biblioteca do pacote 1.
func _carregar_animacoes() -> Dictionary:
	var out := {}
	for caminho in [BONECA_GLB, ANIMS_EXTRA]:
		var inst: Node = (load(caminho) as PackedScene).instantiate()
		var ap := _achar_ap(inst)
		for n in ap.get_animation_list():
			if not out.has(n):
				out[n] = ap.get_animation(n)
		inst.queue_free()
	return out


## Gladiador (modelo Meshy + rig Mixamo, animações Quaternius reaproveitadas por retarget).
func _criar_gladiador(cor: Color, com_equip: bool) -> Node3D:
	var raiz := Node3D.new()
	_vp.add_child(raiz)
	var inst: Node3D = (load(GLAD_FBX) as PackedScene).instantiate()
	inst.scale = Vector3.ONE * 94.7
	raiz.add_child(inst)
	var ap := _achar_ap(inst)
	var lib := ap.get_animation_library("") as AnimationLibrary
	var nossas := load(GLAD_ANIMS) as AnimationLibrary
	for n in nossas.get_animation_list():
		lib.add_animation(n, nossas.get_animation(n))
	var m := StandardMaterial3D.new()
	m.albedo_texture = load(GLAD_TEX)
	m.albedo_color = cor
	m.roughness = 0.8
	for mi in inst.find_children("*", "MeshInstance3D", true, false):
		(mi as MeshInstance3D).material_override = m
		(mi as MeshInstance3D).mesh = load(GLAD_MALHA)
	if not com_equip:
		_bon_mats.append(m)
	var sk := inst.find_children("*", "Skeleton3D", true, false)[0] as Skeleton3D
	# Armas: orientação desejada em pose T (mundo) convertida para o osso de descanso do Mixamo.
	var r_dir := sk.get_bone_global_rest(sk.find_bone("mixamorig_RightHand")).basis.orthonormalized()
	var r_esq := sk.get_bone_global_rest(sk.find_bone("mixamorig_LeftHand")).basis.orthonormalized()
	var w_esp := Basis(Vector3(0, 1, 0), Vector3(0, 0, 1), Vector3(1, 0, 0))
	var o_esp := Vector3(-0.12, 0, -0.04) + _rot_env("GPOS")
	_anexar_b(sk, "mixamorig_RightHand", GLADIO, r_dir.inverse() * w_esp, r_dir.inverse() * o_esp * 0.01, 0.01)
	var w_esc := Basis.from_euler(Vector3(deg_to_rad(_rot_env("SEUL").x), deg_to_rad(_rot_env("SEUL").y), deg_to_rad(_rot_env("SEUL").z)))
	var o_esc := Vector3(-0.10, 0, 0.05) + _rot_env("SPOS")
	var esc := Node3D.new()
	sk.add_child(esc)
	var ps_esc := load(ESCUDO) as PackedScene
	if ps_esc != null:
		esc.add_child(ps_esc.instantiate())
	var mod := EscudoMod.new()
	mod.escudo = esc
	mod.ap = ap
	mod.jogador = com_equip
	sk.add_child(mod)
	if OS.get_environment("DBG") != "":
		_dbg_esq(sk)
	return raiz


func _criar_personagem(animas: Dictionary, cor: Color, com_equip: bool) -> Node3D:
	if OS.get_environment("MODELO") != "manequim":
		return _criar_gladiador(Color(1, 1, 1) if com_equip else Color(1.0, 0.78, 0.62), com_equip)
	var inst: Node3D = (load(BONECA_GLB) as PackedScene).instantiate()
	_vp.add_child(inst)
	var ap := _achar_ap(inst)
	var lib := ap.get_animation_library("") as AnimationLibrary
	for n in animas:
		if not lib.has_animation(n):
			lib.add_animation(n, animas[n])
	for mi in inst.find_children("*", "MeshInstance3D", true, false):
		var m := StandardMaterial3D.new()
		m.albedo_color = cor if com_equip else cor
		m.roughness = 0.85
		(mi as MeshInstance3D).material_override = m
		if not com_equip:
			_bon_mats.append(m)
	var sk := inst.find_children("*", "Skeleton3D", true, false)[0] as Skeleton3D
	_visual(inst, sk, cor)
	_anexar(sk, "hand_r", GLADIO, _rot_env("GPOS"), _rot_env("GROT"), 1.0)
	var sp := _rot_env("SPOS")
	var sr := _rot_env("SROT")
	if not com_equip:
		sp.z = -sp.z
		sr.y = -sr.y
	_anexar(sk, "hand_l", ESCUDO, sp, sr, 0.26)
	return inst


func _rot_env(nome: String) -> Vector3:
	var t := OS.get_environment(nome)
	if t == "":
		match nome:
			"GROT":
				return Vector3(90, 0, 0)
			"GPOS", "SPOS", "SEUL":
				return Vector3.ZERO
		return Vector3(0, 90, 0)
	var p := t.split(",")
	return Vector3(float(p[0]), float(p[1]), float(p[2]))


func _anexar_b(sk: Skeleton3D, osso: String, caminho: String, base: Basis, pos: Vector3, esc: float) -> void:
	var ba := BoneAttachment3D.new()
	ba.bone_name = osso
	sk.add_child(ba)
	var ps := load(caminho) as PackedScene
	if ps == null:
		return
	var n: Node3D = ps.instantiate()
	n.transform = Transform3D(base * Basis.from_scale(Vector3.ONE * esc), pos)
	ba.add_child(n)


func _anexar(sk: Skeleton3D, osso: String, caminho: String, pos: Vector3, rot: Vector3, esc: float) -> void:
	var ba := BoneAttachment3D.new()
	ba.bone_name = osso
	sk.add_child(ba)
	var ps := load(caminho) as PackedScene
	if ps == null:
		return
	var n: Node3D = ps.instantiate()
	n.position = pos
	n.rotation_degrees = rot
	n.scale = Vector3.ONE * esc
	ba.add_child(n)


func _tocar(ap: AnimationPlayer, nome: String, dur: float, de_tras := false, lento := 1.0) -> void:
	if not ap.has_animation(nome):
		return
	var a := ap.get_animation(nome)
	var vel := 1.0
	if dur > 0.0 and a.length > 0.01:
		vel = a.length / dur
	vel *= lento
	if de_tras:
		ap.play(nome, 0.06, -vel, true)
	else:
		ap.play(nome, 0.08, vel)


func _fim_anim_j(n: String) -> void:
	if n == "Sword_Block" and _defendendo:
		_ap_j.pause()
	elif n in ["Sword_Regular_A", "Sword_Heavy_Combo", "Hit_Chest", "Sword_Dash", "Shield_OneShot", "Roll"]:
		_fixo_j = ""


## Posição e entrada atual vindos de TreinoCombate.
func atualizar(nucleo: TreinoCombate) -> void:
	_defendendo = nucleo.defendendo
	_jog.position = Vector3((nucleo.x - _x0) * MUNDO_POR_PX, 0, 0)
	_bon.position = Vector3((TreinoCombate.X_BONECO - _x0) * MUNDO_POR_PX, 0, 0)
	if _cam != null:
		pass
	if nucleo.estado == "livre" and not nucleo.defendendo:
		if nucleo.direcao != 0:
			var rumo := nucleo.direcao
			var nome := "Walk"
			if _atual_j != "andar%d" % rumo:
				_atual_j = "andar%d" % rumo
				_tocar(_ap_j, nome, 0.0, rumo < 0, 1.0)
		elif _atual_j.begins_with("andar"):
			_atual_j = "guarda"
			_tocar(_ap_j, "Sword_Idle", 0.0)
	elif _atual_j.begins_with("andar"):
		_atual_j = ""


func pose_jogador(pose: String, nucleo: TreinoCombate) -> void:
	_atual_j = pose
	match pose:
		"guarda":
			_tocar(_ap_j, "Sword_Idle", 0.0)
		"defende":
			_tocar(_ap_j, "Idle_Shield", 0.0)
		"prepara":
			if nucleo.estado == "pesado":
				var t: float = float(TreinoCombate.PESADO["prep"]) + float(TreinoCombate.PESADO["golpe"]) + float(TreinoCombate.PESADO["rec"])
				_tocar(_ap_j, "Sword_Attack", t)
			else:
				var t2: float = float(TreinoCombate.LEVE["prep"]) + float(TreinoCombate.LEVE["golpe"]) + float(TreinoCombate.LEVE["rec"])
				_tocar(_ap_j, "Sword_Regular_A", t2)
		"esquiva":
			_tocar(_ap_j, "Sword_Dash", TreinoCombate.ESQUIVA_DUR, true)
		"dano":
			_tocar(_ap_j, "Hit_Chest", TreinoCombate.DANO_DUR)
		"empurrao":
			_tocar(_ap_j, "Shield_OneShot", 0.5)
		_:
			pass


func pose_boneco(pose: String, tinta: String) -> void:
	var cor := Color(0.85, 0.65, 0.45)
	match tinta:
		"alerta":
			cor = Color(1.0, 0.45, 0.35)
		"atordoado":
			cor = Color(0.5, 0.65, 1.0)
	for m in _bon_mats:
		(m as StandardMaterial3D).albedo_color = cor
	match pose:
		"guarda":
			_tocar(_ap_b, "Idle", 0.0)
		"prepara":
			_tocar(_ap_b, "Sword_Regular_B", 1.4, false, 1.0)
		"dano":
			if tinta == "atordoado":
				_tocar(_ap_b, "Idle_Shield_Break", TreinoCombate.BONECO_ATORDOA)
			else:
				_tocar(_ap_b, "Hit_Chest", TreinoCombate.BONECO_REACAO)
		_:
			pass


func _mat(c: Color, metal := 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.55 if metal > 0.0 else 0.9
	m.metallic = metal
	return m


func _peca(sk: Skeleton3D, osso: String, mesh: Mesh, mat: Material, pos: Vector3, rot := Vector3.ZERO, esc := Vector3.ONE) -> void:
	var ba := BoneAttachment3D.new()
	ba.bone_name = osso
	sk.add_child(ba)
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	mi.rotation_degrees = rot
	mi.scale = esc
	ba.add_child(mi)


func _cil(r1: float, r2: float, h: float) -> CylinderMesh:
	var c := CylinderMesh.new()
	c.top_radius = r1
	c.bottom_radius = r2
	c.height = h
	c.radial_segments = 16
	return c


## Variantes visuais de teste (env VISUAL): 1 = peças 3D por cima, 2 = faixas de cor/textura procedural.
func _visual(inst: Node3D, sk: Skeleton3D, cor: Color) -> void:
	var v := OS.get_environment("VISUAL")
	if v == "1":
		var bronze := _mat(Color("b08a3c"), 0.7)
		var ferro := _mat(Color("6c6f75"), 0.8)
		var couro := _mat(Color("5a3a22"))
		var pano := _mat(Color("a32a1f"))
		var s := SphereMesh.new()
		s.radius = 0.125
		s.height = 0.25
		_peca(sk, "Head", s, ferro, Vector3(0, 0.07, 0), Vector3.ZERO, Vector3(1, 1.05, 1.15))
		var crista := BoxMesh.new()
		crista.size = Vector3(0.03, 0.12, 0.26)
		_peca(sk, "Head", crista, pano, Vector3(0, 0.2, 0))
		_peca(sk, "spine_02", _cil(0.2, 0.17, 0.34), bronze, Vector3(0, 0.08, 0))
		_peca(sk, "pelvis", _cil(0.17, 0.25, 0.26), pano, Vector3(0, -0.12, 0))
		_peca(sk, "pelvis", _cil(0.18, 0.18, 0.05), couro, Vector3(0, 0.03, 0))
		_peca(sk, "upperarm_r", _cil(0.065, 0.06, 0.26), ferro, Vector3(0, 0.14, 0), Vector3(0, 0, 90))
		_peca(sk, "lowerarm_r", _cil(0.058, 0.05, 0.26), ferro, Vector3(0, 0.14, 0), Vector3(0, 0, 90))
		for lado in ["l", "r"]:
			_peca(sk, "calf_" + lado, _cil(0.075, 0.06, 0.3), bronze, Vector3(0, 0.2, 0))
	elif v == "2":
		var sh := Shader.new()
		sh.code = """
shader_type spatial;
varying float y;
varying vec3 p;
void vertex() { y = VERTEX.y; p = VERTEX; }
void fragment() {
	vec3 pele = vec3(0.80, 0.58, 0.42);
	vec3 col = pele;
	if (y > 0.86 && y < 1.12) { col = vec3(0.66, 0.15, 0.12); float f = 0.5 + 0.5 * sin(p.x * 60.0); col *= 0.85 + 0.15 * f; }
	if (y >= 1.12 && y < 1.46 && abs(p.x) < 0.24) { col = vec3(0.62, 0.48, 0.2); col += 0.1 * sin(y * 90.0); }
	if (y >= 1.12 && y < 1.2) { col = vec3(0.30, 0.19, 0.1); }
	if (y > 1.58) { col = vec3(0.42, 0.44, 0.48); }
	if (y < 0.5) { col = mix(col, vec3(0.50, 0.36, 0.22), step(y, 0.42)); }
	ALBEDO = col; ROUGHNESS = 0.8;
}
"""
		for mi in inst.find_children("*", "MeshInstance3D", true, false):
			var m := ShaderMaterial.new()
			m.shader = sh
			(mi as MeshInstance3D).material_override = m


func _ENV_ALVO() -> float:
	return float(OS.get_environment("CAMALVO")) if OS.get_environment("CAMALVO") != "" else 0.0

func _dbg_esq(sk: Skeleton3D) -> void:
	for b in ["mixamorig_Hips", "mixamorig_Head", "mixamorig_Spine2", "mixamorig_LeftHand", "mixamorig_LeftForeArm", "mixamorig_RightHand"]:
		print("BONE ", b, " ", sk.get_bone_global_pose(sk.find_bone(b)).origin)
	var bs := sk.global_transform.basis.orthonormalized()
	print("SKBASIS x ", bs.x, " y ", bs.y, " z ", bs.z)
	print("SKT ", sk.global_transform.basis.get_scale(), " ", sk.get_parent().global_transform.basis.get_scale())


