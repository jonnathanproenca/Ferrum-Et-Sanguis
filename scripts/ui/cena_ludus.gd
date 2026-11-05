class_name CenaLudus
extends Control
## Cena do ludus no alto do morro (porte de cenaLudus/personagensLudus em ui.ts e de src/art/ludus.ts).
## Mantém a proporção 1024:572 da imagem base; tudo é posicionado em "pixels da imagem" e escalado por `_k`.

const W := 1024.0
const H := 572.0
const DURACAO_COMPRA := 3.2

const CAMADAS := {
	"armaria": Rect2(139, 299, 204, 154), "refeitorio": Rect2(639, 307, 64, 72),
	"alojamentos": Rect2(741, 291, 52, 72), "enfermaria": Rect2(431, 289, 76, 80),
}
const ORDEM_CAMADAS := ["armaria", "refeitorio", "alojamentos", "enfermaria"]
const COM_TABUAS := ["enfermaria", "refeitorio", "alojamentos"]
const PORTAO := Rect2(0, 335, 92, 182)
const TABUAS := [
	{"top": 4.0, "r": -4.0, "vx": -95.0, "rf": -210.0, "d": 0.0},
	{"top": 28.0, "r": 3.0, "vx": 110.0, "rf": 180.0, "d": 0.14},
	{"top": 52.0, "r": -2.0, "vx": -140.0, "rf": -150.0, "d": 0.28},
	{"top": 76.0, "r": 4.0, "vx": 125.0, "rf": 230.0, "d": 0.42},
]
## Sprites dos gladiadores do pátio: [arquivo, w, h] (pixels da imagem).
const SPRITES_GLAD := [
	["s10", 44, 83], ["s11", 46, 82], ["s12", 62, 67], ["s13", 45, 72], ["s14", 62, 68], ["s15", 41, 79],
	["s04", 32, 75], ["s05", 39, 71], ["s06", 63, 71], ["s07", 49, 68], ["s08", 42, 77], ["s09", 51, 68],
]
const DOUTOR := ["s02", 42, 68]
## Guardas da varanda: [arquivo, w, h, x, pé y].
const GUARDAS := [["s00", 40, 81, 352, 237], ["s01", 38, 77, 580, 237], ["s00", 40, 81, 704, 237]]
const LANISTA_POS := Vector2(510, 237)
const LANISTA_ALTURA := 80.0
const GUARDACORPO := [["guardacorpo-1", 197, 194, 216], ["guardacorpo-2", 428, 194, 193], ["guardacorpo-3", 637, 194, 231]]
const TREINO := [["s17", 63, 78, 772, 440], ["s16", 72, 105, 846, 478], ["s17", 63, 78, 952, 548]]
const PONTOS := [[330, 505], [455, 478], [585, 508], [650, 462], [262, 470], [395, 450], [520, 545], [200, 540]]

const SHADER_BRILHO := "shader_type canvas_item;\nuniform float brilho = 1.0;\nvoid fragment() { vec4 c = texture(TEXTURE, UV) * COLOR; COLOR = vec4(c.rgb * brilho, c.a); }"

# ---------- Controles auxiliares ----------

