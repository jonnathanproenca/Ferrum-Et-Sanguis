class_name TelaSelecao
extends Control
## Escolha do lanista (palco com os 10 sprites, história, especialização e bônus), da dificuldade e início do novo ludus.

const TOQUES_CHEAT := 25
const REF := Vector2(1376, 768)
const SHADER_SPRITE := """
shader_type canvas_item;
uniform float cinza = 0.0;
uniform float brilho = 1.0;
void fragment() {
	vec4 c = texture(TEXTURE, UV);
	float l = dot(c.rgb, vec3(0.299, 0.587, 0.114));
	c.rgb = mix(c.rgb, vec3(l), cinza) * brilho;
	COLOR = c;
}
"""

var _lanistas: Array = []
var _sel := -1
var _dif := "medio"
var _palco: Control
var _itens: Array = []          ## {raiz, sprite, brilho, nome, tw, hover}
var _shader: Shader
var _info: PanelContainer
var _info_v: VBoxContainer
var _l_resumo: Label
var _botoes_dif := {}
var _b_assumir: Button
var _aviso: Label
var _toques := 0
var _glow_tex: GradientTexture2D

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	clip_contents = true
	Som.musica("menu")
	_lanistas = Game.lanistas()
	_shader = Shader.new()
	_shader.code = SHADER_SPRITE
	_glow_tex = GradientTexture2D.new()
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.55, 1.0])
	g.colors = PackedColorArray([Color(1.0, 0.82, 0.38, 1.0), Color(0.98, 0.65, 0.22, 0.5), Color(0.9, 0.5, 0.1, 0.0)])
	_glow_tex.gradient = g
	_glow_tex.fill = GradientTexture2D.FILL_RADIAL
	_glow_tex.fill_from = Vector2(0.5, 0.5)
	_glow_tex.fill_to = Vector2(1.0, 0.5)
	_glow_tex.width = 128
	_glow_tex.height = 128

	# fundo
	var f := TextureRect.new()
	f.texture = Tema.textura("assets/lanistas/fundo.jpg")
	f.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	f.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	f.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	f.mouse_filter = Control.MOUSE_FILTER_IGNORE
	f.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(f)
	# degradê escuro no alto (leitura do texto) e embaixo (barra)
	var gr := Gradient.new()
	gr.offsets = PackedFloat32Array([0.0, 0.3, 0.55, 1.0])
	gr.colors = PackedColorArray([Color(0.04, 0.02, 0.015, 0.9), Color(0.04, 0.02, 0.015, 0.5), Color(0, 0, 0, 0.0), Color(0.04, 0.02, 0.015, 0.7)])
	var gt := GradientTexture2D.new()
	gt.gradient = gr
	gt.fill_from = Vector2(0, 0)
	gt.fill_to = Vector2(0, 1)
	gt.width = 4
	gt.height = 256
	var ov := TextureRect.new()
	ov.texture = gt
	ov.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ov.stretch_mode = TextureRect.STRETCH_SCALE
	ov.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ov.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(ov)

	var raiz := Tema.vbox(0)
	raiz.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(raiz)
	_palco = Control.new()
	_palco.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_palco.resized.connect(_posicionar)
	raiz.add_child(_palco)
	for i in range(_lanistas.size()):
		_criar_item(i)
	_montar_info()
	_montar_barra(raiz)
	_aviso = Tema.rotulo("", 18, Tema.VERDE)
	_aviso.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_aviso.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_aviso.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_aviso.offset_bottom = -150
	_aviso.add_theme_color_override("font_shadow_color", Color.BLACK)
	_aviso.add_theme_constant_override("shadow_offset_y", 2)
	_aviso.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_aviso)
	_atualizar_info()
	_posicionar.call_deferred()

# ---------- Palco ----------

func _criar_item(i: int) -> void:
	var l: Dictionary = _lanistas[i]
	var raiz := Control.new()
	raiz.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	raiz.mouse_filter = Control.MOUSE_FILTER_STOP
	raiz.gui_input.connect(func(ev: InputEvent):
		if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
			_marcar(i))
	raiz.mouse_entered.connect(func(): _hover(i, true))
	raiz.mouse_exited.connect(func(): _hover(i, false))
	_palco.add_child(raiz)
	var brilho := TextureRect.new()
	brilho.texture = _glow_tex
	brilho.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	brilho.mouse_filter = Control.MOUSE_FILTER_IGNORE
	brilho.modulate.a = 0.0
	raiz.add_child(brilho)
	var sp := TextureRect.new()
	sp.texture = Tema.textura("assets/lanistas/%s.png" % l["id"])
	sp.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sp.stretch_mode = TextureRect.STRETCH_SCALE
	sp.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var m := ShaderMaterial.new()
	m.shader = _shader
	sp.material = m
	raiz.add_child(sp)
	var nome := Tema.rotulo(str(l["nome"]), 15, Tema.AREIA)
	nome.autowrap_mode = TextServer.AUTOWRAP_OFF
	nome.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nome.add_theme_color_override("font_shadow_color", Color.BLACK)
	nome.add_theme_constant_override("shadow_offset_y", 2)
	nome.add_theme_constant_override("shadow_offset_x", 1)
	nome.mouse_filter = Control.MOUSE_FILTER_IGNORE
	raiz.add_child(nome)
	_itens.append({"raiz": raiz, "sprite": sp, "brilho": brilho, "nome": nome, "tw": null, "hover": false})

