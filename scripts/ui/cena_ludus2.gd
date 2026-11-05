class_name CenaLudus2
extends CenaLudus
## Ludus "novo": a mesma arte pintada do morro (prédio de dois andares, lanista e guardas no balcão, portão à esquerda,
## precipício à direita), mas com os gladiadores e o doctore em sprites grandes, iguais aos da luta, e uma gradação
## de entardecer para combinar com o resto do jogo.

const PONTOS_TREINO := [Vector2(732, 456), Vector2(800, 496)]

## Gradação multiplicativa: céu mais frio/escuro, cantos e pé da cena escurecidos.
class Grade extends Control:
	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		var m := CanvasItemMaterial.new()
		m.blend_mode = CanvasItemMaterial.BLEND_MODE_MUL
		material = m
	func _draw() -> void:
		var w := size.x
		var h := size.y
		var branco := Color.WHITE
		draw_polygon(PackedVector2Array([Vector2(0, 0), Vector2(w, 0), Vector2(w, h * 0.5), Vector2(0, h * 0.5)]),
			PackedColorArray([Color(0.50, 0.46, 0.72), Color(0.50, 0.46, 0.72), Color(0.98, 0.90, 0.82), Color(0.98, 0.90, 0.82)]))
		draw_polygon(PackedVector2Array([Vector2(0, h * 0.5), Vector2(w, h * 0.5), Vector2(w, h), Vector2(0, h)]),
			PackedColorArray([Color(0.98, 0.90, 0.82), Color(0.98, 0.90, 0.82), Color(0.78, 0.66, 0.60), Color(0.78, 0.66, 0.60)]))
		var esc := Color(0.45, 0.38, 0.38)
		draw_polygon(PackedVector2Array([Vector2(0, 0), Vector2(w * 0.16, 0), Vector2(w * 0.16, h), Vector2(0, h)]), PackedColorArray([esc, branco, branco, esc]))
		draw_polygon(PackedVector2Array([Vector2(w * 0.84, 0), Vector2(w, 0), Vector2(w, h), Vector2(w * 0.84, h)]), PackedColorArray([branco, esc, esc, branco]))

