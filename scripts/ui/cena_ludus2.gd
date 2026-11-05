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

## Doctore: animação em quadros (caminhada em loop + chicotada), recortada de vídeo, com a âncora nos pés de cada quadro.
class Doctore extends Node2D:
	const DIR := "assets/ludus/doctore/"
	var frente := 1.0
	var ocupado := false  ## true enquanto toca a chicotada
	var _meta: Dictionary
	var _spr := Sprite2D.new()
	var _tex := {}
	var _clip := "andar"
	var _t_clip := 0.0
	var _proximo := 3.0

	func _init() -> void:
		_meta = Util.ler_json("res://" + DIR + "doctore.json")
		for nome in ["andar", "chicote"]:
			for q: Dictionary in _meta[nome]:
				_tex[q["f"]] = Tema.textura(DIR + str(q["f"]))
		_spr.centered = false
		add_child(_spr)
		scale = Vector2(0.6, 0.6)
		_mostrar(0)

	func _draw() -> void:
		var pts := PackedVector2Array()
		for i in range(24):
			var a := TAU * i / 24.0
			pts.append(Vector2(cos(a) * 62.0, sin(a) * 9.0))
		draw_colored_polygon(pts, Color(0, 0, 0, 0.32))

	func _mostrar(i: int) -> void:
		var q: Dictionary = (_meta[_clip] as Array)[i]
		_spr.texture = _tex[q["f"]]
		_spr.position = -Vector2(q["ancora"][0], q["ancora"][1])

	func chicotear() -> void:
		ocupado = true
		_clip = "chicote"
		_t_clip = 0.0

	func _process(delta: float) -> void:
		_t_clip += delta
		var n: int = (_meta[_clip] as Array).size()
		var fps: float = float(_meta["fps"])
		var q := int(_t_clip * fps)
		if _clip == "chicote":
			if q >= n:
				ocupado = false
				_clip = "andar"
				_t_clip = float(_meta["volta"]) / fps
				_proximo = randf_range(3.0, 7.0)
				q = int(_t_clip * fps)
				n = (_meta[_clip] as Array).size()
				_mostrar(q % n)
				return
			_mostrar(q)
			return
		_proximo -= delta
		if _proximo <= 0.0:
			chicotear()
			return
		_mostrar(q % n)


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
		_ponto_doctore += delta
		var u := _tri(_ponto_doctore / 8.0)
		var x := lerpf(250.0, 600.0, u)
		var vai := fposmod(_ponto_doctore, 16.0) < 8.0
		_doctore.position = Vector2(x, 458.0)
		_doctore.scale.x = 0.6 * (1.0 if vai else -1.0)
	if not _treinadores.is_empty() and is_visible_in_tree():
		_prox_golpe -= delta
		if _prox_golpe <= 0.0:
			_prox_golpe = randf_range(1.6, 3.2)
			var l: LutadorLuta = _treinadores[randi() % _treinadores.size()]
			if is_instance_valid(l) and l.is_inside_tree():
				l.golpear("corte")
