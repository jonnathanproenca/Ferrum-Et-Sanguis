class_name TelaTreinoCombate
extends Control
## Mini-arena de treino: o jogador controla o gladiador contra um boneco, só com os comandos (sem vida).
## Teclado/mouse: A/D ou setas andam, Espaço esquiva, botão direito defende (parry no tempo certo),
## clique = ataque leve, segurar = pesado. Toque: botões na tela (multitoque). A lógica fica em TreinoCombate.

const PALCO := Vector2(1280, 720)
const CHAO_Y := 610.0
const COR_FB := {"branco": Color("f2e6cc"), "ouro": Color("ffd25a"), "verde": Color("9be05a"), "vermelho": Color("e06a5a"), "cinza": Color("9a9a9a")}

var _nucleo: TreinoCombate
var _palco: Control
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
var _bot_estilo: Dictionary = {}   ## id do estilo -> Button
var _ed: PanelContainer            ## editor de peças (posição/rotação/escala de cada acessório)
var _ed_item := "cap"
var _ed_sl: Dictionary = {}        ## campo -> HSlider
var _ed_val: Dictionary = {}       ## campo -> Label
var _ed_bot: Dictionary = {}       ## item -> Button
var _rep: Timer                    ## repetição ao segurar as setas
var _rep_campo := ""
var _rep_passo := 0.0


## Abre o treino sobre `pai`, com o estilo do gladiador `g` (vazio = murmilo).
static func abrir(pai: Node, _g: Dictionary = {}) -> TelaTreinoCombate:
	var topo: Node = pai
	while topo.get_parent() is Control:
		topo = topo.get_parent()
	var t := TelaTreinoCombate.new()
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
	_c3d = Cena3DTreino.new()
	_c3d.size = PALCO
	_palco.add_child(_c3d)

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

	var titulo := Tema.rotulo("Treino de combate", 22, Tema.OURO, true)
	titulo.autowrap_mode = TextServer.AUTOWRAP_OFF
	titulo.position = Vector2(20, 12)
	titulo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(titulo)
	var sair := Tema.botao("Sair", "normal", 18)
	sair.position = Vector2(20, 52)
	sair.pressed.connect(sair_treino)
	add_child(sair)
	_montar_estilos()
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


## Lista de estilos no canto esquerdo: troca o gladiador na hora (gladiador 1 ou gladiador 2 com acessórios).
func _montar_estilos() -> void:
	var rot := Tema.rotulo("Gladiador / estilo", 14, Tema.CINZA)
	rot.position = Vector2(20, 106)
	rot.autowrap_mode = TextServer.AUTOWRAP_OFF
	rot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(rot)
	var y := 128.0
	for id in Estilos3D.ORDEM:
		var b := Tema.botao(Estilos3D.nome(id), "normal", 14)
		b.custom_minimum_size = Vector2(170, 28)
		b.position = Vector2(20, y)
		b.pressed.connect(_escolher_estilo.bind(id))
		add_child(b)
		_bot_estilo[id] = b
		y += 31.0
	var bed := Tema.botao("Ajustar peças", "ouro", 14)
	bed.custom_minimum_size = Vector2(170, 30)
	bed.position = Vector2(20, y + 8)
	bed.pressed.connect(_alternar_editor)
	add_child(bed)
	_montar_editor()
	_marcar_estilo()


func _escolher_estilo(id: String) -> void:
	_c3d.trocar_jogador(id)
	_marcar_estilo()
	_ed_carregar()


# ---------- Editor de peças ----------

const ED_CAMPOS := [
	["px", "Posição X (cm)", -30.0, 30.0, 0.5], ["py", "Posição Y (cm)", -30.0, 30.0, 0.5], ["pz", "Posição Z (cm)", -30.0, 30.0, 0.5],
	["rx", "Giro X (°)", -180.0, 180.0, 1.0], ["ry", "Giro Y (°)", -180.0, 180.0, 1.0], ["rz", "Giro Z (°)", -180.0, 180.0, 1.0],
	["esc", "Tamanho", 0.3, 2.5, 0.01],
]
const ED_ITENS := [["cap", "Capacete"], ["dir", "Mão dir."], ["esq", "Mão esq."], ["esc", "Escudo"]]
const ED_POSES := [["Guarda", "Sword_Idle", 0.0], ["Leve", "Sword_Regular_A", 0.3], ["Pesado", "Sword_Attack", 0.5], ["Defesa", "Idle_Shield", 0.3]]


