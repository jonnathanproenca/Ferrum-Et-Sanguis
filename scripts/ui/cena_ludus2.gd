class_name CenaLudus2
extends Control
## Ludus "novo": pátio ao entardecer desenhado em código (mesma paleta e escala das arenas), com os gladiadores do jogador
## em sprites grandes (os mesmos da luta), o doctore, as salas do ludus (acendem ao construir) e o portão.
## Palco lógico 1280x720 escalado para caber no controle.

const PALCO := Vector2(1280, 720)
const MURO_Y := 200.0
const CHAO_Y := 430.0
const SALAS := [
	["armaria", "ARMARIA", 270.0], ["enfermaria", "ENFERMARIA", 540.0],
	["refeitorio", "REFEITÓRIO", 810.0], ["alojamentos", "ALOJAMENTOS", 1080.0],
]
const TOCHAS := [Vector2(135, 330), Vector2(405, 330), Vector2(675, 330), Vector2(945, 330), Vector2(1215, 330)]
## Pontos do pátio onde os gladiadores ficam: x, y (pés). Os dois últimos ficam junto dos palus e treinam.
const VAGAS := [
	Vector2(300, 520), Vector2(470, 585), Vector2(640, 520), Vector2(780, 610), Vector2(360, 650),
	Vector2(560, 650), Vector2(900, 540), Vector2(220, 590), Vector2(700, 475), Vector2(430, 480),
]
const VAGAS_TREINO := [Vector2(1010, 600), Vector2(1140, 640)]