## Ponto clicável (portão, ícones): botão sem estilo que desenha a si mesmo.
class Ponto extends Button:
	var tipo := "portao"          ## "portao", "armaria" ou "enfermaria"
	var rotulo := ""
	var aviso := 0
	var escala_pop := 1.0         ## animação de surgimento
	func _init() -> void:
		flat = true
		focus_mode = Control.FOCUS_NONE
		mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		for s in ["normal", "hover", "pressed", "focus", "disabled", "hover_pressed"]:
			add_theme_stylebox_override(s, StyleBoxEmpty.new())
		mouse_entered.connect(queue_redraw)
		mouse_exited.connect(queue_redraw)
	func _draw() -> void:
		var r := Rect2(Vector2.ZERO, size)
		var hover := is_hovered()
		if tipo == "portao":
			if hover:
				draw_rect(r, Color(0.95, 0.82, 0.54, 0.10))
				var c := Color(0.95, 0.82, 0.54, 0.9)
				var pasto := 9.0
				for lado in [[r.position, Vector2(r.size.x, 0)], [Vector2(0, r.size.y), Vector2(r.size.x, 0)], [r.position, Vector2(0, r.size.y)], [Vector2(r.size.x, 0), Vector2(0, r.size.y)]]:
					var n: float = lado[1].length()
					var d: Vector2 = lado[1] / n
					var p := 0.0
					while p < n:
						draw_line(lado[0] + d * p, lado[0] + d * minf(p + pasto * 0.6, n), c, 2.0)
						p += pasto
			var f: Font = Tema.fonte_titulo
			var fs := maxi(10, int(size.x * 0.13))
			var txt := "PORTÃO"
			var tw := f.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
			var pos := Vector2((size.x - tw) / 2.0, size.y - 8.0)
			draw_string_outline(f, pos, txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 5, Color(0, 0, 0, 0.9))
			draw_string(f, pos, txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Tema.OURO if hover else Color(0.95, 0.82, 0.54, 0.8))
			return
		# ícone redondo
		var cen := size / 2.0
		var raio := minf(size.x, size.y) / 2.0 * escala_pop
		if raio <= 0.5:
			return
		draw_circle(cen + Vector2(0, 2), raio, Color(0, 0, 0, 0.45))
		draw_circle(cen, raio, Color("3a2a14") if hover else Color(0.078, 0.047, 0.035, 0.9))
		draw_arc(cen, raio - 1.0, 0.0, TAU, 40, Color("fff0a0") if hover else Tema.OURO, 2.0, true)
		var u := raio * 0.5
		var cor := Tema.OURO
		if tipo == "enfermaria":
			var a := u * 0.42
			draw_colored_polygon(PackedVector2Array([
				cen + Vector2(-a, -u), cen + Vector2(a, -u), cen + Vector2(a, -a), cen + Vector2(u, -a), cen + Vector2(u, a), cen + Vector2(a, a),
				cen + Vector2(a, u), cen + Vector2(-a, u), cen + Vector2(-a, a), cen + Vector2(-u, a), cen + Vector2(-u, -a), cen + Vector2(-a, -a)]), cor)
		else:
			draw_colored_polygon(PackedVector2Array([cen + Vector2(0, -u * 1.35), cen + Vector2(u * 0.28, u * 0.1), cen + Vector2(-u * 0.28, u * 0.1)]), cor)
			draw_rect(Rect2(cen + Vector2(-u * 0.75, u * 0.1), Vector2(u * 1.5, u * 0.2)), cor)
			draw_rect(Rect2(cen + Vector2(-u * 0.12, u * 0.3), Vector2(u * 0.24, u * 1.0)), cor)
		if aviso > 0 and escala_pop > 0.9:
			var pb := Vector2(size.x - 2.0, 2.0)
			var rb := maxf(8.0, size.x * 0.26)
			draw_circle(pb, rb, Tema.SANGUE_CLARO)
			draw_arc(pb, rb, 0.0, TAU, 24, Color.WHITE, 1.2, true)
			var t := str(aviso)
			var fs2 := int(rb * 1.25)
			var tw2 := Tema.fonte_corpo.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, fs2).x
			draw_string(Tema.fonte_corpo, pb + Vector2(-tw2 / 2.0, fs2 * 0.33), t, HORIZONTAL_ALIGNMENT_LEFT, -1, fs2, Color.WHITE)