func _montar_editor() -> void:
	_rep = Timer.new()
	_rep.one_shot = true
	_rep.timeout.connect(_rep_tick)
	add_child(_rep)
	_ed = PanelContainer.new()
	_ed.visible = false
	_ed.mouse_filter = Control.MOUSE_FILTER_STOP
	_ed.add_theme_stylebox_override("panel", Tema.caixa(Color(0.08, 0.06, 0.05, 0.92), Tema.OURO_ESCURO, 8, 1, 10))
	add_child(_ed)
	_ed.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	_ed.offset_left = -330
	_ed.offset_right = -12
	_ed.offset_top = 52
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 3)
	_ed.add_child(v)
	v.add_child(Tema.rotulo("Ajustar peça do estilo atual", 15, Tema.OURO))
	var linha := HBoxContainer.new()
	linha.add_theme_constant_override("separation", 4)
	v.add_child(linha)
	for it in ED_ITENS:
		var b := Tema.botao(it[1], "normal", 13)
		b.custom_minimum_size = Vector2(0, 28)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.pressed.connect(_ed_escolher.bind(it[0]))
		linha.add_child(b)
		_ed_bot[it[0]] = b
	var lp := HBoxContainer.new()
	lp.add_theme_constant_override("separation", 4)
	v.add_child(lp)
	for ps in ED_POSES:
		var b2 := Tema.botao(ps[0], "normal", 13)
		b2.custom_minimum_size = Vector2(0, 28)
		b2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b2.pressed.connect(func(): _c3d.ver_pose(ps[1], ps[2]))
		lp.add_child(b2)
	var lz := HBoxContainer.new()
	lz.add_theme_constant_override("separation", 4)
	v.add_child(lz)
	for zz in [["Câmera normal", 0], ["Corpo", 1], ["Cabeça", 2]]:
		var bzm := Tema.botao(zz[0], "normal", 13)
		bzm.custom_minimum_size = Vector2(0, 28)
		bzm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		bzm.pressed.connect(func(): _c3d.zoom(zz[1]))
		lz.add_child(bzm)
	for c in ED_CAMPOS:
		var l := Tema.rotulo(c[1], 13, Tema.AREIA)
		l.autowrap_mode = TextServer.AUTOWRAP_OFF
		v.add_child(l)
		var linha_s := HBoxContainer.new()
		linha_s.add_theme_constant_override("separation", 3)
		v.add_child(linha_s)
		var sl := HSlider.new()
		sl.min_value = c[2]
		sl.max_value = c[3]
		sl.step = c[4]
		sl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		sl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		sl.custom_minimum_size = Vector2(60, 18)
		sl.focus_mode = Control.FOCUS_NONE
		sl.value_changed.connect(func(_x): _ed_mudou())
		for sp in [["«", -5.0], ["‹", -1.0]]:
			linha_s.add_child(_ed_seta(sp[0], str(c[0]), float(sp[1]) * float(c[4])))
		linha_s.add_child(sl)
		for sp2 in [["›", 1.0], ["»", 5.0]]:
			linha_s.add_child(_ed_seta(sp2[0], str(c[0]), float(sp2[1]) * float(c[4])))
		var val := Tema.rotulo("0", 13, Tema.OURO)
		val.custom_minimum_size = Vector2(42, 0)
		val.autowrap_mode = TextServer.AUTOWRAP_OFF
		val.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		linha_s.add_child(val)
		_ed_sl[c[0]] = sl
		_ed_val[c[0]] = val
	var lb := HBoxContainer.new()
	lb.add_theme_constant_override("separation", 4)
	v.add_child(lb)
	var bz := Tema.botao("Zerar peça", "normal", 13)
	bz.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bz.pressed.connect(_ed_zerar)
	lb.add_child(bz)
	var bc := Tema.botao("Copiar ajustes", "primario", 13)
	bc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bc.pressed.connect(_ed_copiar)
	lb.add_child(bc)


