class_name Tema
extends RefCounted
## Tema visual do jogo (cores do Redux, fontes Cinzel e EB Garamond) e fábricas de controles.

const BG := Color("120c0a")
const PAINEL := Color("1d1411")
const PAINEL_2 := Color("2a1c16")
const BORDA := Color("4a2a1e")
const OCRE := Color("c2895a")
const OURO := Color("f2d28a")
const OURO_ESCURO := Color("c9a24a")
const SANGUE := Color("8a1c1c")
const SANGUE_CLARO := Color("b8281c")
const AREIA := Color("e8d5b0")
const VERDE := Color("8fbf7a")
const CINZA := Color("a8957f")

## Cor de cada um dos 6 atributos (forca, destreza, vitalidade, resistencia, inteligencia, aura).
const COR_ATRIBUTO := {"forca": Color("d9694a"), "destreza": Color("8fcf7a"), "vitalidade": Color("e08a9a"),
	"resistencia": Color("d9a63e"), "inteligencia": Color("6aa6d8"), "aura": Color("b894e0")}

static var _tema: Theme
static var fonte_titulo: Font
static var fonte_corpo: Font

static func caixa(cor: Color, borda: Color = BORDA, raio: int = 6, esp: int = 1, margem: int = 8) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = cor
	s.border_color = borda
	s.set_border_width_all(esp)
	s.set_corner_radius_all(raio)
	s.content_margin_left = margem + 4
	s.content_margin_right = margem + 4
	s.content_margin_top = margem
	s.content_margin_bottom = margem
	return s

static func tema() -> Theme:
	if _tema:
		return _tema
	fonte_titulo = load("res://assets/fontes/Cinzel.ttf")
	fonte_corpo = load("res://assets/fontes/EBGaramond.ttf")
	var t := Theme.new()
	t.default_font = fonte_corpo
	t.default_font_size = 18
	for c in ["Label", "RichTextLabel", "CheckBox", "OptionButton", "ItemList"]:
		t.set_color("font_color", c, AREIA)
	t.set_color("default_color", "RichTextLabel", AREIA)
	# Botões
	t.set_stylebox("normal", "Button", caixa(PAINEL, BORDA, 6, 1, 6))
	t.set_stylebox("hover", "Button", caixa(PAINEL_2, OCRE, 6, 1, 6))
	t.set_stylebox("pressed", "Button", caixa(SANGUE, OURO, 6, 1, 6))
	t.set_stylebox("disabled", "Button", caixa(Color("181010"), Color("2a1c16"), 6, 1, 6))
	t.set_stylebox("focus", "Button", caixa(Color(0, 0, 0, 0), OURO_ESCURO, 6, 2, 6))
	t.set_color("font_color", "Button", AREIA)
	t.set_color("font_hover_color", "Button", OURO)
	t.set_color("font_pressed_color", "Button", OURO)
	t.set_color("font_disabled_color", "Button", Color("6b5a4a"))
	t.set_constant("h_separation", "Button", 8)
	# Painéis
	t.set_stylebox("panel", "PanelContainer", caixa(PAINEL, BORDA, 8, 1, 10))
	t.set_stylebox("panel", "Panel", caixa(PAINEL, BORDA, 8, 1, 10))
	# OptionButton / PopupMenu
	t.set_stylebox("normal", "OptionButton", caixa(PAINEL, BORDA, 6, 1, 4))
	t.set_stylebox("hover", "OptionButton", caixa(PAINEL_2, OCRE, 6, 1, 4))
	t.set_stylebox("pressed", "OptionButton", caixa(PAINEL_2, OURO, 6, 1, 4))
	t.set_stylebox("disabled", "OptionButton", caixa(Color("181010"), Color("2a1c16"), 6, 1, 4))
	t.set_color("font_color", "OptionButton", AREIA)
	t.set_color("font_hover_color", "OptionButton", OURO)
	t.set_stylebox("panel", "PopupMenu", caixa(PAINEL, OURO_ESCURO, 4, 1, 4))
	t.set_stylebox("hover", "PopupMenu", caixa(SANGUE, SANGUE, 3, 0, 2))
	t.set_color("font_color", "PopupMenu", AREIA)
	t.set_color("font_hover_color", "PopupMenu", OURO)
	# Barras de rolagem discretas
	var grab := caixa(BORDA, BORDA, 4, 0, 0)
	t.set_stylebox("grabber", "VScrollBar", grab)
	t.set_stylebox("grabber_highlight", "VScrollBar", caixa(OCRE, OCRE, 4, 0, 0))
	t.set_stylebox("grabber_pressed", "VScrollBar", caixa(OURO, OURO, 4, 0, 0))
	t.set_stylebox("scroll", "VScrollBar", caixa(Color(0, 0, 0, 0.2), Color(0, 0, 0, 0), 4, 0, 0))
	t.set_stylebox("grabber", "HScrollBar", grab)
	t.set_stylebox("scroll", "HScrollBar", caixa(Color(0, 0, 0, 0.2), Color(0, 0, 0, 0), 4, 0, 0))
	t.set_stylebox("separator", "HSeparator", caixa(BORDA, BORDA, 0, 0, 0))
	_tema = t
	return t

# ---------- Fábricas ----------

## tipo: "normal", "primario" (vermelho), "ouro"
static func botao(texto: String, tipo: String = "normal", tam_fonte: int = 18) -> Button:
	var b := Button.new()
	b.text = texto
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", tam_fonte)
	b.custom_minimum_size = Vector2(0, 40)
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	if tipo == "primario":
		b.add_theme_stylebox_override("normal", caixa(SANGUE, OURO_ESCURO, 6, 1, 6))
		b.add_theme_stylebox_override("hover", caixa(Color("a52424"), OURO, 6, 1, 6))
		b.add_theme_stylebox_override("pressed", caixa(Color("6a1414"), OURO, 6, 1, 6))
		b.add_theme_color_override("font_color", AREIA)
	elif tipo == "ouro":
		b.add_theme_stylebox_override("normal", caixa(Color("3a2a14"), OURO_ESCURO, 6, 1, 6))
		b.add_theme_stylebox_override("hover", caixa(Color("4a3618"), OURO, 6, 1, 6))
		b.add_theme_color_override("font_color", OURO)
	return b

static func rotulo(texto: String, tam: int = 18, cor: Color = AREIA, titulo: bool = false) -> Label:
	var l := Label.new()
	l.text = texto
	l.add_theme_font_size_override("font_size", tam)
	l.add_theme_color_override("font_color", cor)
	if titulo:
		l.add_theme_font_override("font", fonte_titulo)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l

static func titulo(texto: String, tam: int = 28) -> Label:
	var l := rotulo(texto, tam, OURO, true)
	l.autowrap_mode = TextServer.AUTOWRAP_OFF
	return l

static func painel(cor: Color = PAINEL, borda: Color = BORDA) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", caixa(cor, borda, 8, 1, 10))
	return p

static func vbox(sep: int = 8) -> VBoxContainer:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", sep)
	return v

static func hbox(sep: int = 8) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", sep)
	return h

static func espaco(h: int = 8) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, h)
	return c

## Textura de um arquivo de assets/ ("assets/ludus/base.png" ou caminho res://).
static func textura(caminho: String) -> Texture2D:
	var p := caminho if caminho.begins_with("res://") else "res://" + caminho
	return load(p) if ResourceLoader.exists(p) else null

static func limpar(no: Node) -> void:
	for c in no.get_children():
		no.remove_child(c)
		c.queue_free()
