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
	var tr := TextureRect.new()
	tr.texture = textura(item)
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_child(tr)
	return p

static func fmt_bonus(b: Dictionary) -> String:
	var partes: Array = []
	for k in Model.ATRIBUTOS:
		var v: int = int(b.get(k, 0))
		if v != 0:
			partes.append("%s %s%d" % [Model.SIGLA_ATRIBUTO[k], "+" if v > 0 else "", v])
	return ", ".join(partes) if not partes.is_empty() else "sem bônus"
