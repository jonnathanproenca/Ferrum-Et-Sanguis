class_name DoctoreOssos
extends Node2D
## Doctore por esqueleto: peças recortadas presas a ossos (Node2D), animadas por código. O chicote é uma corrente de
## segmentos com mola, então "estala" sozinho quando o braço varre. Mesma interface do Doctore por quadros.

const DIR := "assets/ludus/doctore_rig/"
const ESC := 0.52   ## fonte -> PNG do corpo
const SW := 0.10    ## fonte -> PNG do chicote
## [nome, pai, posição (px da fonte, no espaço do pai), pivô (px da fonte, na peça), rotação inicial, z, esticar em y]
const OSSOS := [
	["quadril", "", Vector2(0, 0), Vector2.ZERO, 0.0, 0, Vector2(1.0, 1.0)],
	["saia", "quadril", Vector2(0, 0), Vector2(116, 30), 0.0, 6, Vector2(1.0, 0.62)],
	["torso", "quadril", Vector2(0, 8), Vector2(96, 190), 0.0, 2, Vector2(1.0, 1.0)],
	["cabeca", "torso", Vector2(34, -158), Vector2(62, 172), 0.0, 3, Vector2(1.0, 1.0)],
	["braco_f_sup", "torso", Vector2(-8, -118), Vector2(58, 32), 0.0, 5, Vector2(1.0, 1.0)],
	["braco_f_ant", "braco_f_sup", Vector2(10, 143), Vector2(22, 78), 0.0, 5, Vector2(1.0, 1.0)],
	["braco_t_sup", "torso", Vector2(-2, -120), Vector2(62, 32), 0.0, 0, Vector2(1.0, 1.0)],
	["braco_t_ant", "braco_t_sup", Vector2(43, 118), Vector2(18, 42), 0.0, 0, Vector2(1.0, 1.0)],
	["coxa_f", "quadril", Vector2(6, 0), Vector2(48, 28), -0.2, 3, Vector2(0.7, 1.55)],
	["canela_f", "coxa_f", Vector2(42, 212), Vector2(58, 22), 0.2, 4, Vector2(0.85, 1.25)],
	["coxa_t", "quadril", Vector2(-4, 0), Vector2(48, 28), -0.2, 1, Vector2(0.7, 1.55)],
	["canela_t", "coxa_t", Vector2(42, 212), Vector2(50, 55), 0.2, 1, Vector2(0.85, 1.25)],
]
const CADEIA := ["w_s1", "w_s2", "w_s3", "w_s4", "w_s5", "w_s6", "w_ponta"]
const REPOUSO := [0.0, 0.05, 0.3, 0.4, 0.4, 0.3, 0.15]
const PES := 440.0
const LF := 0.34  ## encurta os segmentos do chicote  ## distância (fonte) do quadril ao chão

var escala_base := 0.3
var congelar := false  ## só para depuração: pose parada
var frente := 1.0
var ocupado := false
var _o := {}
var _t := 0.0
var _acao := -1.0
var _proximo := 3.0
var _rel: Array = []
var _vel: Array = []
var _entrada: Array = []


func _init() -> void:
	for d: Array in OSSOS:
		var n := Node2D.new()
		n.name = d[0]
		n.rotation = d[4]
		_o[d[0]] = n
		if d[1] == "":
			add_child(n)
			n.position = Vector2(0, -PES * ESC)
		else:
			(_o[d[1]] as Node2D).add_child(n)
			n.position = (d[2] as Vector2) * ESC
		if d[0] != "quadril":
			var s := Sprite2D.new()
			s.texture = Tema.textura(DIR + str(d[0]) + ".png")
			s.centered = false
			s.offset = -(d[3] as Vector2) * ESC
			s.z_index = d[5]
			s.scale = d[6]
			n.add_child(s)
	# chicote: cabo na mão (ponta da mão) e corrente de segmentos
	var cabo := _peca("w_cabo", Vector2(0, 4.4))
	(_o["braco_f_ant"] as Node2D).add_child(cabo)
	cabo.position = Vector2(150, -26) * ESC
	cabo.rotation = PI / 2.0
	_o["w_cabo"] = cabo
	var pai: Node2D = cabo
	var comp_pai: float = 19.35
	for i in range(CADEIA.size()):
		var seg := _peca(CADEIA[i], Vector2(0, 0))
		pai.add_child(seg)
		seg.position = Vector2(comp_pai * (1.0 if i == 0 else LF), 0)
		_o[CADEIA[i]] = seg
		comp_pai = (seg.get_child(0) as Sprite2D).texture.get_width()
		pai = seg
		_rel.append(REPOUSO[i])
		_vel.append(0.0)
		_entrada.append(0.0)
	scale = Vector2(escala_base, escala_base)