## Tábua de madeira pregada (desenhada em código com as listras do CSS original).
class Tabua extends Control:
	var unidade := 1.0
	func _draw() -> void:
		var r := Rect2(Vector2.ZERO, size)
		draw_rect(Rect2(Vector2(0, 3), size), Color(0, 0, 0, 0.5))
		draw_rect(r, Color("7b5232"))
		var per := 18.0 * unidade
		var x := 0.0
		while x < size.x:
			var segs := [[0.0, 7.0, "7b5232"], [7.0, 8.0, "6a4426"], [8.0, 17.0, "8a5d3b"], [17.0, 18.0, "5f3d22"]]
			for s in segs:
				var x0 := x + float(s[0]) * unidade
				var w := minf(float(s[1]) * unidade, size.x) - float(s[0]) * unidade
				if x0 < size.x:
					draw_rect(Rect2(x0, 0, minf(w, size.x - x0), size.y), Color(str(s[2])))
			x += per
		draw_rect(Rect2(0, 0, size.x, maxf(1.0, unidade)), Color(1, 1, 1, 0.14))
		draw_rect(r, Color("26140a"), false, maxf(1.5, 2.0 * unidade))
		for nx in [size.x * 0.06 + 3.0 * unidade, size.x * 0.94 - 3.0 * unidade]:
			draw_circle(Vector2(nx, size.y * 0.4), 2.2 * unidade + 0.6, Color("333333"))
			draw_circle(Vector2(nx, size.y * 0.4 - 0.5), 2.0 * unidade + 0.4, Color("c8c8c8"))

## Chicote do doutor: arco que se estende e termina num estalo.
class Chicote extends Control:
	var prog := 0.0    ## 0..1 (0 = invisível)
	func _draw() -> void:
		if prog <= 0.0:
			return
		var a := clampf(prog / 0.25, 0.0, 1.0) if prog < 0.7 else clampf((1.0 - prog) / 0.3, 0.0, 1.0)
		var alc := clampf(prog / 0.35, 0.0, 1.0)
		var s := size.x
		var mao := Vector2(0.0, size.y * 0.5)
		var ponta := Vector2(s * 0.95, size.y * 0.05)
		var c1 := Vector2(s * 0.25, -size.y * 0.5)
		var c2 := Vector2(s * 0.62, -size.y * 0.35)
		var pts := PackedVector2Array()
		var n := 16
		for i in range(n + 1):
			var t := float(i) / n * alc
			var q := 1.0 - t
			pts.append(q * q * q * mao + 3.0 * q * q * t * c1 + 3.0 * q * t * t * c2 + t * t * t * ponta)
		var cor := Color(0.91, 0.84, 0.69, a)
		draw_polyline(pts, Color(0, 0, 0, a * 0.35), maxf(3.0, s * 0.04), true)
		draw_polyline(pts, cor, maxf(1.6, s * 0.022), true)
		if alc >= 1.0:
			var p := pts[pts.size() - 1]
			var l := s * 0.1
			var cc := Color(1, 0.96, 0.78, a)
			for d in [Vector2(1, -0.6), Vector2(1.1, 0.2), Vector2(0.5, 1.0), Vector2(-0.2, -1.0)]:
				draw_line(p, p + d.normalized() * l, cc, maxf(1.5, s * 0.016), true)

# ---------- Estado ----------

var _k := 1.0
var _org := Vector2.ZERO
var _t := 0.0
var _compra_id := ""
var _compra_t0 := 0
var _assinatura := ""
var _shader: Shader

var _fundo: Control
var _itens: Array = []            ## {no, rect (px imagem), tipo, ...}
var _tabuas: Array = []           ## {no, rect, r, vx, rf, d, sec}
var _gladiadores: Array = []
var _doutor: Control
var _chicote: Chicote
var _doutor_corpo: TextureRect
var _chicote_prox := 2.5
var _chicote_ini := -10.0
var _menu: PanelContainer
var _rotulo: Label
var _pontos: Dictionary = {}      ## "portao", "armaria", "enfermaria" -> Ponto
var grande := false               ## true: sem os gladiadores/doutor pequenos (a subclasse põe os sprites grandes)

