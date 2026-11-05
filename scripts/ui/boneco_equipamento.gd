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

func _anatomia(col: Color, forte: bool) -> void:
	var w := 1.6 if forte else 1.0
	# clavículas, peitoral, abdômen, deltoides, joelhos
	draw_polyline(PackedVector2Array([Vector2(206, 92), Vector2(186, 98), Vector2(172, 96)]), col, w, true)
	draw_polyline(PackedVector2Array([Vector2(234, 92), Vector2(254, 98), Vector2(268, 96)]), col, w, true)
	draw_arc(Vector2(200, 126), 24.0, 0.15, PI - 0.25, 16, col, w, true)
	draw_arc(Vector2(240, 126), 24.0, 0.25, PI - 0.15, 16, col, w, true)
	draw_line(Vector2(220, 100), Vector2(220, 214), col, w, true)
	for y in [166, 186, 204]:
		draw_line(Vector2(204, y), Vector2(236, y), col, w, true)
	draw_arc(Vector2(170, 108), 15.0, 1.2, 4.4, 12, col, w, true)
	draw_arc(Vector2(270, 108), 15.0, -1.3, 1.9, 12, col, w, true)
	draw_arc(Vector2(190, 304), 11.0, 0.3, 2.8, 10, col, w, true)
	draw_arc(Vector2(250, 304), 11.0, 0.3, 2.8, 10, col, w, true)
	draw_line(Vector2(192, 244), Vector2(190, 290), col, w, true)
	draw_line(Vector2(248, 244), Vector2(250, 290), col, w, true)

func _colunas(a: float, estriar: bool) -> void:
	for cx in [38.0, 402.0]:
		draw_rect(Rect2(cx - 16, 14, 32, 380), Color(0.17, 0.13, 0.10, a))
		draw_rect(Rect2(cx - 20, 8, 40, 10), Color(0.24, 0.19, 0.14, a))
		draw_rect(Rect2(cx - 20, 388, 40, 10), Color(0.24, 0.19, 0.14, a))
		if estriar:
			for k in range(-2, 3):
				draw_line(Vector2(cx + k * 6.0, 20), Vector2(cx + k * 6.0, 386), Color(0.08, 0.06, 0.05, a), 1.0)

func _arco(cor: Color) -> void:
	draw_arc(Vector2(220, 214), 176.0, PI, TAU, 64, cor, 12.0, true)
	draw_arc(Vector2(220, 214), 160.0, PI, TAU, 64, Color(cor, cor.a * 0.5), 2.0, true)

func _tijolos(a: float) -> void:
	for y in range(30, 386, 22):
		draw_line(Vector2(60, y), Vector2(380, y), Color(0.0, 0.0, 0.0, a), 1.0)
		var off := 0.0 if (y / 22) % 2 == 0 else 20.0
		for x in range(60 + int(off), 380, 40):
			draw_line(Vector2(x, y), Vector2(x, y + 22), Color(0.0, 0.0, 0.0, a), 1.0)

func _piso(a: float) -> void:
	for ix in range(0, 11):
		for iy in range(0, 2):
			var cor := Color(0.30, 0.22, 0.14, a) if (ix + iy) % 2 == 0 else Color(0.20, 0.14, 0.09, a)
			draw_rect(Rect2(8 + ix * 42.0, 384 + iy * 8.0, 42, 8), cor)

func _tocha(p: Vector2, forca: float) -> void:
	for i in range(8):
		var k := float(i) / 7.0
		draw_circle(p, 80.0 * (1.0 - k), Color(1.0, 0.55, 0.15, 0.012 + 0.02 * k * forca))
	draw_rect(Rect2(p + Vector2(-3, 6), Vector2(6, 26)), Color(0.25, 0.16, 0.08))
	draw_circle(p + Vector2(0, 2), 6.0, Color(1.0, 0.7, 0.2))
	draw_circle(p + Vector2(0, -2), 3.5, Color(1.0, 0.95, 0.6))

func _subligaculo(cor: Color) -> void:
	draw_colored_polygon(PackedVector2Array([Vector2(192, 214), Vector2(248, 214), Vector2(256, 262), Vector2(236, 270), Vector2(220, 246), Vector2(204, 270), Vector2(184, 262)]), cor)
	draw_rect(Rect2(191, 210, 58, 9), Color(0.55, 0.40, 0.14))

func _faixas(cor: Color) -> void:
	for l in [[Vector2(122, 168), Vector2(146, 180)], [Vector2(112, 190), Vector2(134, 202)], [Vector2(318, 180), Vector2(294, 168)], [Vector2(328, 202), Vector2(306, 190)]]:
		draw_line(l[0], l[1], cor, 5.0, true)

