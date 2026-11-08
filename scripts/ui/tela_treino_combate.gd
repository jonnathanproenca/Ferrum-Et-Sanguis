class_name TelaTreinoCombate
extends Control
## Mini-arena de treino: o jogador controla o gladiador contra um boneco, só com os comandos (sem vida).
## Teclado/mouse: A/D ou setas andam, Espaço esquiva, botão direito defende (parry no tempo certo),
## clique = ataque leve, segurar = pesado. Toque: botões na tela (multitoque). A lógica fica em TreinoCombate.

const PALCO := Vector2(1280, 720)
const CHAO_Y := 610.0
const ESCALA_LUTADOR := 1.6
const FUNDO := "assets/arenas/pompeia.png"
const COR_FB := {"branco": Color("f2e6cc"), "ouro": Color("ffd25a"), "verde": Color("9be05a"), "vermelho": Color("e06a5a"), "cinza": Color("9a9a9a")}

var _nucleo: TreinoCombate
var _classe := "murmilo"
var _id := "treino"
var _palco: Control
var _jogador: LutadorLuta
var _boneco: LutadorLuta
var _fb: Label
var _placar: Label
var _barra: ColorRect
var _tw_fb: Tween
var _tecla_esq := false
var _tecla_dir := false
var _toque_esq := false
var _toque_dir := false
var _botoes: Array = []        ## {"id", "no": Control, "tipo": "tap"|"hold"}
var _toques: Dictionary = {}   ## índice do dedo -> id do botão
var _fechado := false
var _c3d: Cena3DTreino
var _arte2d: Control
var _veu2d: Control
var _btn3d: Button


## Abre o treino sobre `pai`, com o estilo do gladiador `g` (vazio = murmilo).
static func abrir(pai: Node, g: Dictionary = {}) -> TelaTreinoCombate:
	var topo: Node = pai
	while topo.get_parent() is Control:
		topo = topo.get_parent()
	var t := TelaTreinoCombate.new()
	if not g.is_empty() and not g.get("semEstilo", false):
		t._classe = str(g["classe"])
		t._id = str(g["id"])
	topo.add_child(t)
	return t


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	z_as_relative = false
	z_index = 3600
	mouse_filter = Control.MOUSE_FILTER_STOP
	_nucleo = TreinoCombate.new(int(Time.get_ticks_msec()) % 100000 + 1)
	var fundo := ColorRect.new()
	fundo.color = Color.BLACK
	fundo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fundo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fundo)

	_palco = Control.new()
	_palco.size = PALCO
	_palco.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_palco.clip_contents = true
	add_child(_palco)
	var arte := TextureRect.new()
	arte.texture = Tema.textura(FUNDO)
	arte.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	arte.stretch_mode = TextureRect.STRETCH_SCALE
	arte.size = PALCO
	_arte2d = arte
	arte.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_palco.add_child(arte)
	var vel := ColorRect.new()
	vel.color = Color(0, 0, 0, 0.25)
	vel.size = PALCO
	_veu2d = vel
	vel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_palco.add_child(vel)

	_boneco = LutadorLuta.new("boneco", "murmilo", ESCALA_LUTADOR, true, 1.0, Vector2(TreinoCombate.X_BONECO, CHAO_Y))
	_boneco.parado = true
	_boneco.modulate = Color(0.85, 0.75, 0.6)
	_palco.add_child(_boneco)
	_jogador = LutadorLuta.new(_id, _classe, ESCALA_LUTADOR, false, 1.0, Vector2(_nucleo.x, CHAO_Y))
	_jogador.parado = true
	_palco.add_child(_jogador)

	_barra = ColorRect.new()
	_barra.color = Color("c9a24a")
	_barra.size = Vector2(0, 8)
	_barra.visible = false
	_palco.add_child(_barra)

	# captura do mouse (atrás dos botões)
	var captura := Control.new()
	captura.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	captura.mouse_filter = Control.MOUSE_FILTER_STOP
	captura.gui_input.connect(_mouse)
	add_child(captura)

	var titulo := Tema.rotulo("Treino de combate (teste)", 22, Tema.OURO, true)
	titulo.autowrap_mode = TextServer.AUTOWRAP_OFF
	titulo.position = Vector2(20, 12)
	titulo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(titulo)
	_btn3d = Tema.botao("Modo 3D (teste)", "normal", 16)
	_btn3d.position = Vector2(110, 52)
	_btn3d.pressed.connect(_alternar_3d)
	add_child(_btn3d)
	var sair := Tema.botao("Sair", "normal", 18)
	sair.position = Vector2(20, 52)
	sair.pressed.connect(sair_treino)
	add_child(sair)
	_placar = Tema.rotulo("", 16, Tema.AREIA)
	_placar.autowrap_mode = TextServer.AUTOWRAP_OFF
	_placar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_placar.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	_placar.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_placar.offset_left = -520
	_placar.offset_right = -16
	_placar.offset_top = 14
	add_child(_placar)
	_fb = Tema.titulo("", 46)
	_fb.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_fb.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_fb.offset_left = -400
	_fb.offset_right = 400
	_fb.offset_top = 70
	_fb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fb.modulate.a = 0.0
	add_child(_fb)
	if OS.has_feature("mobile") or OS.has_feature("web_android") or OS.has_feature("web_ios"):
		_montar_botoes()
	else:
		var dica := Tema.rotulo("A/D ou setas: andar  ·  Espaço: esquivar  ·  Botão direito: defender (erga no momento do golpe = parry)  ·  Clique: ataque leve  ·  Segure o clique: ataque pesado  ·  Esc: sair", 15, Tema.CINZA)
		dica.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		dica.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
		dica.offset_top = -44
		dica.offset_bottom = -8
		dica.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(dica)
	resized.connect(_ajustar)
	_ajustar()
	_atualizar_placar()
	_fb_texto("Treine: o boneco ataca de tempos em tempos", "cinza")


