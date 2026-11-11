class_name EscudoMod
extends SkeletonModifier3D
## Posiciona o escudo do gladiador a cada atualização do esqueleto (espaço do esqueleto: +Z frente, +X lado esquerdo, +Y cima).
## Em guarda/caminhada/ataque o escudo fica rente ao antebraço esquerdo, do lado de fora (no pesado, por cima);
## na defesa do jogador fica fixo à frente do peito e o braço é levado até ele (IK de 2 ossos);
## no parry do boneco acompanha o movimento da mão.

const ESC := 0.0026
const FRENTE := Vector3(0.0014, 0.0135, 0.0026)
const GUARDA := Vector3(0.0016, 0.0124, 0.0020)
const ROLL := Basis(Vector3(0, 0, 1), PI / 2.0)

var escudo: Node3D
var ap: AnimationPlayer
var jogador := true
var fixo := false               ## escudo preso ao antebraço, sempre na mesma posição relativa (qualquer animação)
var sobe := 0.0                 ## sobe o escudo (unidades do esqueleto) na guarda/defesa
var esc_k := 1.0                ## fator de escala do esqueleto (gladiador 2 usa outra escala de instância)
var _peso := 0.0
var _pref := Vector3.RIGHT
var _ref := Vector3.ZERO
var _modo_ant := ""
var _t := 0


func _process_modification() -> void:
	var sk := get_skeleton()
	if sk == null or escudo == null or ap == null:
		return
	var b_arm := sk.find_bone("mixamorig_LeftArm")
	var b_fore := sk.find_bone("mixamorig_LeftForeArm")
	var b_hand := sk.find_bone("mixamorig_LeftHand")
	var agora := Time.get_ticks_msec()
	var dt: float = clampf((agora - _t) / 1000.0, 0.0, 0.1)
	_t = agora
	var esc_ef := ESC * esc_k
	var nome := String(ap.current_animation)
	var modo := "mao"
	if fixo:
		_fixar(sk, b_fore, b_hand, esc_ef)
		return
	var pref := Vector3.RIGHT
	match nome:
		"Idle_Shield", "Sword_Block":
			if jogador:
				modo = "frente"
		"Sword_Regular_A", "Sword_Regular_B":
			if jogador:
				modo = "guarda"
		"Idle_Shield_Break":
			if not jogador:
				modo = "segue"
		"Sword_Attack", "Sword_Heavy_Combo":
			pref = Vector3.UP
			# no fim do golpe pesado o escudo volta para a frente do corpo (madeira à mostra)
			if jogador and ap.current_animation_length > 0.0 and ap.current_animation_position / ap.current_animation_length > 0.6:
				modo = "guarda"
	var alvo := 0.0 if modo == "mao" else 1.0
	_peso = move_toward(_peso, alvo, dt * 9.0) if ap.is_playing() else alvo
	_pref = _pref.lerp(pref, clampf(dt * 10.0, 0.0, 1.0)) if ap.is_playing() else pref
	var gh := sk.get_bone_global_pose(b_hand)
	if modo != _modo_ant:
		_modo_ant = modo
		_ref = gh.origin
	# --- posição "rente ao antebraço, por fora"
	var e := sk.get_bone_global_pose(b_fore).origin
	var a := (gh.origin - e).normalized()
	var p := _pref.normalized()
	var n := p - a * p.dot(a)
	if n.length() < 0.25:
		n = Vector3.BACK - a * Vector3.BACK.dot(a)
	n = n.normalized()
	var y := a
	var x := y.cross(n).normalized()
	var t_mao := Transform3D(Basis(y, -x, n) * Basis.from_scale(Vector3.ONE * esc_ef), e + a * 0.0014 * esc_k + n * 0.0009 * esc_k)
	var t_fim := t_mao
	var esc_s := ROLL * Basis.from_scale(Vector3.ONE * esc_ef)
	var b_peito := sk.find_bone("mixamorig_Spine2")
	var mv := sk.get_bone_global_pose(b_peito) * sk.get_bone_global_rest(b_peito).affine_inverse()
	var base_pos := (GUARDA if modo == "guarda" else FRENTE) * esc_k + Vector3(0, sobe, 0)
	if modo == "frente" or modo == "guarda" or (modo == "segue" and _peso > 0.0):
		var t_f := mv * Transform3D(esc_s, base_pos)
		if modo == "segue":
			t_f = Transform3D(esc_s, base_pos + (gh.origin - _ref))
		t_fim = t_mao.interpolate_with(t_f, _peso)
	elif _peso > 0.0 and ap.is_playing():
		pass
	escudo.transform = t_fim
	for tr in _tiras:
		tr.visible = modo != "frente"
	# --- IK do braço até o escudo na defesa do jogador
	if (modo == "frente" or modo == "guarda") and _peso > 0.0:
		var alvo_mao := mv * (base_pos + Vector3(0, 0, -0.0007) * esc_k)
		var ga := sk.get_bone_global_pose(b_arm)
		var gf := sk.get_bone_global_pose(b_fore)
		var s := ga.origin
		var ee := gf.origin
		var w := gh.origin
		var l1 := (ee - s).length()
		var l2 := (w - ee).length()
		var dd := clampf((alvo_mao - s).length(), absf(l1 - l2) + 0.00005, l1 + l2 - 0.00005)
		var dir := (alvo_mao - s).normalized()
		var perp := (ee - s) - dir * (ee - s).dot(dir)
		if perp.length() < 0.00005:
			perp = Vector3(0, -1, -1)
		perp = (perp.normalized() + Vector3(0.2, -0.3, 0.7)).normalized()
		perp = (perp - dir * perp.dot(dir)).normalized()
		var aa := (l1 * l1 - l2 * l2 + dd * dd) / (2.0 * dd)
		var hh := sqrt(maxf(l1 * l1 - aa * aa, 0.0))
		var e2 := s + dir * aa + perp * hh
		var q1 := _arco((ee - s).normalized(), (e2 - s).normalized())
		var q2 := _arco(q1 * (w - ee).normalized(), (s + dir * dd - e2).normalized())
		var ga2 := Transform3D(Basis(q1) * ga.basis, s).interpolate_with(ga, 1.0 - _peso)
		var gf2 := Transform3D(Basis(q2 * q1) * gf.basis, e2).interpolate_with(gf, 1.0 - _peso)
		var gh2 := Transform3D(Basis(q2 * q1) * gh.basis, w.lerp(s + dir * dd, _peso))
		sk.set_bone_global_pose(b_arm, ga2)
		sk.set_bone_global_pose(b_fore, gf2)
		sk.set_bone_global_pose(b_hand, gh2)


