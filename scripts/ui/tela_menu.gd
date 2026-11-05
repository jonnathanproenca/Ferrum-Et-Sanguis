class_name TelaMenu
extends Control
## Menu principal: arena ao fundo (zoom lento e troca de arenas), vinheta, brasas, emblema, título e botões.
## Também serve de menu dentro da partida (o HUD salva e navega para "menu"): Continuar volta à partida em curso.

const ARENAS := ["coliseu", "capua", "pompeia", "poco"]
const TOQUES_CHEAT := 25
const SOMBRA := """
shader_type canvas_item;
uniform float forca = 0.85;
void fragment() {
	vec2 uv = UV - 0.5;
	uv.x *= 1.15;
	float d = length(uv);
	float v = smoothstep(0.25, 0.8, d);
	float topo = smoothstep(0.5, 0.0, UV.y) * 0.35;
	COLOR = vec4(0.04, 0.02, 0.015, clamp(v * forca + topo + 0.12, 0.0, 0.95));
}
"""

## Escudo do ludus desenhado em código (mesmo desenho do EMBLEMA do original).
class Emblema extends Control:
	func _init(lado: float = 120.0) -> void:
		custom_minimum_size = Vector2(lado, lado)
		mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	func _draw() -> void:
		var k: float = minf(size.x, size.y) / 120.0
		var c := size / 2.0
		var f := func(p: Vector2) -> Vector2: return c + (p - Vector2(60, 60)) * k
		draw_circle(c + Vector2(0, 4 * k), 56 * k, Color(0, 0, 0, 0.35))
		draw_circle(c, 56 * k, Tema.PAINEL)
		draw_arc(c, 56 * k, 0, TAU, 64, Tema.OURO, 3 * k, true)
		var n := 24
		for i in range(n):
			var a0: float = TAU * i / n
			draw_arc(c, 48 * k, a0, a0 + TAU / n * 0.5, 6, Tema.SANGUE_CLARO, 2.5 * k, true)
		var lamina := PackedVector2Array([f.call(Vector2(60, 22)), f.call(Vector2(74, 52)), f.call(Vector2(60, 98)), f.call(Vector2(46, 52))])
		draw_colored_polygon(lamina, Tema.SANGUE)
		var borda := lamina.duplicate()
		borda.append(lamina[0])
		draw_polyline(borda, Tema.OURO, 2 * k, true)
		draw_line(f.call(Vector2(34, 34)), f.call(Vector2(86, 86)), Tema.AREIA, 5 * k, true)
		draw_line(f.call(Vector2(86, 34)), f.call(Vector2(34, 86)), Tema.AREIA, 5 * k, true)
		draw_circle(c, 7 * k, Tema.OURO)

var _fundo_a: TextureRect
var _fundo_b: TextureRect
var _arena_i := 0
var _toques := 0
var _ultimo_toque := 0
var _aviso: Label
var _caixa_botoes: VBoxContainer

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	clip_contents = true
	Som.musica("menu")
	_montar_fundo()
	_montar_centro()
	_montar_rodape()

func _camada_fundo(arena: String) -> TextureRect:
	var t := TextureRect.new()
	t.texture = Tema.textura("assets/arenas/%s.png" % arena)
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	t.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	t.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	t.modulate = Color(0.8, 0.68, 0.62)
	t.resized.connect(func(): t.pivot_offset = t.size / 2.0)
	return t

func _montar_fundo() -> void:
	_fundo_a = _camada_fundo(ARENAS[0])
	_fundo_b = _camada_fundo(ARENAS[1])
	_fundo_b.modulate.a = 0.0
	add_child(_fundo_a)
	add_child(_fundo_b)
	_zoom(_fundo_a)
	# vinheta
	var v := ColorRect.new()
	v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sh := Shader.new()
	sh.code = SOMBRA
	var mat := ShaderMaterial.new()
	mat.shader = sh
	v.material = mat
	add_child(v)
	# brasas subindo
	var p := CPUParticles2D.new()
	p.amount = 46
	p.lifetime = 7.0
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.direction = Vector2(0.15, -1)
	p.spread = 18.0
	p.gravity = Vector2(6, -10)
	p.initial_velocity_min = 22.0
	p.initial_velocity_max = 62.0
	p.scale_amount_min = 1.4
	p.scale_amount_max = 3.2
	p.angle_max = 360.0
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.15, 0.7, 1.0])
	g.colors = PackedColorArray([Color(1, 0.7, 0.3, 0.0), Color(1, 0.72, 0.3, 0.9), Color(0.9, 0.35, 0.12, 0.5), Color(0.5, 0.1, 0.05, 0.0)])
	p.color_ramp = g
	add_child(p)
	resized.connect(func():
		p.position = Vector2(size.x / 2.0, size.y + 10.0)
		p.emission_rect_extents = Vector2(size.x / 2.0, 4.0))
	p.position = Vector2(size.x / 2.0, size.y + 10.0)
	p.emission_rect_extents = Vector2(maxf(size.x / 2.0, 640.0), 4.0)
	# troca de arena a cada 9 s
	var t := Timer.new()
	t.wait_time = 9.0
	t.autostart = true
	t.timeout.connect(_trocar_arena)
	add_child(t)

func _zoom(t: TextureRect) -> void:
	t.scale = Vector2.ONE
	create_tween().tween_property(t, "scale", Vector2(1.09, 1.09), 16.0).set_trans(Tween.TRANS_SINE)