func _ready() -> void:
	theme = Tema.tema()
	clip_contents = true
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mouse_filter = Control.MOUSE_FILTER_PASS
	_shader = Shader.new()
	_shader.code = SHADER_BRILHO
	resized.connect(_ao_redimensionar)
	Jogo.mudou.connect(_ao_mudar)
	Jogo.construiu.connect(_ao_construir)
	gui_input.connect(_ao_input)
	visibility_changed.connect(func(): if is_visible_in_tree(): _montar())
	_ao_redimensionar()
	if not Jogo.e.is_empty():
		_montar()

func _ao_input(ev: InputEvent) -> void:
	if ev is InputEventMouseButton and ev.pressed and _menu and _menu.visible:
		_menu.visible = false

func _ao_redimensionar() -> void:
	if size.x <= 1.0:
		return
	custom_minimum_size.y = size.x * H / W
	_k = minf(size.x / W, size.y / H) if size.y > 1.0 else size.x / W
	_org = Vector2((size.x - W * _k) / 2.0, (size.y - H * _k) / 2.0 if size.y > 1.0 else 0.0)
	_reposicionar()

func _ao_mudar() -> void:
	if is_visible_in_tree() and not Jogo.e.is_empty():
		_montar()

func _ao_construir(id: String) -> void:
	_compra_id = id
	_compra_t0 = Time.get_ticks_msec()
	_assinatura = ""
	if not Jogo.e.is_empty():
		_montar()

func _compra_ativa() -> bool:
	return _compra_id != "" and float(Time.get_ticks_msec() - _compra_t0) / 1000.0 < DURACAO_COMPRA

func _decorrido() -> float:
	return float(Time.get_ticks_msec() - _compra_t0) / 1000.0 if _compra_id != "" else 0.0

# ---------- Construção dos nós ----------

func _tem(id: String) -> bool:
	return Game.tem_melhoria(Jogo.e, id)

func _ass() -> String:
	var vivos: Array = Jogo.e["gladiadores"].filter(func(g): return g["vivo"])
	var s := str(Jogo.e["casaId"]) + "|" + _compra_id + "|"
	for m in Game.MELHORIAS_LUDUS:
		s += "1" if _tem(m["id"]) else "0"
	for g in vivos:
		s += "|" + str(g["id"])
	return s

func _feridos() -> int:
	return Jogo.e["gladiadores"].filter(func(g): return g["vivo"] and not g["efeitos"].is_empty()).size()