## Desenho do cenário (céu, muro, salas, chão, palus, tochas, vinheta).
class Fundo extends Node2D:
	var construidas := {}
	var t := 0.0
	var _pontos: Array = []
	var _estrelas: Array = []

	func _init() -> void:
		var r := RandomNumberGenerator.new()
		r.seed = 77
		for i in range(520):
			_pontos.append([r.randf() * 1280.0, 440.0 + r.randf() * 280.0, r.randf(), r.randf_range(1.0, 3.0)])
		for i in range(70):
			_estrelas.append([r.randf() * 1280.0, r.randf() * 140.0, r.randf()])

	func _process(delta: float) -> void:
		t += delta
		queue_redraw()

	func _draw() -> void:
		_ceu()
		_muro()
		_salas()
		_chao()
		_portao()
		_palus()
		_tochas()
		_vinheta()

	func _faixas(x0: float, y0: float, w: float, h: float, a: Color, b: Color, n: int) -> void:
		var sh := h / float(n)
		for i in range(n):
			draw_rect(Rect2(x0, y0 + i * sh, w, sh + 1.0), a.lerp(b, float(i) / float(maxi(n - 1, 1))))

	func _ceu() -> void:
		_faixas(0, 0, 1280, 210, Color(0.05, 0.07, 0.17), Color(0.66, 0.32, 0.20), 42)
		for e in _estrelas:
			var br: float = 0.25 + 0.5 * abs(sin(t * 0.8 + float(e[2]) * 9.0))
			draw_circle(Vector2(e[0], e[1]), 1.2, Color(1, 0.95, 0.8, br * (1.0 - float(e[1]) / 160.0)))
		draw_circle(Vector2(930, 190), 150.0, Color(1.0, 0.5, 0.2, 0.10))
		draw_colored_polygon(PackedVector2Array([Vector2(0, 205), Vector2(0, 160), Vector2(140, 130), Vector2(300, 170), Vector2(470, 150), Vector2(620, 180), Vector2(760, 165), Vector2(860, 110), Vector2(900, 70), Vector2(930, 64), Vector2(965, 76), Vector2(1010, 118), Vector2(1120, 150), Vector2(1280, 140), Vector2(1280, 205)]), Color(0.15, 0.10, 0.17))
		draw_circle(Vector2(930, 66), 5.0, Color(1.0, 0.55, 0.2, 0.55 + 0.25 * sin(t * 2.0)))

	func _muro() -> void:
		var base := Color(0.36, 0.28, 0.22)
		draw_rect(Rect2(0, MURO_Y, 1280, CHAO_Y - MURO_Y + 14), base)
		var fila := 0
		var y := MURO_Y
		while y < CHAO_Y + 14.0:
			var off := 0.0 if fila % 2 == 0 else 34.0
			var x := -off
			while x < 1280.0:
				var h := float((int(x) * 31 + fila * 17) % 13) / 13.0
				var c := base.lightened(0.06 * h).darkened(0.05 * (1.0 - h))
				draw_rect(Rect2(x + 1, y + 1, 66, 25), c)
				x += 68.0
			draw_line(Vector2(0, y), Vector2(1280, y), Color(0.12, 0.08, 0.06, 0.8), 1.5)
			y += 26.0
			fila += 1
		# telhado
		draw_rect(Rect2(0, 150, 1280, 56), Color(0.34, 0.13, 0.09))
		for x in range(0, 1290, 16):
			draw_line(Vector2(x, 150), Vector2(x, 206), Color(0.20, 0.07, 0.05, 0.8), 1.5)
		for y2 in range(158, 206, 12):
			draw_line(Vector2(0, y2), Vector2(1280, y2), Color(0.55, 0.22, 0.14, 0.35), 1.0)
		draw_rect(Rect2(0, 146, 1280, 8), Color(0.50, 0.21, 0.13))
		draw_rect(Rect2(0, 202, 1280, 8), Color(0.10, 0.07, 0.06, 0.85))
		# pilastras
		for px in [135.0, 405.0, 675.0, 945.0, 1215.0]:
			draw_rect(Rect2(px - 18, MURO_Y + 8, 36, CHAO_Y - MURO_Y + 6), Color(0.46, 0.36, 0.28))
			draw_rect(Rect2(px - 18, MURO_Y + 8, 8, CHAO_Y - MURO_Y + 6), Color(0.56, 0.45, 0.35))
			draw_rect(Rect2(px - 24, MURO_Y + 4, 48, 12), Color(0.52, 0.41, 0.32))
			draw_rect(Rect2(px - 24, CHAO_Y - 4, 48, 14), Color(0.40, 0.31, 0.24))

	func _salas() -> void:
		for s in SALAS:
			var id: String = s[0]
			var cx: float = s[2]
			var ligada: bool = bool(construidas.get(id, false))
			var topo := 262.0
			var pts := PackedVector2Array()
			pts.append(Vector2(cx - 80, CHAO_Y))
			pts.append(Vector2(cx - 80, topo + 40))
			for i in range(0, 21):
				var a := PI + PI * float(i) / 20.0
				pts.append(Vector2(cx + cos(a) * 80.0, topo + 40.0 + sin(a) * 40.0))
			pts.append(Vector2(cx + 80, CHAO_Y))
			draw_colored_polygon(pts, Color(0.04, 0.03, 0.03))
			if ligada:
				var f := 0.8 + 0.2 * sin(t * 3.0 + cx)
				draw_colored_polygon(pts, Color(0.95, 0.55, 0.20, 0.28 * f))
				draw_circle(Vector2(cx, 380), 70.0, Color(1.0, 0.65, 0.25, 0.10 * f))
				_interior(id, cx)
			else:
				for k in range(-2, 3):
					draw_line(Vector2(cx + k * 34.0 - 40, CHAO_Y - 4), Vector2(cx + k * 34.0 + 40, 320), Color(0.30, 0.20, 0.12), 8.0)
				draw_line(Vector2(cx - 76, 330), Vector2(cx + 76, 330), Color(0.38, 0.26, 0.15), 10.0)
				draw_line(Vector2(cx - 76, 392), Vector2(cx + 76, 392), Color(0.38, 0.26, 0.15), 10.0)
			# arco de pedra
			var arco := PackedVector2Array()
			for i in range(0, 21):
				var a2 := PI + PI * float(i) / 20.0
				arco.append(Vector2(cx + cos(a2) * 88.0, topo + 40.0 + sin(a2) * 46.0))
			draw_polyline(arco, Color(0.55, 0.44, 0.34), 9.0, true)
			draw_line(Vector2(cx - 88, topo + 40), Vector2(cx - 88, CHAO_Y), Color(0.55, 0.44, 0.34), 9.0)
			draw_line(Vector2(cx + 88, topo + 40), Vector2(cx + 88, CHAO_Y), Color(0.55, 0.44, 0.34), 9.0)
			# placa
			var fonte: Font = Tema.fonte_titulo
			var tw := fonte.get_string_size(s[1], HORIZONTAL_ALIGNMENT_LEFT, -1, 20).x
			draw_rect(Rect2(cx - tw / 2.0 - 12, 214, tw + 24, 30), Color(0.20, 0.12, 0.07))
			draw_rect(Rect2(cx - tw / 2.0 - 12, 214, tw + 24, 30), Color(0.78, 0.60, 0.28, 0.9 if ligada else 0.35), false, 2.0)
			draw_string(fonte, Vector2(cx - tw / 2.0, 236), s[1], HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color(0.95, 0.82, 0.54) if ligada else Color(0.55, 0.48, 0.40))

	func _interior(id: String, cx: float) -> void:
		var c := Color(0.12, 0.07, 0.05)
		match id:
			"armaria":
				for k in range(-3, 4):
					draw_line(Vector2(cx + k * 18.0, 322), Vector2(cx + k * 18.0, 428), c, 3.0)
				draw_line(Vector2(cx - 62, 350), Vector2(cx + 62, 350), c, 4.0)
				for k in range(-2, 3):
					draw_line(Vector2(cx + k * 24.0, 338), Vector2(cx + k * 24.0 + 6, 388), Color(0.75, 0.78, 0.82), 3.0)
				draw_circle(Vector2(cx - 40, 410), 12.0, Color(0.55, 0.40, 0.20))
			"enfermaria":
				draw_rect(Rect2(cx - 50, 394, 100, 18), c)
				draw_rect(Rect2(cx - 46, 384, 92, 12), Color(0.82, 0.76, 0.66))
				draw_rect(Rect2(cx - 5, 330, 10, 34), Color(0.75, 0.15, 0.12))
				draw_rect(Rect2(cx - 17, 342, 34, 10), Color(0.75, 0.15, 0.12))
			"refeitorio":
				draw_rect(Rect2(cx - 62, 392, 124, 10), c)
				draw_line(Vector2(cx - 54, 402), Vector2(cx - 54, 428), c, 5.0)
				draw_line(Vector2(cx + 54, 402), Vector2(cx + 54, 428), c, 5.0)
				for k in range(-1, 2):
					draw_circle(Vector2(cx + k * 34.0, 380), 11.0, Color(0.62, 0.36, 0.18))
				draw_circle(Vector2(cx + 54, 405), 14.0, Color(0.50, 0.30, 0.15))
			_:
				for y2 in [340.0, 392.0]:
					draw_rect(Rect2(cx - 62, y2, 124, 8), c)
					draw_rect(Rect2(cx - 58, y2 - 8, 116, 8), Color(0.55, 0.42, 0.30))
				draw_line(Vector2(cx - 62, 340), Vector2(cx - 62, 428), c, 5.0)
				draw_line(Vector2(cx + 62, 340), Vector2(cx + 62, 428), c, 5.0)

	func _chao() -> void:
		_faixas(0, CHAO_Y + 14.0, 1280, 280, Color(0.60, 0.45, 0.29), Color(0.30, 0.21, 0.13), 28)
		draw_rect(Rect2(0, CHAO_Y + 8, 1280, 14), Color(0.10, 0.07, 0.05, 0.55))
		for p in _pontos:
			var cl := Color(0.82, 0.66, 0.42, 0.10 + 0.14 * float(p[2])) if float(p[2]) > 0.5 else Color(0.20, 0.13, 0.08, 0.25)
			draw_rect(Rect2(p[0], p[1], float(p[3]) * 2.0, float(p[3]) * 0.6), cl)
		for tp in TOCHAS:
			for i in range(5):
				var f := float(i) / 4.0
				draw_set_transform(Vector2(tp.x, 470.0), 0.0, Vector2(1.0, 0.28))
				draw_circle(Vector2.ZERO, 190.0 * (1.0 - f * 0.8), Color(1.0, 0.62, 0.25, 0.026))
				draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	func _portao() -> void:
		draw_rect(Rect2(0, 250, 150, 360), Color(0.43, 0.34, 0.27))
		for y in range(256, 610, 28):
			draw_line(Vector2(0, y), Vector2(150, y), Color(0.12, 0.08, 0.06, 0.7), 1.5)
		draw_rect(Rect2(14, 322, 108, 268), Color(0.03, 0.02, 0.02))
		for k in range(0, 8):
			draw_line(Vector2(24 + k * 13.0, 322), Vector2(24 + k * 13.0, 590), Color(0.30, 0.28, 0.27), 4.0)
		draw_line(Vector2(14, 420), Vector2(122, 420), Color(0.30, 0.28, 0.27), 5.0)
		draw_line(Vector2(14, 520), Vector2(122, 520), Color(0.30, 0.28, 0.27), 5.0)
		draw_rect(Rect2(8, 316, 120, 10), Color(0.52, 0.42, 0.33))
		draw_rect(Rect2(0, 604, 150, 8), Color(0.10, 0.07, 0.05, 0.6))

	func _palus() -> void:
		for p in [Vector2(1010, 596), Vector2(1140, 636)]:
			draw_set_transform(p + Vector2(0, 4), 0.0, Vector2(1.0, 0.25))
			draw_circle(Vector2.ZERO, 46.0, Color(0, 0, 0, 0.32))
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			draw_rect(Rect2(p.x - 6, p.y - 150, 12, 150), Color(0.32, 0.21, 0.12))
			draw_rect(Rect2(p.x - 6, p.y - 150, 4, 150), Color(0.46, 0.31, 0.18))
			draw_rect(Rect2(p.x - 32, p.y - 118, 64, 9), Color(0.32, 0.21, 0.12))
			draw_circle(Vector2(p.x, p.y - 158), 12.0, Color(0.62, 0.50, 0.28))
			draw_circle(Vector2(p.x, p.y - 100), 15.0, Color(0.55, 0.44, 0.24))
			draw_line(Vector2(p.x - 14, p.y - 96), Vector2(p.x + 14, p.y - 84), Color(0.30, 0.20, 0.12), 3.0)

	func _tochas() -> void:
		for p in TOCHAS:
			var f := 0.85 + 0.15 * sin(t * 9.0 + p.x) + 0.08 * sin(t * 17.0 + p.x * 2.0)
			for i in range(9):
				var k := float(i) / 8.0
				draw_circle(p, 110.0 * (1.0 - k), Color(1.0, 0.55, 0.15, (0.010 + 0.02 * k) * f))
			draw_rect(Rect2(p.x - 3, p.y + 6, 6, 30), Color(0.26, 0.16, 0.08))
			draw_rect(Rect2(p.x - 7, p.y + 2, 14, 7), Color(0.38, 0.24, 0.12))
			var alt := 15.0 * f
			draw_colored_polygon(PackedVector2Array([Vector2(p.x - 7, p.y + 2), Vector2(p.x, p.y - alt), Vector2(p.x + 7, p.y + 2)]), Color(1.0, 0.55, 0.12))
			draw_colored_polygon(PackedVector2Array([Vector2(p.x - 4, p.y + 2), Vector2(p.x, p.y - alt * 0.6), Vector2(p.x + 4, p.y + 2)]), Color(1.0, 0.92, 0.55))

	func _vinheta() -> void:
		var esc := Color(0, 0, 0, 0.55)
		var nul := Color(0, 0, 0, 0)
		draw_polygon(PackedVector2Array([Vector2(0, 0), Vector2(150, 0), Vector2(150, 720), Vector2(0, 720)]), PackedColorArray([esc, nul, nul, esc]))
		draw_polygon(PackedVector2Array([Vector2(1130, 0), Vector2(1280, 0), Vector2(1280, 720), Vector2(1130, 720)]), PackedColorArray([nul, esc, esc, nul]))
		draw_polygon(PackedVector2Array([Vector2(0, 590), Vector2(1280, 590), Vector2(1280, 720), Vector2(0, 720)]), PackedColorArray([nul, nul, esc, esc]))
		draw_polygon(PackedVector2Array([Vector2(0, 0), Vector2(1280, 0), Vector2(1280, 70), Vector2(0, 70)]), PackedColorArray([esc, esc, nul, nul]))