## Troca o visual 2D (sprites) pelo 3D de teste (manequim com animações de espada) e volta.
func _alternar_3d() -> void:
	if _c3d == null:
		_c3d = Cena3DTreino.new()
		_c3d.size = PALCO
		_c3d.visible = false
		_palco.add_child(_c3d)
		_palco.move_child(_c3d, 0)
	var ligar := not _c3d.visible
	_c3d.visible = ligar
	_arte2d.visible = not ligar
	_veu2d.visible = not ligar
	_jogador.visible = not ligar
	_boneco.visible = not ligar
	_btn3d.text = "Modo 2D" if ligar else "Modo 3D (teste)"


func _ajustar() -> void:
	var k := minf(size.x / PALCO.x, size.y / PALCO.y)
	_palco.scale = Vector2(k, k)
	_palco.position = (size - PALCO * k) / 2.0
	_posicionar_botoes()


# ---------- Botões de toque ----------

func _montar_botoes() -> void:
	var defs := [["esq", "<", "hold"], ["dir", ">", "hold"], ["esquiva", "ESQ", "tap"], ["defesa", "DEF", "hold"], ["leve", "LEVE", "tap"], ["pesado", "PESADO", "tap"]]
	for d in defs:
		var p := PanelContainer.new()
		p.mouse_filter = Control.MOUSE_FILTER_IGNORE
		p.add_theme_stylebox_override("panel", Tema.caixa(Color(0.1, 0.06, 0.05, 0.78), Tema.OURO_ESCURO, 14, 2, 4))
		var l := Tema.rotulo(str(d[1]), 24 if str(d[1]).length() > 1 else 38, Tema.AREIA, true)
		l.autowrap_mode = TextServer.AUTOWRAP_OFF
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		p.add_child(l)
		add_child(p)
		_botoes.append({"id": d[0], "no": p, "tipo": d[2]})


func _posicionar_botoes() -> void:
	if _botoes.is_empty():
		return
	var lado := clampf(size.y * 0.2, 70.0, 120.0)
	var m := 20.0
	var y1 := size.y - lado - m
	var y2 := y1 - lado - 10.0
	var pos := {
		"esq": Vector2(m, y1), "dir": Vector2(m + lado + 10.0, y1),
		"pesado": Vector2(size.x - m - lado, y1), "leve": Vector2(size.x - m - lado * 2.0 - 10.0, y1),
		"defesa": Vector2(size.x - m - lado * 2.0 - 10.0, y2), "esquiva": Vector2(size.x - m - lado, y2),
	}
	for b in _botoes:
		var no: Control = b["no"]
		no.position = pos[b["id"]]
		no.size = Vector2(lado, lado)


func _botao_em(p: Vector2) -> String:
	for b in _botoes:
		if (b["no"] as Control).get_global_rect().has_point(p):
			return str(b["id"])
	return ""


func _brilho(id: String, ligado: bool) -> void:
	for b in _botoes:
		if b["id"] == id:
			(b["no"] as Control).modulate = Color(1.5, 1.3, 1.1) if ligado else Color.WHITE


func _botao_apertar(id: String) -> void:
	_brilho(id, true)
	match id:
		"esq":
			_toque_esq = true
		"dir":
			_toque_dir = true
		"esquiva":
			_nucleo.esquiva()
		"defesa":
			_nucleo.defesa(true)
		"leve":
			_nucleo.ataque_leve()
		"pesado":
			_nucleo.ataque_pesado()
	_direcao()


func _botao_soltar(id: String) -> void:
	_brilho(id, false)
	match id:
		"esq":
			_toque_esq = false
		"dir":
			_toque_dir = false
		"defesa":
			_nucleo.defesa(false)
	_direcao()


func _direcao() -> void:
	var d := 0
	if _tecla_dir or _toque_dir:
		d += 1
	if _tecla_esq or _toque_esq:
		d -= 1
	_nucleo.definir_direcao(d)


# ---------- Entrada ----------