## Doctore: corpo em 3 poses (guarda, preparar, golpe) + chicote em 4 quadros presos à mão por ponto e ângulo de cada pose.
class Doctore extends Node2D:
	const USAR_ROLO_SPRITE := false  ## chicote enrolado na mão desligado: o chicote só aparece ao chicotar
	const USAR_ROLO := false  ## rolo desenhado em código desligado até existir o sprite do chicote enrolado
	const DIR := "assets/ludus/doctore/"
	var frente := 1.0
	var ocupado := false
	var _meta: Dictionary
	var _corpo := Sprite2D.new()
	var _chicote := Sprite2D.new()
	var _rolo := Sprite2D.new()  ## chicote recolhido, pendurado na mão
	var _tex := {}
	var _seq: Array = []
	var _seq_t := 0.0
	var _t := 0.0
	var _proximo := 3.0
	var _pose := "guarda"
	var _quadro := 1
	var _passo_t := 0.0
	const CICLO := ["anda_2", "anda_3", "anda_6", "anda_5"]
	var _recolhendo := false
	var _rec_t := 0.0
	var _coil := 1.0   ## 0..1: quanto do chicote já está enrolado na mão

	func _init() -> void:
		_meta = Util.ler_json("res://" + DIR + "doctore.json")
		for n in CICLO:
			_tex[n] = Tema.textura(DIR + n + ".png")
		for n in ["corpo_guarda", "corpo_prepara", "corpo_golpe", "chicote_1", "chicote_2", "chicote_3", "chicote_4"]:
			_tex[n] = Tema.textura(DIR + n + ".png")
		_corpo.centered = false
		_chicote.centered = false
		_rolo.texture = Tema.textura(DIR + "rolo.png")
		_rolo.centered = false
		var rp: Array = _meta["rolo"]["pivo"]
		_rolo.offset = -Vector2(rp[0], rp[1])
		add_child(_corpo)
		add_child(_chicote)
		add_child(_rolo)
		scale = Vector2(0.6, 0.6)
		_aplicar("guarda", 1)
		_chicote.visible = false

	func _draw() -> void:
		var pts := PackedVector2Array()
		for i in range(24):
			var a := TAU * i / 24.0
			pts.append(Vector2(cos(a) * 62.0, sin(a) * 9.0))
		draw_colored_polygon(pts, Color(0, 0, 0, 0.32))
		if USAR_ROLO and _pose == "guarda" and _coil > 0.01:
			_desenhar_rolo()

	## Chicote enrolado na mão (desenhado em código): cabo curto e três voltas de couro.
	func _desenhar_rolo() -> void:
		var m: Dictionary = _meta["corpo_guarda"]
		var mao := Vector2(m["mao"][0], m["mao"][1]) - Vector2(m["ancora"][0], m["ancora"][1])
		var k := _coil
		draw_line(mao + Vector2(-6, 2), mao + Vector2(14 * k, -2 * k), Color(0.08, 0.05, 0.03), 6.0, true)
		draw_line(mao + Vector2(-6, 2), mao + Vector2(14 * k, -2 * k), Color(0.50, 0.33, 0.16), 3.5, true)
		var c := mao + Vector2(4, 11)
		for i in range(3):
			var r := (9.0 - i * 2.2) * k
			draw_set_transform(c + Vector2(0, i * 1.5), 0.0, Vector2(1.0, 0.78))
			draw_arc(Vector2.ZERO, r, 0.0, TAU, 20, Color(0.08, 0.05, 0.03), 5.0, true)
			draw_arc(Vector2.ZERO, r, 0.0, TAU, 20, Color(0.42 + i * 0.05, 0.27 + i * 0.03, 0.13), 2.6, true)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	func _aplicar(pose: String, quadro: int) -> void:
		_pose = pose
		_quadro = quadro
		var m: Dictionary = _meta["corpo_" + pose]
		var anc := Vector2(m["ancora"][0], m["ancora"][1])
		_corpo.texture = _tex["corpo_" + pose]
		_corpo.position = -anc
		var c: Dictionary = _meta["chicote_%d" % quadro]
		_chicote.texture = _tex["chicote_%d" % quadro]
		_chicote.offset = -Vector2(c["pivo"][0], c["pivo"][1])
		_chicote.position = Vector2(m["mao"][0], m["mao"][1]) - anc
		_chicote.rotation = deg_to_rad(float(m["angulo"]))
		_rolo.position = Vector2(m["mao"][0], m["mao"][1]) - anc
		_rolo.rotation = 0.0
		_rolo.visible = USAR_ROLO_SPRITE and ((pose == "guarda" and not ocupado) or (pose == "guarda" and _recolhendo and _coil > 0.5))

	func chicotear() -> void:
		ocupado = true
		_recolhendo = false
		_chicote.visible = true
		_chicote.scale = Vector2.ONE
		_coil = 0.0
		queue_redraw()
		_seq = [[0.30, "prepara", 2], [0.10, "golpe", 3], [0.16, "golpe", 4], [0.20, "golpe", 3]]
		_seq_t = 0.0
		_rolo.modulate.a = 1.0
		_aplicar("prepara", 2)

	func _process(delta: float) -> void:
		_t += delta
		if ocupado:
			_seq_t += delta
			var acum := 0.0
			var fim := true
			for passo in _seq:
				acum += float(passo[0])
				if _seq_t < acum:
					if _pose != passo[1] or _quadro != passo[2]:
						_aplicar(passo[1], passo[2])
					fim = false
					break
			if fim:
				if not _recolhendo:
					_recolhendo = true
					_rec_t = 0.0
					_aplicar("guarda", 1)
				_rec_t += delta
				var q := clampf(_rec_t / 0.45, 0.0, 1.0)
				_chicote.scale = Vector2.ONE * (1.0 - q)
				_chicote.modulate.a = 1.0 - q * 0.6
				_coil = q
				queue_redraw()
				if q >= 1.0:
					ocupado = false
					_recolhendo = false
					_chicote.visible = false
					_chicote.modulate.a = 1.0
					_proximo = randf_range(3.0, 7.0)
			return
		_proximo -= delta
		if _proximo <= 0.0:
			chicotear()
			return
		_passo_t += delta
		_andar(int(_passo_t / 0.16) % CICLO.size())

	## Quadro do ciclo de caminhada (corpo; o chicote fica escondido enquanto anda).
	func _andar(i: int) -> void:
		var n: String = CICLO[i]
		var m: Dictionary = _meta[n]
		_corpo.texture = _tex[n]
		_corpo.position = -Vector2(m["ancora"][0], m["ancora"][1])
		_pose = "anda"
		_chicote.visible = false
		_rolo.visible = false