func _montar() -> void:
	if Jogo.e.is_empty():
		return
	if _compra_id != "" and not _compra_ativa():
		_compra_id = ""
	var ass := _ass()
	if ass == _assinatura:
		_atualizar_avisos()
		return
	_assinatura = ass
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_itens.clear()
	_tabuas.clear()
	_gladiadores.clear()
	_pontos.clear()
	var ativa := _compra_ativa()
	var anim := _compra_id if ativa else ""

	var bg := ColorRect.new()
	bg.color = Color("2a1a18")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	_img("assets/ludus/base.png", Rect2(0, 0, W, H), 0)

	# camadas das melhorias construídas
	for id in ORDEM_CAMADAS:
		if _tem(id):
			var n := _img("assets/ludus/%s.png" % id, CAMADAS[id], 1)
			if anim == id:
				_itens[_itens.size() - 1]["fade"] = {"d": 1.0 if id in COM_TABUAS else 0.6}
				_aplicar_fade(_itens[_itens.size() - 1])
	# personagens
	var hash_f := func(t: String) -> int:
		var h := 7
		for i in range(t.length()):
			h = (h * 31 + t.unicode_at(i)) & 0xFFFFFFFF
		return h
	for g in GUARDAS:
		_sprite(g[0], g[1], g[2], g[3], g[4], false)
	var casa: Dictionary = Game.lanista_da_casa(Jogo.e)
	var tex_l: Texture2D = Tema.textura("assets/lanistas/%s.png" % str(casa.get("id", "")))
	if tex_l:
		var th := LANISTA_ALTURA
		var tw := roundf(tex_l.get_width() * th / tex_l.get_height())
		var n2 := _sprite_tex(tex_l, tw, th, LANISTA_POS.x, LANISTA_POS.y, false)
		n2.name = "Lanista"
	for t in GUARDACORPO:
		var tx: Texture2D = Tema.textura("assets/ludus/%s.png" % t[0])
		_img("assets/ludus/%s.png" % t[0], Rect2(t[1], t[2], t[3], t[3] * float(tx.get_height()) / tx.get_width()), 240)
	if _tem("palus"):
		for t in TREINO:
			var it := _sprite(t[0], t[1], t[2], t[3], t[4], false)
			if anim == "palus":
				it["fade"] = {"d": 0.3}
				_aplicar_fade(it)
	var i := 0
	for g in ([] if grande else Jogo.e["gladiadores"]):
		if not g["vivo"]:
			continue
		var h: int = hash_f.call(str(g["id"]))
		var sp: Array = SPRITES_GLAD[h % SPRITES_GLAD.size()]
		var p: Array = PONTOS[i % PONTOS.size()]
		var it2 := _sprite(sp[0], sp[1], sp[2], p[0], p[1], h % 2 == 1)
		it2["treina"] = {"dur": 2.6 + float(h % 17) / 10.0, "atraso": -float(h % 40) / 10.0}
		i += 1
	if not grande:
		_montar_doutor()
	# tábuas
	for id in COM_TABUAS:
		if not _tem(id) or anim == id:
			_montar_tabuas(id, anim == id)
	# poeira da armaria
	if anim == "armaria":
		_montar_poeira()
	# pontos clicáveis
	var portao := Ponto.new()
	portao.tipo = "portao"
	portao.tooltip_text = "Portão do ludus: escolher mercado ou arena"
	portao.pressed.connect(_alternar_menu)
	portao.z_index = 2
	add_child(portao)
	_itens.append({"no": portao, "rect": PORTAO, "tipo": "ponto"})
	_pontos["portao"] = portao
	for id in ["armaria", "enfermaria"]:
		if _tem(id):
			var ic := Ponto.new()
			ic.tipo = id
			ic.z_index = 1000
			var aba := "armeiro" if id == "armaria" else "enfermaria"
			ic.pressed.connect(func(): Jogo.abrir_aba.emit(aba))
			add_child(ic)
			var r: Rect2 = CAMADAS[id]
			_itens.append({"no": ic, "rect": Rect2(r.get_center(), Vector2.ZERO), "tipo": "icone", "pop": anim == id})
			_pontos[id] = ic
	# menu do portão
	_menu = PanelContainer.new()
	_menu.add_theme_stylebox_override("panel", Tema.caixa(Color(0.078, 0.047, 0.035, 0.95), Tema.OCRE, 8, 1, 10))
	_menu.z_index = 2000
	_menu.visible = false
	var vb := Tema.vbox(6)
	_menu.add_child(vb)
	vb.add_child(Tema.rotulo("Para onde ir?", 17, Tema.AREIA))
	var b1 := Tema.botao("Mercado de gladiadores", "primario", 17)
	b1.pressed.connect(func(): _menu.visible = false; Jogo.abrir_aba.emit("mercado"))
	var b2 := Tema.botao("Arenas", "normal", 17)
	b2.pressed.connect(func(): _menu.visible = false; Jogo.abrir_aba.emit("arenas"))
	vb.add_child(b1)
	vb.add_child(b2)
	add_child(_menu)
	# rótulo
	_rotulo = Label.new()
	_rotulo.text = "Ludus de %s" % str(casa.get("nome", ""))
	_rotulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_rotulo.add_theme_font_override("font", Tema.fonte_titulo)
	_rotulo.add_theme_color_override("font_color", Tema.OURO)
	_rotulo.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.95))
	_rotulo.add_theme_constant_override("outline_size", 6)
	_rotulo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rotulo.z_index = 1500
	add_child(_rotulo)
	_atualizar_avisos()
	_reposicionar()

