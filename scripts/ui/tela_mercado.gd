class_name TelaMercado
extends Tela
## Aba "mercado": cena do mercado de escravos (mercador animado, som ambiente) e as cartas dos 5 escravos à venda.

const CENA := {"w": 1376.0, "h": 768.0, "fundo": "assets/mercado/fundo.jpg", "mercador": Rect2(428, 287, 264, 305)}
const NOME_CONDICAO := {"jovem": "Jovem", "maduro": "Maduro", "cicatrizado": "Cicatrizado"}
const DESC_CONDICAO := {"jovem": "+1 treino em atributo aleatório, mais caro", "maduro": "equilibrado", "cicatrizado": "+1 vitalidade, mais barato"}
const COR_CONDICAO := {"jovem": Color("8fbf7a"), "maduro": Color("e8d5b0"), "cicatrizado": Color("d88a6a")}

var _cena: CenaFracao
var _info: Label
var _aviso: Label
var _cartas: HBoxContainer
var _vazio: Label
var _som: AudioStreamPlayer
var _entrada := false

func construir() -> void:
	var sc := ScrollContainer.new()
	sc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(sc)
	var v := Tema.vbox(0)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.add_child(v)

	# Cena
	_cena = CenaFracao.new(Tema.textura(CENA["fundo"]), Vector2(CENA["w"], CENA["h"]))
	_cena.foco_y = 0.52
	_cena.foco_x = 0.5
	_cena.custom_minimum_size = Vector2(0, 200)
	_cena.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(_cena)
	var merc := Anim.criar("mercador")
	_cena.adicionar(merc, CENA["mercador"])
	_cena.desvanecer_base(46, Color("1d1411"))
	# Plaquinha de informação sobre a cena
	var m := MarginContainer.new()
	m.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	m.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for lado in ["left", "top"]:
		m.add_theme_constant_override("margin_" + lado, 14)
	_cena.add_child(m)
	var caixa := PanelContainer.new()
	caixa.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	caixa.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	caixa.add_theme_stylebox_override("panel", Tema.caixa(Color(0.07, 0.04, 0.03, 0.82), Tema.OURO_ESCURO, 8, 1, 8))
	caixa.mouse_filter = Control.MOUSE_FILTER_IGNORE
	m.add_child(caixa)
	var iv := Tema.vbox(2)
	caixa.add_child(iv)
	iv.add_child(Tema.titulo("Mercado de escravos", 24))
	_info = Tema.rotulo("", 17, Tema.AREIA)
	iv.add_child(_info)
	_aviso = Tema.rotulo("", 16, Tema.OCRE)
	_aviso.custom_minimum_size = Vector2(300, 0)
	iv.add_child(_aviso)

	# Painel das cartas
	var painel := PanelContainer.new()
	var sb := Tema.caixa(Tema.PAINEL, Tema.BORDA, 0, 0, 10)
	sb.border_width_top = 2
	sb.border_color = Tema.OURO_ESCURO
	painel.add_theme_stylebox_override("panel", sb)
	v.add_child(painel)
	var pv := Tema.vbox(8)
	painel.add_child(pv)
	var meta := Tema.rotulo("O mercado vende escravos e é renovado a cada turno. Cada um traz uma tendência de atributo, uma terra e uma condição física. Depois de comprado, você escolhe o estilo em que ele vai lutar e ele recebe o kit básico.", 15, Tema.CINZA)
	pv.add_child(meta)
	_cartas = Tema.hbox(10)
	_cartas.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pv.add_child(_cartas)
	_vazio = Tema.rotulo("Não há escravos à venda. Novos chegam no próximo turno.", 18, Tema.OCRE)
	pv.add_child(_vazio)

	# Som ambiente próprio (loop baixo enquanto a aba estiver aberta)
	_som = AudioStreamPlayer.new()
	var s: AudioStream = load("res://assets/audio/ambiente/mercado.mp3")
	if s:
		s = s.duplicate()
		if s is AudioStreamMP3:
			s.loop = true
		_som.stream = s
	add_child(_som)

func _process(_d: float) -> void:
	if _som and _som.playing and not is_visible_in_tree():
		_som.stop()

func _exit_tree() -> void:
	if _som:
		_som.stop()

func _volume() -> float:
	var p: Dictionary = Jogo.prefs["audio"]
	if not p["ativo"]:
		return -80.0
	var lin: float = float(p["efeitos"]) * 0.5
	return -80.0 if lin <= 0.001 else linear_to_db(lin)

func ao_mostrar() -> void:
	_entrada = true
	super.ao_mostrar()
	if _som and _som.stream:
		_som.volume_db = _volume()
		if not _som.playing:
			_som.play()
	Som.voz("mercador")

func atualizar() -> void:
	var e: Dictionary = Jogo.e
	if _som:
		_som.volume_db = _volume()
	var cap: int = Game.capacidade_ludus(e)
	var n: int = e["gladiadores"].size()
	_info.text = "Ludus: %d/%d gladiadores" % [n, cap]
	if n >= cap and cap < Game.MAX_GLADIADORES:
		_aviso.text = "Ludus lotado (%d/%d). Construa os alojamentos para ampliar." % [n, cap]
	elif n >= cap:
		_aviso.text = "Ludus lotado (%d/%d)." % [n, cap]
	else:
		_aviso.text = ""
	_aviso.visible = _aviso.text != ""
	Tema.limpar(_cartas)
	var lista: Array = e["mercado"]
	_vazio.visible = lista.is_empty()
	var i := 0
	for g in lista:
		var c := _carta(e, g)
		_cartas.add_child(c)
		if _entrada:
			c.modulate.a = 0.0
			var tw := c.create_tween()
			tw.tween_interval(0.07 * i)
			tw.tween_property(c, "modulate:a", 1.0, 0.3)
		i += 1
	_entrada = false