var _palco2: Node2D
var _treinadores: Array = []
var _prox_golpe := 1.5
var _ponto_doctore := 0.0
var _doctore: Doctore


func _init() -> void:
	grande = true


func _montar() -> void:
	var antes := _assinatura
	super._montar()
	if _assinatura == antes:
		return
	_treinadores.clear()
	_doctore = null
	_palco2 = Node2D.new()
	_palco2.z_index = 0
	add_child(_palco2)
	var e: Dictionary = Jogo.e
	var palus := Game.tem_melhoria(e, "palus")
	var livres: Array = PONTOS.map(func(p: Array) -> Vector2: return Vector2(p[0], p[1]))
	var vagas_t: Array = PONTOS_TREINO.duplicate()
	var i := 0
	for g: Dictionary in e["gladiadores"]:
		if not g["vivo"]:
			continue
		var sem: bool = bool(g.get("semEstilo", false))
		var treina: bool = palus and not sem and not vagas_t.is_empty()
		var pos: Vector2 = vagas_t.pop_front() if treina else livres[i % livres.size()]
		if not treina:
			i += 1
		var esc := 0.50 + 0.14 * clampf((pos.y - 440.0) / 110.0, 0.0, 1.0)
		var virado: bool = not treina and pos.x > 460.0
		var altura := 181.0 * esc
		var no: Node2D
		if sem:
			no = Node2D.new()
			var sp := Sprite2D.new()
			sp.texture = Sprites.escravo(str(g["terra"]), int(g["look"]), str(g.get("condicao", "")))
			sp.centered = false
			var ts: Vector2 = sp.texture.get_size()
			var f := (altura * 0.84) / ts.y
			sp.scale = Vector2(f * (-1.0 if virado else 1.0), f)
			sp.position = Vector2(ts.x * f / 2.0 if virado else -ts.x * f / 2.0, -ts.y * f)
			no.add_child(sp)
			no.position = pos
		else:
			var lut := LutadorLuta.new(str(g["id"]), str(g["classe"]), esc, virado, 0.5, pos)
			no = lut
			if treina:
				_treinadores.append(lut)
		no.z_index = int(pos.y)
		_palco2.add_child(no)
		var b := Button.new()
		b.flat = true
		b.focus_mode = Control.FOCUS_NONE
		b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		for sn in ["normal", "hover", "pressed", "focus", "disabled", "hover_pressed"]:
			b.add_theme_stylebox_override(sn, StyleBoxEmpty.new())
		b.tooltip_text = "%s · nível %d. Clique para ver a ficha." % [g["nome"], int(g["nivel"])]
		var gid: String = g["id"]
		b.pressed.connect(func() -> void: ModalGladiador.abrir(self, gid))
		b.z_index = 1200
		_novo_item(b, Rect2(pos.x - altura * 0.30, pos.y - altura, altura * 0.60, altura), 1200, "ponto")
	# doctore: sprite grande, patrulhando o pátio
	_doctore = Doctore.new()
	_doctore.position = Vector2(300, 458)
	_doctore.z_index = 458
	_palco2.add_child(_doctore)
	# gradação de entardecer
	var gr := Grade.new()
	_novo_item(gr, Rect2(0, 0, W, H), 900, "img")
	_reposicionar()


func _reposicionar() -> void:
	super._reposicionar()
	if _palco2:
		_palco2.position = _org
		_palco2.scale = Vector2(_k, _k)


func _animar(delta: float) -> void:
	super._animar(delta)
	if _doctore and is_instance_valid(_doctore):
		if not _doctore.ocupado:
			_ponto_doctore += delta
		var u := _tri(_ponto_doctore / 18.0)
		var x := lerpf(250.0, 600.0, _suave(u))
		var vai := fposmod(_ponto_doctore, 36.0) < 18.0
		_doctore.position = Vector2(x, 458.0)
		_doctore.scale.x = 0.6 * (1.0 if vai else -1.0)
	if not _treinadores.is_empty() and is_visible_in_tree():
		_prox_golpe -= delta
		if _prox_golpe <= 0.0:
			_prox_golpe = randf_range(1.6, 3.2)
			var l: LutadorLuta = _treinadores[randi() % _treinadores.size()]
			if is_instance_valid(l) and l.is_inside_tree():
				l.golpear("corte")