var _palco: Node2D
var _fundo: Fundo
var _entes: Node2D
var _k := 1.0
var _org := Vector2.ZERO
var _rotulo: Label
var _menu: PanelContainer
var _sobre: Control
var _pontos := {}
var _assinatura := ""
var _treinadores: Array = []
var _prox_golpe := 1.0


func _ready() -> void:
	theme = Tema.tema()
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_PASS
	_palco = Node2D.new()
	add_child(_palco)
	_fundo = Fundo.new()
	_palco.add_child(_fundo)
	_entes = Node2D.new()
	_palco.add_child(_entes)
	_sobre = Control.new()
	_sobre.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_sobre.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_sobre)
	resized.connect(_ao_redimensionar)
	Jogo.mudou.connect(_ao_mudar)
	visibility_changed.connect(func() -> void: if is_visible_in_tree(): _montar())
	_ao_redimensionar()
	if not Jogo.e.is_empty():
		_montar()


func _ao_redimensionar() -> void:
	if size.x <= 1.0:
		return
	custom_minimum_size.y = size.x * PALCO.y / PALCO.x
	_k = minf(size.x / PALCO.x, size.y / PALCO.y) if size.y > 1.0 else size.x / PALCO.x
	_org = Vector2((size.x - PALCO.x * _k) / 2.0, (size.y - PALCO.y * _k) / 2.0 if size.y > 1.0 else 0.0)
	_palco.position = _org
	_palco.scale = Vector2(_k, _k)
	_posicionar()


