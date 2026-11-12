## Peso e balanço de peças soltas (rede do retiário): mola amortecida que reage à aceleração da mão, mais uma oscilação de repouso.
extends Node3D

const RIGIDEZ := 150.0   ## quanto maior, mais rápido a peça volta
const AMORT := 7.0       ## amortecimento (peso: menos oscilação)
const LIMITE := 0.7      ## rad, para não atravessar o corpo

var _tempo := 0.0
var _ant := Vector3.ZERO
var _vel := Vector3.ZERO
var _ang := Vector2.ZERO
var _angv := Vector2.ZERO
var _primeiro := true


func _process(dt: float) -> void:
	if dt <= 0.0:
		return
	var p := global_position
	if _primeiro:
		_ant = p
		_primeiro = false
	var v := (p - _ant) / dt
	var acc := (v - _vel) / dt
	_vel = v
	_ant = p
	_tempo += dt
	# a inércia empurra a ponta para trás do movimento (eixos locais X e Z)
	var alvo := Vector2(-acc.z, acc.x) * 0.012
	alvo.x = clampf(alvo.x, -LIMITE, LIMITE)
	alvo.y = clampf(alvo.y, -LIMITE, LIMITE)
	_angv += (alvo - _ang) * RIGIDEZ * dt - _angv * AMORT * dt
	_ang += _angv * dt
	var repouso := Vector2(0.05 * sin(_tempo * 1.7), 0.04 * sin(_tempo * 1.3))
	var tot := _ang + repouso
	rotation = Vector3(tot.x, 0.0, tot.y)
