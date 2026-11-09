class_name Cena3DTreino
extends SubViewportContainer
## Versão 3D (teste) da mini-arena de treino: manequim Quaternius com animações de espada, gládio e escudo nas mãos,
## boneco de treino. Só desenha: quem decide golpe, parry e esquiva continua em TreinoCombate.

const BONECA_GLB := "res://assets/3d/UAL1_Standard.glb"
const ANIMS_EXTRA := "res://assets/3d/UAL2_Standard.glb"
const GLADIO := "res://assets/3d/gladio.glb"
const ESCUDO := "res://assets/3d/escudo_redondo.fbx"
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
	var animas := _carregar_animacoes()
	_jog = _criar_personagem(animas, Color(0.93, 0.85, 0.72), true)
	_bon = _criar_personagem(animas, Color(0.85, 0.65, 0.45), false)
	var giro := float(OS.get_environment('GIRO')) if OS.get_environment('GIRO') != '' else 90.0
	_jog.rotation_degrees.y = giro
	_bon.rotation_degrees.y = -giro
	_ap_j = _achar_ap(_jog)
	_ap_b = _achar_ap(_bon)
	_ap_j.animation_finished.connect(func(n): _fim_anim_j(String(n)))
	_tocar(_ap_j, "Sword_Idle", 0.0)
	_tocar(_ap_b, "Idle", 0.0)


func _montar_mundo() -> void:
	var cam := Camera3D.new()
	cam.fov = 34.0
	cam.position = Vector3(0.95, 1.35, 7.0)
	_vp.add_child(cam)
	_cam = cam
	cam.look_at(Vector3(0.95, 0.95, 0.0), Vector3.UP)
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


func _criar_personagem(animas: Dictionary, cor: Color, com_equip: bool) -> Node3D:
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
	_anexar(sk, "hand_r", GLADIO, _rot_env("GPOS"), _rot_env("GROT"), 1.0)
	_anexar(sk, "hand_l", ESCUDO, _rot_env("SPOS") if OS.get_environment("SPOS") != "" else Vector3.ZERO, _rot_env("SROT"), 0.26)
	return inst


func _rot_env(nome: String) -> Vector3:
	var t := OS.get_environment(nome)
	if t == "":
		match nome:
			"GROT":
				return Vector3(90, 0, 0)
			"GPOS":
				return Vector3(0, 0.12, 0.04)
		return Vector3(0, -90, 0)
	var p := t.split(",")
	return Vector3(float(p[0]), float(p[1]), float(p[2]))


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