func _ao_mudar() -> void:
	if is_visible_in_tree() and not Jogo.e.is_empty():
		_montar()


func _px(r: Rect2) -> Rect2:
	return Rect2(_org + r.position * _k, r.size * _k)


func _posicionar() -> void:
	for n in _pontos:
		var p: Dictionary = _pontos[n]
		var b: Control = p["no"]
		var r := _px(p["rect"])
		b.position = r.position
		b.size = r.size
	if _rotulo:
		_rotulo.position = Vector2(0, _org.y + 52.0 * _k)
		_rotulo.size = Vector2(size.x, 40)
		_rotulo.add_theme_font_size_override("font_size", maxi(14, int(26.0 * _k)))
	if _menu and _pontos.has("portao"):
		var rp := _px(_pontos["portao"]["rect"])
		_menu.position = rp.position + Vector2(rp.size.x + 8.0, 40.0 * _k)


func _montar() -> void:
	var e: Dictionary = Jogo.e
	var casa := Game.lanista_da_casa(e)
	var ass := "%s|%s|%s" % [JSON.stringify(e["melhorias"]), str(e["gladiadores"].map(func(g: Dictionary) -> String: return "%s%s%s%s" % [g["id"], g["classe"], str(g.get("semEstilo", false)), str(g["vivo"])])), str(casa.get("nome", ""))]
	if ass == _assinatura:
		return
	_assinatura = ass
	for c in _entes.get_children():
		c.queue_free()
	for c in _sobre.get_children():
		c.queue_free()
	_pontos.clear()
	_treinadores.clear()
	for s in SALAS:
		_fundo.construidas[s[0]] = Game.tem_melhoria(e, s[0])
	_fundo.construidas["palus"] = Game.tem_melhoria(e, "palus")
	_montar_gladiadores(e)
	_montar_doctore()
	_montar_controles(casa)
	_ao_redimensionar()


