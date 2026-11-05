class_name IconeItem
extends RefCounted
## Ícones dos itens do armeiro (assets/itens/<id>.png) com moldura na cor da qualidade (porte de icones.ts).

static func cor_qualidade(q: int) -> Color:
	return Color(Model.COR_QUALIDADE[clampi(q, 0, Model.QUALIDADE_MAX)])

## Itens básicos reusam o ícone mais simples do mesmo tipo, conforme a classe.
static func _id_basico(slot: String, classe: String) -> String:
	var meio: bool = classe == "murmilo" or classe == "samnita"
	match slot:
		"arma":
			return "tridente" if classe == "retiario" else ("sica" if classe == "tracio" else "gladio")
		"acessorio":
			if classe == "retiario": return "rede"
			if classe == "tracio": return "escudo_redondo_pequeno"
			return "escudo_oval" if classe == "samnita" else "escudo_quadrado"
		"elmo":
			if classe == "murmilo": return "elmo_murmilo"
			if classe == "retiario": return "galero"
			return "capacete_frigio" if classe == "tracio" else "elmo_viseira"
		"peito":
			return "peito_leve"
		"pe":
			return "bota_legionaria" if meio else "sandalia"
	return "perneira_couro" if meio else "faixa_coxa"

static func arquivo(item: Dictionary) -> String:
	if item.get("basico", false) and not (item["classes"] as Array).is_empty():
		return _id_basico(item["slot"], item["classes"][0])
	return str(Model.separar_id(item["id"])["base"])

static func textura(item: Dictionary) -> Texture2D:
	return Tema.textura("assets/itens/%s.png" % arquivo(item))

## Caixa quadrada com o ícone e a moldura da qualidade; `tam` em pixels.
static func criar(item: Dictionary, tam: int = 44) -> Control:
	var q: int = int(item.get("qualidade", 0))
	var cor := cor_qualidade(q)
	var p := PanelContainer.new()
	var sb := Tema.caixa(Color(0.07, 0.045, 0.035), cor, 6, 2, 3)
	sb.content_margin_left = 3
	sb.content_margin_right = 3
	if q >= 3:
		sb.shadow_color = Color(cor, 0.45)
		sb.shadow_size = 6
	p.add_theme_stylebox_override("panel", sb)
	p.custom_minimum_size = Vector2(tam, tam)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if item.get("amuleto", false):
		p.add_child(_medalhao(item, cor))
		return p
	var tr := TextureRect.new()
	tr.texture = textura(item)
	if tr.texture == null:
		var gl := Glifo.novo("espadas", maxi(12, tam - 14), Color(cor, 0.7))
		gl.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		p.add_child(gl)
		return p
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_child(tr)
	return p

## Medalhão circular desenhado em código: aro na cor da qualidade, fundo escuro e o glifo do atributo.
class Medalhao extends Control:
	var cor := Color.WHITE
	var foco := "forca"
	var q := 0

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		size_flags_horizontal = Control.SIZE_EXPAND_FILL
		size_flags_vertical = Control.SIZE_EXPAND_FILL
		resized.connect(queue_redraw)

	func _draw() -> void:
		var s := minf(size.x, size.y)
		if s <= 4.0:
			return
		var c := size / 2.0
		var r := s / 2.0 - 1.0
		draw_line(Vector2(c.x, 0), Vector2(c.x, c.y - r * 0.55), cor.darkened(0.3), maxf(1.5, s * 0.06), true)
		draw_circle(c, r, cor.darkened(0.45))
		draw_circle(c, r * 0.86, Color(0.1, 0.07, 0.05))
		draw_arc(c, r * 0.86, 0.0, TAU, 32, cor, maxf(1.5, s * 0.06), true)
		draw_circle(c, r * 0.5, Color(cor, 0.16))

static func _medalhao(item: Dictionary, cor: Color) -> Control:
	var m := Medalhao.new()
	m.cor = cor
	m.foco = str(item.get("foco", "forca"))
	m.q = int(item.get("qualidade", 0))
	var gl := Glifo.novo(m.foco, 10, cor.lightened(0.25))
	gl.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	gl.anchor_left = 0.25
	gl.anchor_right = 0.75
	gl.anchor_top = 0.3
	gl.anchor_bottom = 0.8
	gl.offset_left = 0
	gl.offset_right = 0
	gl.offset_top = 0
	gl.offset_bottom = 0
	gl.size_flags_vertical = Control.SIZE_FILL
	m.add_child(gl)
	return m

static func fmt_bonus(b: Dictionary) -> String:
	var partes: Array = []
	for k in Model.ATRIBUTOS:
		var v: int = int(b.get(k, 0))
		if v != 0:
			partes.append("%s %s%d" % [Model.SIGLA_ATRIBUTO[k], "+" if v > 0 else "", v])
	return ", ".join(partes) if not partes.is_empty() else "sem bônus"