func _trocar_arena() -> void:
	_arena_i = (_arena_i + 1) % ARENAS.size()
	var entra := _fundo_b
	entra.texture = Tema.textura("assets/arenas/%s.png" % ARENAS[_arena_i])
	entra.modulate.a = 0.0
	_zoom(entra)
	var tw := create_tween()
	tw.tween_property(entra, "modulate:a", 1.0, 1.6)
	tw.tween_callback(func():
		_fundo_a.texture = entra.texture
		_fundo_a.scale = entra.scale
		entra.modulate.a = 0.0
		_zoom(_fundo_a))

func _montar_centro() -> void:
	var centro := CenterContainer.new()
	centro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(centro)
	var v := Tema.vbox(6)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	centro.add_child(v)

	var em := Emblema.new(112.0)
	em.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	em.gui_input.connect(_toque_emblema)
	v.add_child(em)

	var tit := Tema.titulo("FERRUM ET SANGUIS", 66)
	tit.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tit.add_theme_color_override("font_outline_color", Color("2a0c08"))
	tit.add_theme_constant_override("outline_size", 10)
	tit.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	tit.add_theme_constant_override("shadow_offset_y", 4)
	v.add_child(tit)

	v.add_child(_ornamento())
	var sub := Tema.rotulo("Um ludus, uma casa, a areia do Coliseu.", 23, Tema.AREIA)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	sub.add_theme_constant_override("shadow_offset_y", 2)
	v.add_child(sub)
	v.add_child(Tema.espaco(18))

	_caixa_botoes = Tema.vbox(12)
	_caixa_botoes.custom_minimum_size = Vector2(340, 0)
	_caixa_botoes.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(_caixa_botoes)
	var tem_partida: bool = not Jogo.e.is_empty()
	var tem_save: bool = tem_partida or Jogo.tem_save()
	if tem_save:
		var c := _botao_grande("Continuar", "primario")
		c.pressed.connect(_continuar)
		_caixa_botoes.add_child(c)
	var n := _botao_grande("Novo ludus", "ouro" if tem_save else "primario")
	n.pressed.connect(func(): Jogo.navegar.emit("selecao"))
	_caixa_botoes.add_child(n)
	var o := _botao_grande("Opções", "normal")
	o.pressed.connect(_abrir_opcoes)
	_caixa_botoes.add_child(o)

	if tem_partida:
		var l := Tema.rotulo("Partida em curso: ludus de %s, turno %d" % [Game.lanista_da_casa(Jogo.e)["nome"], int(Jogo.e["turno"])], 17, Tema.OCRE)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(Tema.espaco(4))
		v.add_child(l)
	_aviso = Tema.rotulo("", 18, Tema.VERDE)
	_aviso.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(_aviso)

func _botao_grande(texto: String, tipo: String) -> Button:
	var b := Tema.botao(texto, tipo, 24)
	b.custom_minimum_size = Vector2(340, 54)
	b.add_theme_font_override("font", Tema.fonte_titulo)
	b.mouse_entered.connect(func(): Som.sfx("sfx/moeda", 0.25))
	return b

## Linha dourada com losango no centro.
func _ornamento() -> Control:
	var h := Tema.hbox(10)
	h.alignment = BoxContainer.ALIGNMENT_CENTER
	for i in range(3):
		if i == 1:
			var d := Tema.rotulo("◆", 16, Tema.OURO_ESCURO)
			d.autowrap_mode = TextServer.AUTOWRAP_OFF
			h.add_child(d)
		else:
			var r := ColorRect.new()
			r.color = Tema.OURO_ESCURO
			r.custom_minimum_size = Vector2(150, 2)
			r.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			h.add_child(r)
	return h

func _montar_rodape() -> void:
	var l := Tema.rotulo("v%s · Cinzel e EB Garamond (OFL)" % TelaConfig.VERSAO, 14, Color(0.66, 0.58, 0.5, 0.7))
	l.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	l.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	l.grow_vertical = Control.GROW_DIRECTION_BEGIN
	l.offset_right = -14
	l.offset_bottom = -8
	l.autowrap_mode = TextServer.AUTOWRAP_OFF
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(l)

func _continuar() -> void:
	if not Jogo.e.is_empty():
		Jogo.navegar.emit("jogo")   # partida em curso (menu aberto de dentro do jogo)
	elif Jogo.continuar():
		Jogo.navegar.emit("jogo")
	else:
		_aviso.add_theme_color_override("font_color", Tema.SANGUE_CLARO)
		_aviso.text = "Não foi possível carregar o save."

func _abrir_opcoes() -> void:
	Modal.abrir(self, "Opções", TelaConfig.conteudo_opcoes(), 560.0)

## Desbloqueio do cheat mode: TOQUES_CHEAT toques seguidos no emblema (cada toque até 2,5 s depois do anterior).
func _toque_emblema(ev: InputEvent) -> void:
	if not (ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT):
		return
	var agora := Time.get_ticks_msec()
	_toques = _toques + 1 if agora - _ultimo_toque < 2500 else 1
	_ultimo_toque = agora
	if _toques >= TOQUES_CHEAT:
		_toques = 0
		liberar_cheat(self)
		_aviso.text = "Cheat mode liberado. Veja em Opções."

## Libera o cheat mode (compartilhado com a seleção de lanista).
static func liberar_cheat(_no: Node) -> void:
	Jogo.prefs["cheatLiberado"] = true
	Jogo.salvar_prefs()
	Som.sfx("sfx/cheat")
