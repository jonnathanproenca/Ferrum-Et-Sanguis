class_name BonecoEquipamento
extends Control
## "Boneco" de equipamentos: silhueta do gladiador ao centro e os 7 slots como caixas quadradas ao redor
## (estilo tela de personagem do Diablo 3). Emite `slot_clicado(slot)`; quem usa abre o seletor.

signal slot_clicado(slot: String)

const TAM_SLOT := 64.0
const TAM_ICONE := 56
const LARGURA := 440.0
const ALTURA := 404.0
## Posição (canto superior esquerdo) de cada slot dentro do boneco.
const POS := {
	"elmo": Vector2(188, 0), "amuleto": Vector2(318, 28), "peito": Vector2(52, 96),
	"arma": Vector2(52, 204), "acessorio": Vector2(324, 204), "calca": Vector2(188, 250), "pe": Vector2(188, 340),
}
const ROTULO := {"elmo": "Elmo", "amuleto": "Amuleto", "peito": "Peito", "arma": "Arma", "acessorio": "Escudo", "calca": "Calça", "pe": "Pés"}
const COR_AMULETO := Color("b894e0")

var g: Dictionary = {}
var _slots := {}
var _sombra: TextureRect
var _fundo_sem: Label


func _init() -> void:
	custom_minimum_size = Vector2(LARGURA, ALTURA)
	size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func construir(g_: Dictionary) -> void:
	g = g_
	_sombra = TextureRect.new()
	_sombra.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_sombra.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_sombra.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_sombra.position = Vector2(LARGURA / 2.0 - 125.0, 4)
	_sombra.size = Vector2(250, ALTURA - 8)
	add_child(_sombra)
	for slot in POS:
		var s := Slot.new()
		s.slot = slot
		s.position = POS[slot]
		s.size = Vector2(TAM_SLOT, TAM_SLOT)
		s.clicado.connect(func(sl: String) -> void: slot_clicado.emit(sl))
		add_child(s)
		_slots[slot] = s
	atualizar(g)


func atualizar(g_: Dictionary = {}) -> void:
	if not g_.is_empty():
		g = g_
	var sem: bool = g.get("semEstilo", false)
	var tex: Texture2D = Sprites.escravo(g["terra"], int(g["look"]), str(g.get("condicao", ""))) if sem else Sprites.pose(g["classe"], "guarda")
	_sombra.texture = tex
	_sombra.modulate = Color(0.17, 0.11, 0.09, 0.96)
	var armaria := Game.tem_melhoria(Jogo.e, "armaria")
	for slot in POS:
		var s: Slot = _slots[slot]
		var id = null if sem else g["equipamento"].get(slot)
		var item: Dictionary = Model.item_por_id(id) if id != null else {}
		var motivo := ""
		if sem:
			motivo = "Defina o estilo do gladiador primeiro."
		elif not armaria:
			motivo = "Construa a armaria para equipar."
		s.definir(item, motivo)


func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size)
	draw_rect(r, Color("0e0a08"))
	# brilho atrás da silhueta
	var c := Vector2(LARGURA / 2.0, ALTURA * 0.46)
	for i in range(14):
		var k := float(i) / 13.0
		draw_circle(c, 210.0 * (1.0 - k), Color(0.80, 0.55, 0.25, 0.012 + 0.012 * k))
	draw_rect(r, Color(Tema.OURO_ESCURO, 0.9), false, 2.0)
	draw_rect(Rect2(Vector2(5, 5), size - Vector2(10, 10)), Color(Tema.OURO_ESCURO, 0.3), false, 1.0)
	# fios ligando os slots ao corpo
	var fio := Color(Tema.OURO_ESCURO, 0.28)
	for slot in POS:
		var p: Vector2 = POS[slot] + Vector2(TAM_SLOT, TAM_SLOT) / 2.0
		if absf(p.x - c.x) < 4.0:
			continue
		var alvo := Vector2(c.x + (-40.0 if p.x < c.x else 40.0), p.y)
		var de := p + Vector2(TAM_SLOT / 2.0 * (1.0 if p.x < c.x else -1.0), 0)
		draw_line(de, alvo, fio, 1.0)


## Caixa de um slot: ícone do item (moldura da qualidade) ou rótulo discreto do tipo quando vazio.
class Slot extends PanelContainer:
	signal clicado(slot: String)
	var slot := ""
	var item: Dictionary = {}
	var motivo := ""
	var _hover := false

	func _init() -> void:
		mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		mouse_entered.connect(func() -> void: _hover = true; _estilo())
		mouse_exited.connect(func() -> void: _hover = false; _estilo())

	func definir(item_: Dictionary, motivo_: String) -> void:
		item = item_
		motivo = motivo_
		Tema.limpar(self)
		var ro: String = BonecoEquipamento.ROTULO[slot]
		var amu := slot == "amuleto"
		if item.is_empty():
			var cen := CenterContainer.new()
			cen.mouse_filter = Control.MOUSE_FILTER_IGNORE
			add_child(cen)
			var l := Tema.rotulo(ro, 14, Color(BonecoEquipamento.COR_AMULETO if amu else Tema.CINZA, 0.75))
			l.autowrap_mode = TextServer.AUTOWRAP_OFF
			l.mouse_filter = Control.MOUSE_FILTER_IGNORE
			cen.add_child(l)
		else:
			var ic := IconeItem.criar(item, BonecoEquipamento.TAM_ICONE)
			ic.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			ic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			add_child(ic)
		_estilo()
		tooltip_text = _tip()

	func _tip() -> String:
		var nome_slot: String = Model.NOME_SLOT[slot]
		if item.is_empty():
			return "%s: vazio.%s" % [nome_slot, ("\n" + motivo) if motivo != "" else "\nClique para escolher."]
		var t := "%s\n%s · %s\nBônus: %s\nPeso %d" % [item["nome"], nome_slot, Model.QUALIDADES[int(item["qualidade"])], IconeItem.fmt_bonus(item["bonus"]), int(item["peso"])]
		if int(item["forcaMin"]) > 0:
			t += " · Força mín. %d" % int(item["forcaMin"])
		return t + (("\n" + motivo) if motivo != "" else "\nClique para trocar.")

	func _estilo() -> void:
		var amu := slot == "amuleto"
		var borda: Color = BonecoEquipamento.COR_AMULETO if amu else Tema.OURO_ESCURO
		var sb := Tema.caixa(Color(0.05, 0.035, 0.03, 0.92), borda.lightened(0.25) if _hover else (borda if not item.is_empty() or amu else Color(borda, 0.55)), 8 if amu else 4, 3 if amu else 2, 3)
		sb.content_margin_left = 3
		sb.content_margin_right = 3
		if amu:
			sb.set_corner_radius_all(32)
			sb.shadow_color = Color(borda, 0.35)
			sb.shadow_size = 8
		if _hover:
			sb.shadow_color = Color(Tema.OURO, 0.4)
			sb.shadow_size = 8
		if motivo != "":
			sb.bg_color = Color(0.03, 0.02, 0.02, 0.92)
		add_theme_stylebox_override("panel", sb)

	func _gui_input(ev: InputEvent) -> void:
		if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT and motivo == "":
			clicado.emit(slot)