func _cone(a: Vector2, b: Vector2, wa: float, wb: float, col: Color) -> void:
	var n := (b - a).orthogonal().normalized()
	draw_colored_polygon(PackedVector2Array([a + n * wa / 2.0, b + n * wb / 2.0, b - n * wb / 2.0, a - n * wa / 2.0]), col)
	draw_circle(a, wa / 2.0, col)
	draw_circle(b, wb / 2.0, col)

func _torso_pts() -> PackedVector2Array:
	var meio: Array = [[88, 50], [100, 54], [128, 45], [160, 36], [190, 26], [214, 29], [230, 32]]
	var pts := PackedVector2Array()
	for m in meio:
		pts.append(Vector2(220 - m[1], m[0]))
	for k in range(meio.size() - 1, -1, -1):
		pts.append(Vector2(220 + meio[k][1], meio[k][0]))
	return pts

## Silhueta humana com membros afilados; `ex` engorda tudo (usado para contorno/brilho).
func _silhueta(col: Color, ex: float) -> void:
	var t := _torso_pts()
	draw_colored_polygon(t, col)
	if ex > 0.0:
		var f: PackedVector2Array = t.duplicate()
		f.append(t[0])
		draw_polyline(f, col, ex * 2.0, true)
	draw_circle(Vector2(220, 38), 21.0 + ex, col)
	draw_colored_polygon(PackedVector2Array([Vector2(207, 44), Vector2(233, 44), Vector2(236 + ex, 78), Vector2(204 - ex, 78)]), col)
	for lado: float in [-1.0, 1.0]:
		var x: float = 220.0 + lado * 50.0
		draw_circle(Vector2(x, 100), 17.0 + ex, col)
		_cone(Vector2(x, 100), Vector2(220.0 + lado * 84.0, 154), 25.0 + ex * 2, 18.0 + ex * 2, col)
		_cone(Vector2(220.0 + lado * 84.0, 154), Vector2(220.0 + lado * 104.0, 210), 18.0 + ex * 2, 12.0 + ex * 2, col)
		draw_circle(Vector2(220.0 + lado * 106.0, 216), 8.0 + ex, col)
		_cone(Vector2(220.0 + lado * 17.0, 226), Vector2(220.0 + lado * 30.0, 304), 38.0 + ex * 2, 26.0 + ex * 2, col)
		_cone(Vector2(220.0 + lado * 30.0, 304), Vector2(220.0 + lado * 36.0, 376), 26.0 + ex * 2, 15.0 + ex * 2, col)
		draw_colored_polygon(PackedVector2Array([Vector2(220.0 + lado * 36.0 - 12 - ex, 372), Vector2(220.0 + lado * 36.0 + 12 + ex, 372), Vector2(220.0 + lado * 36.0 + 12 + ex + maxf(lado, 0.0) * 20.0, 386 + ex), Vector2(220.0 + lado * 36.0 - 12 - ex + minf(lado, 0.0) * 20.0, 386 + ex)]), col)

func _luz_lateral(cor: Color, w: float) -> void:
	# faixa de luz na borda esquerda de tronco e pernas, sombra na direita
	draw_line(Vector2(178, 104), Vector2(190, 212), cor, w, true)
	draw_line(Vector2(200, 250), Vector2(194, 360), cor, w * 0.8, true)
	draw_line(Vector2(130, 112), Vector2(120, 196), cor, w * 0.7, true)

func _fundo_romano(escuro: bool) -> void:
	_colunas(0.95, true)
	_tijolos(0.22 if not escuro else 0.3)
	_arco(Color(0.26, 0.20, 0.15, 1.0) if not escuro else Color(0.18, 0.14, 0.11, 1.0))
	_piso(1.0)
	_tocha(Vector2(38, 130), 1.0 if not escuro else 1.8)
	_tocha(Vector2(402, 130), 1.0 if not escuro else 1.8)

func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size)
	draw_rect(r, Color("120d0a"))
	var c := Vector2(LARGURA / 2.0, ALTURA * 0.46)
	for i in range(14):
		var k := float(i) / 13.0
		draw_circle(c, 210.0 * (1.0 - k), Color(0.80, 0.55, 0.25, 0.012 + 0.012 * k))
	_fundo_romano(true)
	draw_circle(Vector2(220, 384), 70.0, Color(1.0, 0.55, 0.2, 0.06))
	_silhueta(Color(1.0, 0.62, 0.28, 0.55), 2.2)
	_silhueta(Color(0.065, 0.045, 0.04), 0.0)
	_anatomia(Color(1.0, 0.65, 0.3, 0.16), false)
	_subligaculo(Color(0.26, 0.05, 0.04))
	draw_rect(r, Color(Tema.OURO_ESCURO, 0.9), false, 2.0)
	draw_rect(Rect2(Vector2(5, 5), size - Vector2(10, 10)), Color(Tema.OURO_ESCURO, 0.3), false, 1.0)


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