func _posicionar() -> void:
	if _itens.is_empty():
		return
	var ph: float = _palco.size.y
	var pw: float = _palco.size.x
	var alt: float = clampf(ph * 0.5, 120.0, 400.0)
	var esc: float = alt / 290.0
	var pe_y: float = ph - 38.0
	var n := _itens.size()
	for i in range(n):
		var it: Dictionary = _itens[i]
		var tex: Texture2D = (it["sprite"] as TextureRect).texture
		var sz: Vector2 = tex.get_size() * esc if tex else Vector2(100, 200)
		var centro: float = pw * (0.08 + 0.84 / float(n - 1) * i)
		var raiz: Control = it["raiz"]
		raiz.size = Vector2(sz.x, sz.y + 24.0)
		raiz.position = Vector2(centro - sz.x / 2.0, pe_y - sz.y)
		raiz.pivot_offset = Vector2(sz.x / 2.0, sz.y)
		(it["sprite"] as Control).position = Vector2.ZERO
		(it["sprite"] as Control).size = sz
		var br: Control = it["brilho"]
		br.size = Vector2(sz.x * 2.2, sz.x * 0.75)
		br.position = Vector2(sz.x / 2.0 - br.size.x / 2.0, sz.y - br.size.y * 0.62)
		var nm: Control = it["nome"]
		nm.size = Vector2(sz.x + 60.0, 22.0)
		nm.position = Vector2(-30.0, sz.y + 2.0)
		it["base_y"] = raiz.position.y
	_aplicar_visual(false)

func _aplicar_visual(animar: bool) -> void:
	for i in range(_itens.size()):
		var it: Dictionary = _itens[i]
		if not it.has("base_y"):
			continue
		var ativo: bool = i == _sel
		var apagado: bool = _sel >= 0 and not ativo
		var hover: bool = it["hover"]
		var cinza := 0.0
		var brilho := 1.0
		if ativo:
			brilho = 1.04
		elif apagado:
			cinza = 0.35 if hover else 1.0
			brilho = 0.85 if hover else 0.6
		elif hover:
			brilho = 1.12
		var m: ShaderMaterial = (it["sprite"] as TextureRect).material
		m.set_shader_parameter("cinza", cinza)
		m.set_shader_parameter("brilho", brilho)
		var raiz: Control = it["raiz"]
		var alvo_pos := Vector2.ZERO
		var alvo_esc := Vector2.ONE
		if ativo:
			alvo_pos.y = -raiz.size.y * 0.05
			alvo_esc = Vector2(1.06, 1.06)
		elif hover:
			alvo_pos.y = -raiz.size.y * 0.03
		var base_y: float = it["base_y"]
		if it["tw"]:
			(it["tw"] as Tween).kill()
		(it["brilho"] as Control).modulate.a = 1.0 if ativo else 0.0
		(it["nome"] as Label).add_theme_color_override("font_color", Tema.OURO if ativo else (Tema.CINZA if apagado else Tema.AREIA))
		raiz.z_index = 20 if ativo else 10 - absi(i - _itens.size() / 2)
		if animar:
			var tw := create_tween().set_parallel(true)
			tw.tween_property(raiz, "position:y", base_y + alvo_pos.y, 0.14)
			tw.tween_property(raiz, "scale", alvo_esc, 0.14)
			it["tw"] = tw
		else:
			raiz.position.y = base_y + alvo_pos.y
			raiz.scale = alvo_esc

func _hover(i: int, entrou: bool) -> void:
	_itens[i]["hover"] = entrou
	_aplicar_visual(true)

func _marcar(i: int) -> void:
	# cheat: 25 toques seguidos no último lanista (como no original)
	_toques = _toques + 1 if i == _lanistas.size() - 1 else 0
	if _toques >= TOQUES_CHEAT:
		_toques = 0
		TelaMenu.liberar_cheat(self)
		_aviso.text = "Cheat mode liberado."
		_atualizar_barra()
	_sel = i
	_aplicar_visual(true)
	_atualizar_info()
	_b_assumir.disabled = false
	_b_assumir.text = "Assumir o ludus de %s" % _lanistas[i]["nome"]

# ---------- Informações ----------

func _montar_info() -> void:
	_info = PanelContainer.new()
	var sb := Tema.caixa(Color(0.07, 0.04, 0.03, 0.8), Tema.OURO_ESCURO, 10, 2, 10)
	sb.shadow_color = Color(0, 0, 0, 0.6)
	sb.shadow_size = 16
	sb.content_margin_left = 20
	sb.content_margin_right = 20
	_info.add_theme_stylebox_override("panel", sb)
	_info.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_info.anchor_left = 0.17
	_info.anchor_right = 0.83
	_info.offset_left = 0
	_info.offset_right = 0
	_info.offset_top = 12
	_info.grow_vertical = Control.GROW_DIRECTION_END
	_info.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_info)
	_info_v = Tema.vbox(3)
	_info.add_child(_info_v)