func _montar_gladiadores(e: Dictionary) -> void:
	var lista: Array = e["gladiadores"]
	var treino_ok := Game.tem_melhoria(e, "palus")
	var livres: Array = VAGAS.duplicate()
	var vagas_t: Array = VAGAS_TREINO.duplicate()
	for g: Dictionary in lista:
		if not g["vivo"]:
			continue
		var perto_palus: bool = treino_ok and not vagas_t.is_empty() and not bool(g.get("semEstilo", false))
		var pos: Vector2
		if perto_palus:
			pos = vagas_t.pop_front()
		elif not livres.is_empty():
			pos = livres.pop_front()
		else:
			pos = Vector2(260.0 + randf() * 640.0, 480.0 + randf() * 170.0)
		var prof := clampf((pos.y - 450.0) / 230.0, 0.0, 1.0)
		var esc := 0.74 + 0.30 * prof
		var virado: bool = perto_palus or pos.x > 640.0
		var no: Node2D
		var altura := 181.0 * esc
		if g.get("semEstilo", false):
			no = Node2D.new()
			var sp := Sprite2D.new()
			sp.texture = Sprites.escravo(str(g["terra"]), int(g["look"]), str(g.get("condicao", "")))
			sp.centered = false
			var ts: Vector2 = sp.texture.get_size()
			var f := (altura * 0.82) / ts.y
			sp.scale = Vector2(f * (-1.0 if virado else 1.0), f)
			sp.position = Vector2(ts.x * f / 2.0 * (1.0 if virado else -1.0), -ts.y * f)
			no.add_child(sp)
			no.position = pos
		else:
			var lut := LutadorLuta.new(str(g["id"]), str(g["classe"]), esc, virado, 1.0, pos)
			no = lut
			if perto_palus:
				_treinadores.append(lut)
		no.z_index = int(pos.y)
		_entes.add_child(no)
		var b := Button.new()
		b.flat = true
		b.focus_mode = Control.FOCUS_NONE
		b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		for sn in ["normal", "hover", "pressed", "focus", "disabled", "hover_pressed"]:
			b.add_theme_stylebox_override(sn, StyleBoxEmpty.new())
		b.tooltip_text = "%s · nível %d. Clique para ver a ficha." % [g["nome"], int(g["nivel"])]
		var gid: String = g["id"]
		b.pressed.connect(func() -> void: ModalGladiador.abrir(self, gid))
		_sobre.add_child(b)
		_pontos["g_" + gid] = {"no": b, "rect": Rect2(pos.x - 42.0 * esc * 1.3, pos.y - altura, 84.0 * esc * 1.3, altura)}