func _alternar_menu() -> void:
	if _menu:
		_menu.visible = not _menu.visible
		_reposicionar()

func _atualizar_avisos() -> void:
	var f := _feridos()
	if _pontos.has("enfermaria"):
		var p: Ponto = _pontos["enfermaria"]
		p.aviso = f
		p.tooltip_text = "Enfermaria" + (" (%d ferido%s)" % [f, "" if f == 1 else "s"] if f > 0 else "")
		p.queue_redraw()
	if _pontos.has("armaria"):
		_pontos["armaria"].tooltip_text = "Armeiro"

func _novo_item(no: Control, rect: Rect2, z: int, tipo: String = "img") -> Dictionary:
	no.z_index = z
	no.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(no)
	var it := {"no": no, "rect": rect, "tipo": tipo}
	_itens.append(it)
	return it

func _img(arq: String, rect: Rect2, z: int) -> Control:
	var tr := TextureRect.new()
	tr.texture = Tema.textura(arq)
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_SCALE
	_novo_item(tr, rect, z)
	return tr

func _sprite_tex(tex: Texture2D, w: float, h: float, cx: float, pe: float, espelho: bool) -> Control:
	var tr := TextureRect.new()
	tr.texture = tex
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_SCALE
	tr.flip_h = espelho
	_novo_item(tr, Rect2(cx - w / 2.0, pe - h, w, h), int(pe))
	return tr

func _sprite(arq: String, w: float, h: float, cx: float, pe: float, espelho: bool) -> Dictionary:
	_sprite_tex(Tema.textura("assets/ludus/%s.png" % arq), w, h, cx, pe, espelho)
	return _itens[_itens.size() - 1]

func _aplicar_fade(it: Dictionary) -> void:
	var m := ShaderMaterial.new()
	m.shader = _shader
	it["no"].material = m

func _montar_doutor() -> void:
	var d := Control.new()
	d.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tr := TextureRect.new()
	tr.texture = Tema.textura("assets/ludus/%s.png" % DOUTOR[0])
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_SCALE
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	d.add_child(tr)
	_doutor_corpo = tr
	_chicote = Chicote.new()
	_chicote.mouse_filter = Control.MOUSE_FILTER_IGNORE
	d.add_child(_chicote)
	_doutor = d
	_novo_item(d, Rect2(0, 452 - float(DOUTOR[2]), float(DOUTOR[1]), float(DOUTOR[2])), 452, "doutor")

func _montar_tabuas(id: String, anim: bool) -> void:
	var base: Rect2 = CAMADAS[id]
	var rect := Rect2(base.position - Vector2(5, 5), base.size + Vector2(10, 10))
	for b in TABUAS:
		var t := Tabua.new()
		t.mouse_filter = Control.MOUSE_FILTER_IGNORE
		t.z_index = 3 + int(rect.position.y + rect.size.y * float(b["top"]) / 100.0) % 1  # abaixo dos sprites, acima das camadas
		add_child(t)
		_tabuas.append({"no": t, "rect": rect, "b": b, "anim": anim})
	var dica := Control.new()
	dica.tooltip_text = "%s: construa no menu Upgrades" % str(Game.melhoria_por_id(id)["nome"])
	dica.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(dica)
	_itens.append({"no": dica, "rect": rect, "tipo": "img"})