func _peca(nome: String, piv: Vector2) -> Node2D:
	var n := Node2D.new()
	var s := Sprite2D.new()
	s.texture = Tema.textura(DIR + nome + ".png")
	s.centered = false
	var h := s.texture.get_height()
	s.offset = Vector2(0 if nome != "w_cabo" else -s.texture.get_width() / 2.0, -h / 2.0)
	s.z_index = 7
	if nome != "w_cabo":
		s.scale = Vector2(LF, 1.0)
	n.add_child(s)
	return n


func _draw() -> void:
	var pts := PackedVector2Array()
	for i in range(24):
		var a := TAU * i / 24.0
		pts.append(Vector2(cos(a) * 104.0, sin(a) * 15.0))
	draw_colored_polygon(pts, Color(0, 0, 0, 0.32))


func chicotear() -> void:
	ocupado = true
	_acao = 0.0


static func _suave(x: float) -> float:
	x = clampf(x, 0.0, 1.0)
	return x * x * (3.0 - 2.0 * x)


func _process(delta: float) -> void:
	if not congelar:
		_t += delta
	var ph := _t / 1.6 * TAU
	var braco := 0.0
	var ante := 0.0
	var tronco := 0.0
	var rijo := 0.0
	if _acao >= 0.0:
		_acao += delta
		var u := _acao
		if u < 0.45:
			var k := _suave(u / 0.45)
			braco = lerpf(0.0, 2.3, k)
			ante = lerpf(0.0, 1.0, k)
			tronco = lerpf(0.0, -0.12, k)
		elif u < 0.65:
			var k := (u - 0.45) / 0.2
			var e := 1.0 - (1.0 - k) * (1.0 - k)
			braco = lerpf(2.3, -0.9, e)
			ante = lerpf(1.0, -0.3, e)
			tronco = lerpf(-0.12, 0.15, e)
			rijo = e
		elif u < 1.25:
			var k := _suave((u - 0.65) / 0.6)
			braco = lerpf(-0.9, 0.0, k)
			ante = lerpf(-0.3, 0.0, k)
			tronco = lerpf(0.15, 0.0, k)
			rijo = 1.0 - k
		else:
			_acao = -1.0
			ocupado = false
			_proximo = randf_range(3.0, 7.0)
	else:
		_proximo -= delta
		if _proximo <= 0.0:
			chicotear()
	# pernas
	var a := sin(ph)
	(_o["coxa_f"] as Node2D).rotation = -0.2 + a * 0.3
	(_o["canela_f"] as Node2D).rotation = 0.2 + 0.6 * maxf(0.0, -cos(ph)) + 0.08
	(_o["coxa_t"] as Node2D).rotation = -0.2 - a * 0.3
	(_o["canela_t"] as Node2D).rotation = 0.2 + 0.6 * maxf(0.0, cos(ph)) + 0.08
	(_o["quadril"] as Node2D).position.y = -PES * ESC + absf(sin(ph)) * 3.0
	(_o["torso"] as Node2D).rotation = tronco + sin(ph * 2.0) * 0.015
	(_o["braco_f_sup"] as Node2D).rotation = braco + sin(ph + PI) * 0.05 + 0.1
	(_o["braco_f_ant"] as Node2D).rotation = ante
	(_o["braco_t_sup"] as Node2D).rotation = sin(ph) * 0.18 + 0.1
	(_o["braco_t_ant"] as Node2D).rotation = 0.3 + sin(ph) * 0.1
	_chicote(delta, rijo)


func _chicote(delta: float, rijo: float) -> void:
	var cabo: Node2D = _o["w_cabo"]
	var xf := global_transform.affine_inverse() * cabo.global_transform
	var mundo := xf.x.angle()
	if global_transform.determinant() < 0.0:
		mundo = xf.x.angle()
	for i in range(CADEIA.size()):
		var dA := wrapf(mundo - float(_entrada[i]), -PI, PI)
		_entrada[i] = mundo
		var alvo: float = REPOUSO[i] * (1.0 - rijo)
		_rel[i] = float(_rel[i]) - dA * 0.75
		_vel[i] = float(_vel[i]) + (-90.0 * (float(_rel[i]) - alvo) - 9.0 * float(_vel[i])) * delta
		_rel[i] = clampf(float(_rel[i]) + float(_vel[i]) * delta, -1.5, 1.5)
		(_o[CADEIA[i]] as Node2D).rotation = _rel[i]
		mundo += float(_rel[i])
