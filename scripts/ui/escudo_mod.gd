class_name EscudoMod
extends SkeletonModifier3D
## Posiciona o escudo do gladiador a cada atualização do esqueleto (espaço do esqueleto: +Z frente, +X lado esquerdo, +Y cima).
## Em guarda/caminhada/ataque o escudo fica rente ao antebraço esquerdo, do lado de fora (no pesado, por cima);
## na defesa do jogador fica fixo à frente do peito e o braço é levado até ele (IK de 2 ossos);
## no parry do boneco acompanha o movimento da mão.

const ESC := 0.0026
const FRENTE := Vector3(0.0014, 0.0121, 0.0026)

var escudo: Node3D
var ap: AnimationPlayer
var jogador := true
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
	var nome := String(ap.current_animation)
	var modo := "mao"
	var pref := Vector3.RIGHT
	match nome:
		"Idle_Shield", "Sword_Block":
			if jogador:
				modo = "frente"
		"Idle_Shield_Break":
			if not jogador:
				modo = "segue"
		"Sword_Attack", "Sword_Heavy_Combo":
			pref = Vector3.UP
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
	var t_mao := Transform3D(Basis(x, y, n) * Basis.from_scale(Vector3.ONE * ESC), e + a * 0.0014 + n * 0.0009)
	var t_fim := t_mao
	var esc_s := Basis.from_scale(Vector3.ONE * ESC)
	if modo == "frente" or (modo == "segue" and _peso > 0.0):
		var centro := FRENTE
		if modo == "segue":
			centro = FRENTE + (gh.origin - _ref)
		t_fim = t_mao.interpolate_with(Transform3D(esc_s, centro), _peso)
	elif _peso > 0.0 and ap.is_playing():
		pass
	escudo.transform = t_fim
	# --- IK do braço até o escudo na defesa do jogador
	if modo == "frente" and _peso > 0.0:
		var alvo_mao := FRENTE + Vector3(0, 0, -0.0003)
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


func _arco(de: Vector3, para: Vector3) -> Quaternion:
	var c := de.cross(para)
	if c.length() < 0.00001:
		return Quaternion.IDENTITY
	return Quaternion(c.normalized(), de.angle_to(para))