func _montar_doctore() -> void:
	var d := LutadorLuta.new("doctore", "samnita", 0.98, true, 1.0, Vector2(660, 470))
	d.z_index = 470
	_entes.add_child(d)
	d.modulate = Color(0.78, 0.64, 0.52)
	var l := Label.new()
	l.text = "DOCTORE"
	l.add_theme_font_override("font", Tema.fonte_titulo)
	l.add_theme_font_size_override("font_size", 13)
	l.add_theme_color_override("font_color", Tema.OURO)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	l.add_theme_constant_override("outline_size", 4)
	l.position = Vector2(-30, -200)
	l.z_index = 4000
	d.add_child(l)
	l.scale = Vector2(1.0 * d.frente, 1.0)
	l.position = Vector2(-32 if d.frente > 0 else 32, -204)


func _montar_controles(casa: Dictionary) -> void:
	var e: Dictionary = Jogo.e
	var portao := CenaLudus.Ponto.new()
	portao.tipo = "portao"
	portao.tooltip_text = "Portão do ludus: escolher mercado ou arena"
	portao.pressed.connect(func() -> void: _menu.visible = not _menu.visible)
	_sobre.add_child(portao)
	_pontos["portao"] = {"no": portao, "rect": Rect2(0, 316, 130, 280)}
	for s in SALAS:
		var id: String = s[0]
		if id in ["armaria", "enfermaria"] and Game.tem_melhoria(e, id):
			var ic := CenaLudus.Ponto.new()
			ic.tipo = id
			var aba := "armeiro" if id == "armaria" else "enfermaria"
			ic.pressed.connect(func() -> void: Jogo.abrir_aba.emit(aba))
			_sobre.add_child(ic)
			_pontos["ic_" + id] = {"no": ic, "rect": Rect2(float(s[2]) - 24.0, 286, 48, 48)}
		elif not Game.tem_melhoria(e, id):
			var bt := Button.new()
			bt.flat = true
			bt.focus_mode = Control.FOCUS_NONE
			bt.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
			for sn in ["normal", "hover", "pressed", "focus", "disabled", "hover_pressed"]:
				bt.add_theme_stylebox_override(sn, StyleBoxEmpty.new())
			bt.tooltip_text = "%s ainda não construído(a). Veja a aba Upgrades." % s[1].capitalize()
			bt.pressed.connect(func() -> void: Jogo.abrir_aba.emit("upgrades"))
			_sobre.add_child(bt)
			_pontos["c_" + id] = {"no": bt, "rect": Rect2(float(s[2]) - 85.0, 262, 170, 168)}
	_menu = PanelContainer.new()
	_menu.add_theme_stylebox_override("panel", Tema.caixa(Color(0.078, 0.047, 0.035, 0.95), Tema.OCRE, 8, 1, 10))
	_menu.z_index = 2000
	_menu.visible = false
	var vb := Tema.vbox(6)
	_menu.add_child(vb)
	vb.add_child(Tema.rotulo("Para onde ir?", 17, Tema.AREIA))
	var b1 := Tema.botao("Mercado de gladiadores", "primario", 17)
	b1.pressed.connect(func() -> void: _menu.visible = false; Jogo.abrir_aba.emit("mercado"))
	var b2 := Tema.botao("Arenas", "normal", 17)
	b2.pressed.connect(func() -> void: _menu.visible = false; Jogo.abrir_aba.emit("arenas"))
	vb.add_child(b1)
	vb.add_child(b2)
	_sobre.add_child(_menu)
	_rotulo = Label.new()
	_rotulo.text = "Ludus de %s" % str(casa.get("nome", ""))
	_rotulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_rotulo.add_theme_font_override("font", Tema.fonte_titulo)
	_rotulo.add_theme_color_override("font_color", Tema.OURO)
	_rotulo.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.95))
	_rotulo.add_theme_constant_override("outline_size", 6)
	_rotulo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_sobre.add_child(_rotulo)


func _process(delta: float) -> void:
	if _treinadores.is_empty():
		return
	_prox_golpe -= delta
	if _prox_golpe <= 0.0:
		_prox_golpe = randf_range(1.6, 3.2)
		var l: LutadorLuta = _treinadores[randi() % _treinadores.size()]
		if is_instance_valid(l):
			l.golpear("corte")
