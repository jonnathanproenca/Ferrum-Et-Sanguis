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
	"elmo": Vector2(188, 4), "amuleto": Vector2(298, 12), "peito": Vector2(188, 106),
	"arma": Vector2(56, 196), "acessorio": Vector2(320, 196), "calca": Vector2(188, 192), "pe": Vector2(188, 332),
}
const ROTULO := {"elmo": "Elmo", "amuleto": "Amuleto", "peito": "Peito", "arma": "Arma", "acessorio": "Escudo", "calca": "Calça", "pe": "Pés"}
const COR_AMULETO := Color("b894e0")

var g: Dictionary = {}
var _slots := {}
var _fundo_sem: Label


func _init() -> void:
	estilo = int(OS.get_environment("BONECO")) if OS.get_environment("BONECO") != "" else 0
	custom_minimum_size = Vector2(LARGURA, ALTURA)
	size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func construir(g_: Dictionary) -> void:
	g = g_
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


## 0 = sombra anatômica, 1 = homem vitruviano (linhas), 2 = estátua de mármore
var estilo := 0

func _juntas(aberto: bool) -> Dictionary:
	var j := {
		"cabeca": Vector2(220, 40), "pescoco": Vector2(220, 66),
		"ombro_e": Vector2(170, 94), "ombro_d": Vector2(270, 94),
		"quadril_e": Vector2(196, 222), "quadril_d": Vector2(244, 222),
		"joelho_e": Vector2(190, 304), "joelho_d": Vector2(250, 304),
		"pe_e": Vector2(184, 380), "pe_d": Vector2(256, 380),
	}
	if aberto:
		j["cotovelo_e"] = Vector2(112, 100); j["cotovelo_d"] = Vector2(328, 100)
		j["mao_e"] = Vector2(54, 104); j["mao_d"] = Vector2(386, 104)
		j["joelho_e"] = Vector2(170, 304); j["joelho_d"] = Vector2(270, 304)
		j["pe_e"] = Vector2(150, 378); j["pe_d"] = Vector2(290, 378)
	else:
		j["cotovelo_e"] = Vector2(134, 156); j["cotovelo_d"] = Vector2(306, 156)
		j["mao_e"] = Vector2(104, 214); j["mao_d"] = Vector2(336, 214)
	return j

func _membro(a: Vector2, b: Vector2, w: float, col: Color) -> void:
	draw_line(a, b, col, w, true)
	draw_circle(a, w / 2.0, col)
	draw_circle(b, w / 2.0, col)

func _corpo(col: Color, ex: float, aberto: bool) -> void:
	var j := _juntas(aberto)
	var tor := PackedVector2Array([Vector2(168, 88), Vector2(272, 88), Vector2(264, 140), Vector2(248, 184), Vector2(246, 228), Vector2(194, 228), Vector2(192, 184), Vector2(176, 140)])
	draw_colored_polygon(tor, col)
	if ex > 0.0:
		var f: PackedVector2Array = tor.duplicate()
		f.append(tor[0])
		draw_polyline(f, col, ex * 2.0, true)
	draw_circle(j["cabeca"], 24.0 + ex, col)
	_membro(j["pescoco"], j["cabeca"], 16.0 + ex * 2, col)
	for l in ["e", "d"]:
		_membro(j["ombro_" + l], j["cotovelo_" + l], 24.0 + ex * 2, col)
		_membro(j["cotovelo_" + l], j["mao_" + l], 19.0 + ex * 2, col)
		_membro(j["quadril_" + l], j["joelho_" + l], 36.0 + ex * 2, col)
		_membro(j["joelho_" + l], j["pe_" + l], 27.0 + ex * 2, col)
		draw_circle(j["ombro_" + l], 16.0 + ex, col)

func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size)
	draw_rect(r, Color("0e0a08"))
	var c := Vector2(LARGURA / 2.0, ALTURA * 0.46)
	for i in range(14):
		var k := float(i) / 13.0
		draw_circle(c, 210.0 * (1.0 - k), Color(0.80, 0.55, 0.25, 0.012 + 0.012 * k))
	draw_rect(r, Color(Tema.OURO_ESCURO, 0.9), false, 2.0)
	draw_rect(Rect2(Vector2(5, 5), size - Vector2(10, 10)), Color(Tema.OURO_ESCURO, 0.3), false, 1.0)
	match estilo:
		0:
			_corpo(Color(Tema.OURO_ESCURO, 0.55), 2.5, false)
			_corpo(Color(0.06, 0.045, 0.04), 0.0, false)
			# volume: luz lateral suave
			var luz := Color(0.20, 0.14, 0.10, 0.55)
			draw_line(Vector2(184, 104), Vector2(190, 214), luz, 8.0, true)
			draw_line(Vector2(176, 250), Vector2(182, 360), luz, 8.0, true)
		1:
			var fio := Color(Tema.OURO_ESCURO, 0.5)
			draw_arc(Vector2(220, 212), 186.0, 0, TAU, 96, fio, 1.5, true)
			draw_rect(Rect2(Vector2(60, 28), Vector2(320, 350)), Color(Tema.OURO_ESCURO, 0.3), false, 1.5)
			draw_line(Vector2(20, 104), Vector2(420, 104), Color(Tema.OURO_ESCURO, 0.2), 1.0)
			draw_line(Vector2(220, 14), Vector2(220, 392), Color(Tema.OURO_ESCURO, 0.2), 1.0)
			_corpo(Color(Tema.OURO, 0.55), 1.2, true)
			_corpo(Color("0e0a08"), 0.0, true)
		2:
			draw_rect(Rect2(Vector2(120, 388), Vector2(200, 12)), Color(0.42, 0.38, 0.33))
			draw_rect(Rect2(Vector2(120, 388), Vector2(200, 3)), Color(0.62, 0.57, 0.5))
			_corpo(Color(0.30, 0.27, 0.23), 2.0, false)
			_corpo(Color(0.50, 0.46, 0.40), 0.0, false)
			var luz2 := Color(0.68, 0.63, 0.55, 0.7)
			draw_line(Vector2(186, 104), Vector2(192, 212), luz2, 9.0, true)
			draw_line(Vector2(176, 252), Vector2(182, 356), luz2, 9.0, true)
			draw_circle(Vector2(213, 34), 8.0, luz2)
			var sombra := Color(0.34, 0.30, 0.26, 0.6)
			draw_line(Vector2(256, 104), Vector2(250, 214), sombra, 7.0, true)
			draw_line(Vector2(264, 252), Vector2(258, 356), sombra, 7.0, true)


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
