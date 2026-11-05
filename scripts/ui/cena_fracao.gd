class_name CenaFracao
extends Control
## Cena de fundo (imagem de referência 1376x768) com camadas posicionadas por fração da imagem.
## Modo "cobrir": a imagem preenche o controle (recortando o excesso); `foco_y` é a fração vertical da imagem
## que fica no centro da janela, `foco_x` a horizontal. As camadas acompanham a escala e o recorte.

var textura: Texture2D
var ref := Vector2(1376, 768)
var foco_x := 0.5
var foco_y := 0.5
var _camadas: Array = []

func _init(tex: Texture2D = null, tamanho_ref: Vector2 = Vector2(1376, 768)) -> void:
	textura = tex
	ref = tamanho_ref
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR

## Escala e deslocamento atuais da imagem dentro do controle.
func _transformacao() -> Dictionary:
	var s: float = maxf(size.x / ref.x, size.y / ref.y)
	var ox: float = clampf(size.x * 0.5 - foco_x * ref.x * s, size.x - ref.x * s, 0.0)
	var oy: float = clampf(size.y * 0.5 - foco_y * ref.y * s, size.y - ref.y * s, 0.0)
	return {"s": s, "o": Vector2(ox, oy)}

## Posiciona `no` sobre a imagem; `r` em pixels da imagem de referência.
func adicionar(no: Control, r: Rect2) -> void:
	no.mouse_filter = Control.MOUSE_FILTER_IGNORE
	no.custom_minimum_size = Vector2.ZERO
	no.set_anchors_preset(Control.PRESET_TOP_LEFT)
	add_child(no)
	_camadas.append({"no": no, "r": r})
	_ajustar()

## Brilho radial aditivo (como .forja-brilho do original) que pulsa suavemente.
func brilho(r: Rect2, cor: Color = Color(1.0, 0.59, 0.2)) -> void:
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.45, 0.7])
	g.colors = PackedColorArray([Color(cor, 0.55), Color(cor.r, cor.g * 0.73, cor.b * 0.6, 0.18), Color(cor.r, cor.g * 0.6, cor.b * 0.4, 0.0)])
	var gt := GradientTexture2D.new()
	gt.gradient = g
	gt.fill = GradientTexture2D.FILL_RADIAL
	gt.fill_from = Vector2(0.5, 0.5)
	gt.fill_to = Vector2(1.0, 0.5)
	gt.width = 128
	gt.height = 128
	var tr := TextureRect.new()
	tr.texture = gt
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_SCALE
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	tr.material = mat
	adicionar(tr, r)
	tr.pivot_offset = Vector2.ZERO
	var tw := tr.create_tween().set_loops()
	tr.modulate.a = 0.65
	tw.tween_property(tr, "modulate:a", 1.0, 0.55).set_trans(Tween.TRANS_SINE)
	tw.tween_property(tr, "modulate:a", 0.65, 0.55).set_trans(Tween.TRANS_SINE)

## Degradê escuro na base, para fundir a cena com o painel abaixo.
func desvanecer_base(altura: int, cor: Color) -> void:
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 1.0])
	g.colors = PackedColorArray([Color(cor, 0.0), Color(cor, 1.0)])
	var gt := GradientTexture2D.new()
	gt.gradient = g
	gt.fill_from = Vector2(0, 0)
	gt.fill_to = Vector2(0, 1)
	gt.width = 4
	gt.height = 64
	var tr := TextureRect.new()
	tr.texture = gt
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_SCALE
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tr.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	tr.offset_top = -altura
	tr.offset_bottom = 0
	add_child(tr)

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_ajustar()
		queue_redraw()

func _ajustar() -> void:
	if size.x <= 0.0 or size.y <= 0.0:
		return
	var t := _transformacao()
	var s: float = t["s"]
	var o: Vector2 = t["o"]
	for c in _camadas:
		var r: Rect2 = c["r"]
		var no: Control = c["no"]
		no.position = o + r.position * s
		no.size = r.size * s

func _draw() -> void:
	if textura == null:
		return
	var t := _transformacao()
	var s: float = t["s"]
	draw_texture_rect(textura, Rect2(t["o"], ref * s), false)