func _atualizar_info() -> void:
	Tema.limpar(_info_v)
	if _sel < 0:
		_info_v.add_child(_centro(Tema.titulo("Escolha seu lanista", 32)))
		var t := Tema.rotulo("Cada lanista tem uma história, uma especialidade e um bônus que moldam o seu ludus. Toque em um deles.", 19, Tema.AREIA)
		t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_info_v.add_child(t)
		return
	var l: Dictionary = _lanistas[_sel]
	var nome := Tema.rotulo(str(l["nome"]), 34, Color("f2e6c8"), true)
	nome.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nome.autowrap_mode = TextServer.AUTOWRAP_OFF
	_info_v.add_child(nome)
	var tit := Tema.rotulo(str(l.get("titulo", "")), 20, Tema.OURO)
	tit.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_info_v.add_child(tit)
	var h := Tema.rotulo(str(l.get("historia", "")), 18, Tema.AREIA)
	h.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_info_v.add_child(h)
	var esp := Tema.rotulo(str(l.get("especializacao", "")), 18, Tema.OURO_ESCURO)
	esp.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_info_v.add_child(esp)
	var b: Dictionary = l.get("bonus", {})
	var bl := Tema.rotulo("%s: %s" % [b.get("nome", ""), b.get("descricao", "")], 19, Color("ffe9a8"))
	bl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_info_v.add_child(bl)

func _centro(c: Control) -> Control:
	c.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	return c

# ---------- Barra inferior ----------

func _montar_barra(raiz: VBoxContainer) -> void:
	var barra := PanelContainer.new()
	var sb := Tema.caixa(Color(0.07, 0.04, 0.03, 0.94), Tema.SANGUE, 0, 0, 10)
	sb.border_width_top = 2
	sb.content_margin_left = 18
	sb.content_margin_right = 18
	barra.add_theme_stylebox_override("panel", sb)
	raiz.add_child(barra)
	var h := Tema.hbox(16)
	barra.add_child(h)
	var voltar := Tema.botao("Voltar", "normal", 20)
	voltar.custom_minimum_size = Vector2(110, 48)
	voltar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	voltar.pressed.connect(func(): Jogo.navegar.emit("menu"))
	h.add_child(voltar)

	var meio := Tema.vbox(6)
	meio.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(meio)
	var linha := Tema.hbox(8)
	meio.add_child(linha)
	var tl := Tema.rotulo("DIFICULDADE", 14, Tema.OURO_ESCURO, true)
	tl.autowrap_mode = TextServer.AUTOWRAP_OFF
	tl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	linha.add_child(tl)
	for d in Game.DIFICULDADES_ORDEM:
		var id: String = d
		var b := Tema.botao(str(Game.REGRAS[id]["nome"]), "normal", 18)
		b.custom_minimum_size = Vector2(96, 36)
		b.toggle_mode = true
		b.pressed.connect(func(): _dif = id; _atualizar_dif())
		linha.add_child(b)
		_botoes_dif[id] = b
	_l_resumo = Tema.rotulo("", 16, Tema.AREIA)
	meio.add_child(_l_resumo)

	_b_assumir = Tema.botao("Escolha um lanista", "primario", 21)
	_b_assumir.add_theme_font_override("font", Tema.fonte_titulo)
	_b_assumir.custom_minimum_size = Vector2(300, 54)
	_b_assumir.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_b_assumir.disabled = true
	_b_assumir.pressed.connect(_assumir)
	_cheat_btn = Tema.botao("Cheats", "ouro", 17)
	_cheat_btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_cheat_btn.pressed.connect(func(): Modal.abrir(self, "Cheat mode", TelaConfig.painel_cheats(true), 620.0))
	h.add_child(_cheat_btn)
	h.add_child(_b_assumir)
	_atualizar_dif()
	_atualizar_barra()

var _cheat_btn: Button

func _atualizar_barra() -> void:
	_cheat_btn.visible = TelaConfig.cheat_liberado()

func _atualizar_dif() -> void:
	for k in _botoes_dif:
		var b: Button = _botoes_dif[k]
		var on: bool = k == _dif
		b.set_pressed_no_signal(on)
		b.add_theme_stylebox_override("normal", Tema.caixa(Tema.SANGUE if on else Tema.PAINEL, Tema.OURO if on else Tema.BORDA, 6, 1, 4))
		b.add_theme_stylebox_override("pressed", Tema.caixa(Tema.SANGUE, Tema.OURO, 6, 1, 4))
		b.add_theme_color_override("font_color", Tema.OURO if on else Tema.AREIA)
		b.add_theme_color_override("font_pressed_color", Tema.OURO)
	var r: Dictionary = Game.REGRAS[_dif]
	_l_resumo.text = "%s: %s A dificuldade vale para a partida inteira e não muda depois." % [r["nome"], r["resumo"]]

func _assumir() -> void:
	if _sel < 0:
		return
	Jogo.equipe = []
	Jogo.novo(str(_lanistas[_sel]["id"]), _dif)
	Jogo.navegar.emit("jogo")