func _carta(e: Dictionary, g: Dictionary) -> Control:
	var preco: int = Game.preco_recruta(e, g)
	var cheio: bool = e["gladiadores"].size() >= Game.capacidade_ludus(e)
	var sem_ouro: bool = int(e["ouro"]) < preco
	var casa: Dictionary = Game.lanista_da_casa(e)
	var cond: String = str(g.get("condicao", ""))
	var tend: String = str(g.get("tendencia", ""))

	var p := PanelContainer.new()
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	p.custom_minimum_size = Vector2(190, 0)
	var sb := Tema.caixa(Color("211612"), Tema.BORDA, 10, 1, 8)
	sb.shadow_color = Color(0, 0, 0, 0.45)
	sb.shadow_size = 6
	p.add_theme_stylebox_override("panel", sb)
	var v := Tema.vbox(5)
	p.add_child(v)

	# Retrato
	var thumb := PanelContainer.new()
	thumb.add_theme_stylebox_override("panel", Tema.caixa(Color(0.11, 0.07, 0.05), Color("3a2418"), 8, 1, 4))
	v.add_child(thumb)
	var centro := CenterContainer.new()
	thumb.add_child(centro)
	var spr := Sprites.controle_gladiador(g, 92)
	spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	centro.add_child(spr)

	# Nome
	var h := Tema.hbox(6)
	v.add_child(h)
	var nome := Tema.rotulo(str(g["nome"]), 22, Tema.OURO, true)
	nome.autowrap_mode = TextServer.AUTOWRAP_OFF
	nome.clip_text = true
	nome.custom_minimum_size = Vector2(60, 0)
	nome.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nome.add_theme_font_size_override("font_size", 19)
	h.add_child(nome)
	var tag := Tema.rotulo("Escravo", 14, Tema.OCRE)
	tag.autowrap_mode = TextServer.AUTOWRAP_OFF
	h.add_child(tag)

	# Terra · tendência
	var terra: String = str(Model.terra_por_id(g["terra"]).get("nome", g["terra"]))
	var carac := terra
	if tend != "":
		carac += " · Tendência: " + Model.NOME_ATRIBUTO[tend]
	v.add_child(Tema.rotulo(carac, 15, Tema.CINZA))

	# Condição
	if cond != "":
		var cp := PanelContainer.new()
		var cs := Tema.caixa(Color(COR_CONDICAO[cond], 0.1), Color(COR_CONDICAO[cond], 0.55), 6, 1, 4)
		cp.add_theme_stylebox_override("panel", cs)
		cp.custom_minimum_size = Vector2(0, 54)
		var cl := RichTextLabel.new()
		cl.bbcode_enabled = true
		cl.fit_content = true
		cl.scroll_active = false
		cl.add_theme_font_size_override("normal_font_size", 15)
		cl.add_theme_font_size_override("bold_font_size", 15)
		cl.text = "[b][color=#%s]%s[/color][/b]: %s" % [Color(COR_CONDICAO[cond]).to_html(false), NOME_CONDICAO[cond], DESC_CONDICAO[cond]]
		cp.add_child(cl)
		v.add_child(cp)

	# Atributos
	var st: Dictionary = Model.stats_do_gladiador(g, str(casa["especialidade"]), Game.extra_da_casa(e))
	var grade := GridContainer.new()
	grade.columns = 3
	grade.add_theme_constant_override("h_separation", 4)
	for a in Model.ATRIBUTOS:
		var ch := PanelContainer.new()
		ch.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var destaque: bool = a == tend
		ch.add_theme_stylebox_override("panel", Tema.caixa(Color(0.2, 0.14, 0.06) if destaque else Color(0.1, 0.065, 0.05), Tema.OURO_ESCURO if destaque else Color("3a2418"), 5, 1, 2))
		var cv := Tema.vbox(0)
		ch.add_child(cv)
		var l1 := Tema.rotulo(Model.SIGLA_ATRIBUTO[a], 12, Tema.OURO if destaque else Tema.CINZA)
		l1.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cv.add_child(l1)
		var l2 := Tema.rotulo(str(st[a]), 20, Tema.OURO if destaque else Tema.COR_ATRIBUTO[a])
		l2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cv.add_child(l2)
		ch.tooltip_text = Model.NOME_ATRIBUTO[a]
		grade.add_child(ch)
	v.add_child(grade)

	# Glória
	var gl := int(g.get("gloria", 0))
	if gl > 0:
		var lg := Tema.rotulo("%s · Glória %d" % [Model.titulo_gloria(gl), gl], 15, Tema.OURO)
		lg.autowrap_mode = TextServer.AUTOWRAP_OFF
		v.add_child(lg)

	# Compra
	var b := Tema.botao("Comprar · %d ouro" % preco, "primario", 18)
	b.disabled = cheio or sem_ouro
	if cheio:
		b.tooltip_text = "Ludus lotado."
	elif sem_ouro:
		b.tooltip_text = "Faltam %d de ouro." % (preco - int(e["ouro"]))
	var gid: String = str(g["id"])
	b.pressed.connect(func():
		if Jogo.resultado(Game.recrutar(Jogo.e, gid)):
			Som.sfx("sfx/moeda"))
	var fim := Control.new()
	fim.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(fim)
	v.add_child(b)
	return p