func _input(ev: InputEvent) -> void:
	if _fechado:
		return
	if ev is InputEventKey and not ev.echo:
		var k := ev as InputEventKey
		match k.keycode:
			KEY_A, KEY_LEFT:
				_tecla_esq = k.pressed
				_direcao()
			KEY_D, KEY_RIGHT:
				_tecla_dir = k.pressed
				_direcao()
			KEY_SPACE:
				if k.pressed:
					_nucleo.esquiva()
			KEY_J:
				if k.pressed:
					_nucleo.ataque_leve()
			KEY_K:
				if k.pressed:
					_nucleo.ataque_pesado()
			KEY_ESCAPE:
				if k.pressed:
					sair_treino()
		get_viewport().set_input_as_handled()
	elif ev is InputEventScreenTouch:
		var st := ev as InputEventScreenTouch
		if st.pressed:
			var id := _botao_em(st.position)
			if id != "":
				_toques[st.index] = id
				_botao_apertar(id)
		elif _toques.has(st.index):
			_botao_soltar(str(_toques[st.index]))
			_toques.erase(st.index)
	elif ev is InputEventScreenDrag:
		var sd := ev as InputEventScreenDrag
		if _toques.has(sd.index):
			var atual := str(_toques[sd.index])
			var novo := _botao_em(sd.position)
			var tipo_atual := _tipo(atual)
			if novo != atual and tipo_atual == "hold":
				_botao_soltar(atual)
				if novo != "" and _tipo(novo) == "hold":
					_toques[sd.index] = novo
					_botao_apertar(novo)
				else:
					_toques.erase(sd.index)


func _tipo(id: String) -> String:
	for b in _botoes:
		if b["id"] == id:
			return str(b["tipo"])
	return ""


func _mouse(ev: InputEvent) -> void:
	if _fechado or not ev is InputEventMouseButton:
		return
	var mb := ev as InputEventMouseButton
	if mb.device == InputEvent.DEVICE_ID_EMULATION:
		return  # clique emulado a partir do toque: os botões na tela cuidam
	if mb.button_index == MOUSE_BUTTON_LEFT:
		if mb.pressed:
			_nucleo.atacar_pressionar()
		else:
			_nucleo.atacar_soltar()
	elif mb.button_index == MOUSE_BUTTON_RIGHT:
		_nucleo.defesa(mb.pressed)


# ---------- Quadro a quadro ----------

func _process(delta: float) -> void:
	if _fechado:
		return
	_nucleo.atualizar(minf(delta, 0.05))
	_jogador.base.x = _nucleo.x
	_jogador.position.x = _nucleo.x
	if _c3d != null and _c3d.visible:
		_c3d.atualizar(_nucleo)
	for e in _nucleo.pegar_eventos():
		match e["tipo"]:
			"p_pose":
				_jogador.pose(str(e["pose"]))
				if _c3d != null and _c3d.visible:
					_c3d.pose_jogador(str(e["pose"]), _nucleo)
			"b_pose":
				_boneco.pose(str(e["pose"]))
				if _c3d != null and _c3d.visible:
					_c3d.pose_boneco(str(e["pose"]), str(e.get("tinta", "")))
				match str(e.get("tinta", "")):
					"alerta":
						_boneco.modulate = Color(1.0, 0.55, 0.45)
					"atordoado":
						_boneco.modulate = Color(0.55, 0.7, 1.0)
					_:
						_boneco.modulate = Color(0.85, 0.75, 0.6)
			"feedback":
				_fb_texto(str(e["texto"]), str(e["cor"]))
				_atualizar_placar()
	if _nucleo.b_estado == "espera" and _boneco.modulate != Color(0.85, 0.75, 0.6):
		_boneco.modulate = Color(0.85, 0.75, 0.6)
	var mostrar := _nucleo.carregando and _nucleo.carga > 0.08
	_barra.visible = mostrar
	if mostrar:
		var f := clampf(_nucleo.carga / TreinoCombate.CARGA_PESADO, 0.0, 1.0)
		_barra.size = Vector2(110.0 * f, 8.0)
		_barra.position = Vector2(_nucleo.x - 55.0, CHAO_Y - 400.0)
		_barra.color = Color("ffd25a") if f >= 1.0 else Color("c9a24a")


func _fb_texto(texto: String, cor: String) -> void:
	_fb.text = texto
	_fb.add_theme_color_override("font_color", COR_FB.get(cor, Color.WHITE))
	_fb.modulate.a = 1.0
	if _tw_fb and _tw_fb.is_valid():
		_tw_fb.kill()
	_tw_fb = _fb.create_tween()
	_tw_fb.tween_interval(0.5)
	_tw_fb.tween_property(_fb, "modulate:a", 0.0, 0.7)


func _atualizar_placar() -> void:
	var p: Dictionary = _nucleo.placar
	_placar.text = "Parry %d  ·  Esquivas %d  ·  Bloqueios %d  ·  Leves %d  ·  Pesados %d  ·  Críticos %d  ·  Levou %d" % [
		p["parries"], p["esquivas"], p["bloqueios"], p["leves"], p["pesados"], p["criticos"], p["levados"]]


func sair_treino() -> void:
	if _fechado:
		return
	_fechado = true
	hide()
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_free()