## Escudo preso ao antebraço: a "face de fora" é um vetor fixo no osso (gira junto com o antebraço), sem IK nem posição no peito.
const FACE_LOCAL := Vector3(0.47, 0.0, -0.88)

func _fixar(sk: Skeleton3D, b_fore: int, b_hand: int, esc_ef: float) -> void:
	var gf := sk.get_bone_global_pose(b_fore)
	var gh := sk.get_bone_global_pose(b_hand)
	var a := (gh.origin - gf.origin).normalized()
	var n := gf.basis.orthonormalized() * FACE_LOCAL.normalized()
	n = (n - a * n.dot(a)).normalized()
	var y := a
	var x := y.cross(n).normalized()
	escudo.transform = Transform3D(Basis(y, -x, n) * Basis.from_scale(Vector3.ONE * esc_ef), gf.origin + a * 0.0014 * esc_k + n * 0.0009 * esc_k)
	for tr in _tiras:
		tr.visible = true


## Tiras de couro por cima do antebraço (as duas à vista), só quando o escudo está rente ao braço.
var _tiras: Array[MeshInstance3D] = []

func montar_tiras() -> void:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.42, 0.24, 0.1)
	mat.roughness = 0.85
	for cx in [-0.32, 0.1]:
		var mi := MeshInstance3D.new()
		var bx := BoxMesh.new()
		bx.size = Vector3(0.2, 0.46, 0.46)
		mi.mesh = bx
		mi.material_override = mat
		mi.position = Vector3(cx, 0.0, -0.34)
		escudo.add_child(mi)
		_tiras.append(mi)


func _arco(de: Vector3, para: Vector3) -> Quaternion:
	var c := de.cross(para)
	if c.length() < 0.00001:
		return Quaternion.IDENTITY
	return Quaternion(c.normalized(), de.angle_to(para))
