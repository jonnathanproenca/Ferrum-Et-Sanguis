class_name CenaEstatica
extends Control
## Cena de fundo (imagem 1376x768) com elementos posicionados por fração da imagem: animações, brilhos pulsantes.
## Use dentro de um AspectRatioContainer (razão w/h) para manter a proporção.

var img_w: float = 1376.0
var img_h: float = 768.0
var _itens: Array = []   ## {no, rect(Rect2 em px da imagem), escala_tam(bool)}

func _init(fundo: String, w: float = 1376.0, h: float = 768.0) -> void:
	img_w = w
	img_h = h
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(160, 160.0 * h / w)
	var tr := TextureRect.new()
	tr.texture = Tema.textura(fundo)
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_SCALE
	tr.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(tr)
	resized.connect(_reposicionar)

## Adiciona um nó cobrindo o retângulo `r` (pixels da imagem original).
func colocar(no: Control, r: Rect2) -> void:
	no.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(no)
	_itens.append({"no": no, "rect": r})
	_reposicionar()

## Brilho radial aditivo centrado em (x,y) com raio r; pulsa em loop. Cor laranja de fogo por padrão.
func brilho(x: float, y: float, r: float, cor: Color = Color(1.0, 0.6, 0.2), periodo: float = 1.1) -> Control:
	var c := _gradiente(cor, 1.0)
	colocar(c, Rect2(x - r, y - r, r * 2.0, r * 2.0))
	_pulsar(c, periodo, 0.6, 1.0)
	return c

## Luz elíptica (retângulo do chão) que respira devagar.
func luz(rect: Rect2, cor: Color = Color(1.0, 0.92, 0.66), periodo: float = 4.0) -> Control:
	var c := _gradiente(cor, 0.55)
	colocar(c, rect)
	_pulsar(c, periodo, 0.55, 1.0)
	return c

func _gradiente(cor: Color, alfa: float) -> TextureRect:
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.45, 1.0])
	g.colors = PackedColorArray([Color(cor, alfa), Color(cor, alfa * 0.3), Color(cor, 0.0)])
	var t := GradientTexture2D.new()
	t.gradient = g
	t.fill = GradientTexture2D.FILL_RADIAL
	t.fill_from = Vector2(0.5, 0.5)
	t.fill_to = Vector2(1.0, 0.5)
	t.width = 128
	t.height = 128
	var tr := TextureRect.new()
	tr.texture = t
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_SCALE
	var m := CanvasItemMaterial.new()
	m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	tr.material = m
	return tr

func _pulsar(no: Control, periodo: float, de: float, ate: float) -> void:
	no.modulate.a = de
	var tw := no.create_tween().set_loops()
	tw.tween_property(no, "modulate:a", ate, periodo).set_trans(Tween.TRANS_SINE)
	tw.tween_property(no, "modulate:a", de, periodo).set_trans(Tween.TRANS_SINE)

func _reposicionar() -> void:
	if size.x <= 0.0:
		return
	var k := Vector2(size.x / img_w, size.y / img_h)
	for it in _itens:
		var r: Rect2 = it["rect"]
		var no: Control = it["no"]
		no.position = r.position * k
		no.size = r.size * k