## Botão de seta: um clique soma o passo; segurando, repete.
func _ed_seta(txt: String, campo: String, passo: float) -> Button:
	var b := Tema.botao(txt, "normal", 14)
	b.custom_minimum_size = Vector2(24, 24)
	b.button_down.connect(func():
		_ed_passo(campo, passo)
		_rep_campo = campo
		_rep_passo = passo
		_rep.start(0.4))
	b.button_up.connect(func(): _rep.stop())
	return b


func _ed_passo(campo: String, passo: float) -> void:
	var sl := _ed_sl[campo] as HSlider
	sl.value = clampf(sl.value + passo, sl.min_value, sl.max_value)   # dispara value_changed -> _ed_mudou


func _rep_tick() -> void:
	_ed_passo(_rep_campo, _rep_passo)
	_rep.start(0.06)


func _alternar_editor() -> void:
	_ed.visible = not _ed.visible
	_c3d.editor = _ed.visible
	if _ed.visible:
		_c3d.ver_pose("Sword_Idle", 0.0)
		_ed_escolher(_ed_item)
	else:
		_c3d.editor = false


func _ed_chave() -> String:
	return _c3d.estilo_atual() + "/" + _ed_item


func _ed_escolher(item: String) -> void:
	_ed_item = item
	for k in _ed_bot:
		(_ed_bot[k] as Button).modulate = Color(1.0, 0.85, 0.4) if k == item else Color(1, 1, 1)
	_ed_carregar()


func _ed_carregar() -> void:
	if _ed == null:
		return
	var a := Estilos3D.ajuste_de(_ed_chave())
	var vals := {"px": a["pos"][0], "py": a["pos"][1], "pz": a["pos"][2], "rx": a["rot"][0], "ry": a["rot"][1], "rz": a["rot"][2], "esc": a["esc"]}
	for k in vals:
		(_ed_sl[k] as HSlider).set_value_no_signal(float(vals[k]))
		(_ed_val[k] as Label).text = str(snappedf(float(vals[k]), 0.01))


func _ed_mudou() -> void:
	var g := func(k: String) -> float: return (_ed_sl[k] as HSlider).value
	Estilos3D.ajustes[_ed_chave()] = {
		"pos": [g.call("px"), g.call("py"), g.call("pz")],
		"rot": [g.call("rx"), g.call("ry"), g.call("rz")],
		"esc": g.call("esc"),
	}
	for k in _ed_sl:
		(_ed_val[k] as Label).text = str(snappedf((_ed_sl[k] as HSlider).value, 0.01))
	Estilos3D.reaplicar(_ed_chave())
	Estilos3D.salvar_ajustes()


func _ed_zerar() -> void:
	Estilos3D.ajustes.erase(_ed_chave())
	Estilos3D.reaplicar(_ed_chave())
	Estilos3D.salvar_ajustes()
	_ed_carregar()


func _ed_copiar() -> void:
	DisplayServer.clipboard_set(JSON.stringify(Estilos3D.ajustes))
	_fb_texto("Ajustes copiados: cole na conversa", "cinza")


func _marcar_estilo() -> void:
	var atual := _c3d.estilo_atual()
	for id in _bot_estilo:
		(_bot_estilo[id] as Button).modulate = Color(1.0, 0.85, 0.4) if id == atual else Color(1, 1, 1)


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
	_c3d.atualizar(_nucleo)
	for e in _nucleo.pegar_eventos():
		match e["tipo"]:
			"p_pose":
				_c3d.pose_jogador(str(e["pose"]), _nucleo)
			"b_pose":
				_c3d.pose_boneco(str(e["pose"]), str(e.get("tinta", "")))
			"feedback":
				_fb_texto(str(e["texto"]), str(e["cor"]))
				_atualizar_placar()
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