func _montar_poeira() -> void:
	var base: Rect2 = CAMADAS["armaria"]
	var rect := Rect2(base.position - Vector2(10, 10), base.size + Vector2(20, 20))
	var g := Gradient.new()
	g.colors = PackedColorArray([Color(0.86, 0.78, 0.65, 0.9), Color(0.86, 0.78, 0.65, 0.0)])
	g.offsets = PackedFloat32Array([0.0, 0.7])
	var gt := GradientTexture2D.new()
	gt.gradient = g
	gt.fill = GradientTexture2D.FILL_RADIAL
	gt.fill_from = Vector2(0.5, 0.5)
	gt.fill_to = Vector2(1.0, 0.5)
	gt.width = 128
	gt.height = 128
	for b in [[0.05, 0.30, 0.45, 0.60, 0.0], [0.35, 0.15, 0.50, 0.70, 0.12], [0.55, 0.35, 0.45, 0.55, 0.25]]:
		var tr := TextureRect.new()
		tr.texture = gt
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_SCALE
		tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tr.z_index = 600
		tr.modulate.a = 0.0
		add_child(tr)
		var r := Rect2(rect.position + Vector2(rect.size.x * b[0], rect.size.y * b[1]), Vector2(rect.size.x * b[2], rect.size.y * b[3]))
		_itens.append({"no": tr, "rect": r, "tipo": "poeira", "p": b[4]})

# ---------- Posicionamento ----------

func _px(r: Rect2) -> Rect2:
	return Rect2(_org + r.position * _k, r.size * _k)

func _reposicionar() -> void:
	if _itens.is_empty():
		return
	for it in _itens:
		var no: Control = it["no"]
		var r: Rect2 = it["rect"]
		match it["tipo"]:
			"icone":
				var s := maxf(30.0, 40.0 * _k)
				no.size = Vector2(s, s)
				no.pivot_offset = no.size / 2.0
				no.position = _org + r.position * _k - no.size / 2.0
			"ponto":
				var pr := _px(r)
				no.position = pr.position
				no.size = pr.size
			_:
				var pr2 := _px(r)
				no.position = pr2.position
				no.size = pr2.size
				no.pivot_offset = pr2.size / 2.0
	for tb in _tabuas:
		var rc: Rect2 = tb["rect"]
		var b: Dictionary = tb["b"]
		var pr3 := _px(rc)
		var no2: Tabua = tb["no"]
		no2.size = Vector2(pr3.size.x * 1.16, pr3.size.y * 0.24)
		no2.pivot_offset = no2.size / 2.0
		no2.unidade = maxf(0.5, _k)
		tb["base"] = pr3.position + Vector2(-pr3.size.x * 0.08, pr3.size.y * float(b["top"]) / 100.0)
		no2.queue_redraw()
	if _doutor:
		_doutor.pivot_offset = _doutor.size / 2.0
		_doutor_corpo.size = _doutor.size
		_chicote.size = Vector2(_doutor.size.x * 2.3, _doutor.size.x * 1.1)
		_chicote.position = Vector2(_doutor.size.x * 0.85, _doutor.size.y * 0.30)
	if _rotulo:
		var fs := maxi(12, int(15.0 * maxf(_k, 0.8)))
		_rotulo.add_theme_font_size_override("font_size", fs)
		_rotulo.position = _org + Vector2(0, H * 0.018 * _k)
		_rotulo.size = Vector2(W * _k, fs * 1.6)
	if _menu:
		_menu.reset_size()
		_menu.position = _org + Vector2(W * 0.02, H * 0.04) * _k + Vector2(0, 0)
		_menu.custom_minimum_size.x = 220.0
	_animar(0.0)

# ---------- Animação ----------

func _process(delta: float) -> void:
	if _itens.is_empty() or not is_visible_in_tree():
		return
	_t += delta
	if _compra_id != "" and not _compra_ativa():
		_compra_id = ""
		_assinatura = ""
		_montar()
	_animar(delta)

static func _suave(p: float) -> float:
	return p * p * (3.0 - 2.0 * p)

func _tri(x: float) -> float:
	var f := fposmod(x, 2.0)
	return f if f <= 1.0 else 2.0 - f

func _animar(_delta: float) -> void:
	var ativa := _compra_ativa()
	var dec := _decorrido() if ativa else 99.0
	for it in _itens:
		var no: Control = it["no"]
		match it["tipo"]:
			"img":
				if it.has("fade"):
					var q := clampf((dec - float(it["fade"]["d"])) / 1.3, 0.0, 1.0)
					no.modulate.a = q
					(no.material as ShaderMaterial).set_shader_parameter("brilho", lerpf(1.5, 1.0, q))
				if it.has("treina"):
					var tr: Dictionary = it["treina"]
					var n := (_t - float(tr["atraso"])) / float(tr["dur"])
					var f := fposmod(n, 1.0)
					var p := (1.0 - f) if int(floor(n)) % 2 == 1 else f
					var off := Vector2.ZERO
					if p < 0.5:
						off = Vector2(lerpf(-6.0, 0.0, _suave(p * 2.0)), lerpf(0.0, -2.5, _suave(p * 2.0)))
					else:
						off = Vector2(lerpf(0.0, 6.0, _suave((p - 0.5) * 2.0)), lerpf(-2.5, 0.0, _suave((p - 0.5) * 2.0)))
					var pr := _px(it["rect"])
					no.position = pr.position + off * _k
			"doutor":
				var x := lerpf(0.24, 0.58, _suave(_tri(_t / 16.0))) * W
				var pr2 := _px(it["rect"])
				var passo := _suave(_tri(_t / 0.5)) * -2.0
				no.position = Vector2(_org.x + x * _k, pr2.position.y + passo * _k)
				no.scale.x = -1.0 if fposmod(_t, 32.0) >= 16.0 else 1.0
			"icone":
				if it["pop"]:
					var q2 := clampf((dec - 1.9) / 0.6, 0.0, 1.0)
					# overshoot tipo cubic-bezier(.2,1.6,.4,1)
					var s := 1.0 + 1.70158 * pow(q2 - 1.0, 3.0) + 1.70158 * 1.2 * pow(q2 - 1.0, 2.0) if q2 < 1.0 else 1.0
					(no as Ponto).escala_pop = maxf(0.0, s) * (1.0 if q2 > 0.0 else 0.0)
					no.queue_redraw()
				else:
					(no as Ponto).escala_pop = 1.0
			"poeira":
				var q3 := (dec - float(it["p"])) / 1.8
				if q3 <= 0.0 or q3 >= 1.0:
					no.modulate.a = 0.0
				else:
					no.modulate.a = (q3 / 0.18 * 0.95) if q3 < 0.18 else 0.95 * (1.0 - (q3 - 0.18) / 0.82)
					var e := q3 * q3 * (3.0 - 2.0 * q3)
					var pr3 := _px(it["rect"])
					var s2 := lerpf(0.5, 1.7, e)
					no.scale = Vector2(s2, s2)
					no.position = pr3.position + Vector2(0.0, -pr3.size.y * 0.18 * e)
	# tábuas
	for tb in _tabuas:
		var b: Dictionary = tb["b"]
		var no3: Tabua = tb["no"]
		no3.rotation = deg_to_rad(float(b["r"]))
		no3.modulate.a = 1.0
		no3.position = tb["base"] if tb.has("base") else no3.position
		if tb["anim"]:
			var p2 := clampf((dec - float(b["d"])) / 1.5, 0.0, 1.0)
			if p2 > 0.3:
				var q4 := (p2 - 0.3) / 0.7
				var e2 := q4 * q4
				no3.position += Vector2(no3.size.x * float(b["vx"]) / 100.0 * e2, no3.size.y * 3.2 * e2)
				no3.rotation = deg_to_rad(lerpf(float(b["r"]), float(b["rf"]), e2))
				no3.modulate.a = 1.0 - e2
	# chicote
	if _chicote:
		if _chicote_ini < 0.0 and _t >= _chicote_prox:
			_chicote_ini = _t
			_chicote_prox = _t + 1.8 + randf() * 4.2
		if _chicote_ini >= 0.0:
			var q5 := (_t - _chicote_ini) / 0.5
			if q5 >= 1.0:
				_chicote_ini = -10.0
				_chicote.prog = 0.0
			else:
				_chicote.prog = q5
			_chicote.queue_redraw()
