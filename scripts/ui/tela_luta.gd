class_name TelaLuta
extends Control
## Visualizador da luta (tela cheia por cima do HUD). Recebe o payload de `Game.lutar_arena` / `Game.lutar_campanha`
## e reproduz os eventos em sequência: esquiva, defesa, acerto (dano/crítico/pesado), carga, efeitos, atordoado, rendição e morte.
## Uso (no Hud): `Jogo.iniciar_luta.connect(func(p, fim, des, pul): TelaLuta.abrir(self, p, fim, des, pul))`.

const E := 4.0 / 3.0
const PALCO := Vector2(1280, 720)
const Y_PES := 548.0
const CENTRO_PADRAO := 640.0
const CENTRO := {"coliseu": 530.0 * E}
const FATOR_ARENA := {"pompeia": 1.0, "capua": 0.7, "coliseu": 0.66, "poco": 1.0}
const NOME_EFEITO := {"sangramento": "Sangramento", "envenenamento": "Envenenamento", "contusao": "Contusão", "queimadura": "Queimadura"}
const COR_EFEITO := {"sangramento": Color("d6483a"), "envenenamento": Color("7ac043"), "contusao": Color("e0c050"), "queimadura": Color("ff8a30")}
const DURACAO_EFEITO := {"sangramento": 2, "envenenamento": 4, "contusao": -1, "queimadura": 1}
const TRILHAS := ["menu", "gestao", "pompeia", "capua", "coliseu", "poco", "campanha"]
const COR_A := Color("f2d28a")
const COR_B := Color("9bb7e0")

var _payload: Dictionary = {}
var _ao_fim := Callable()
var _ao_desistir := Callable()
var _ao_pular := Callable()
var vel := 1.0
var _arena_id := "coliseu"
var _fim_mostrado := false
var _pausado := false
var _encerrado := false
var _palco: Node2D
var _area: Control
var _plateia: PlateiaLuta
var _lutadores := {}            ## id -> LutadorLuta
var _fichas := {}               ## id -> Dictionary {lado, hp, hp_max, carga, barra, nome_lbl, linha, efeitos, chips}
var _b_vel: Button
var _b_pular: Button
var _b_desistir: Button
var _flash: ColorRect
var _sobreposicao: Control
var _palco_pos := Vector2.ZERO
var _pilha := {}                ## x -> números flutuantes ativos (empilham para não se sobrepor)

## Abre a tela de luta como filha de `pai` (normalmente o Hud) e a devolve.
static func abrir(pai: Node, payload: Dictionary, ao_fim: Callable, ao_desistir: Callable = Callable(), ao_pular: Callable = Callable()) -> TelaLuta:
	var t := TelaLuta.new()
	t.iniciar(payload, ao_fim, ao_desistir, ao_pular)
	var camada := CanvasLayer.new()   # camada própria: fica acima de qualquer z_index das abas
	camada.layer = 100
	pai.add_child(camada)
	camada.add_child(t)
	return t

func iniciar(payload: Dictionary, ao_fim: Callable, ao_desistir: Callable = Callable(), ao_pular: Callable = Callable()) -> void:
	_payload = payload
	_ao_fim = ao_fim
	_ao_desistir = ao_desistir
	_ao_pular = ao_pular

func _ready() -> void:
	theme = Tema.tema()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_arena_id = str(_payload.get("arte", "assets/arenas/coliseu.png")).get_file().get_basename()
	if not FATOR_ARENA.has(_arena_id):
		_arena_id = "coliseu"
	Som.musica(_chave_trilha(str(_payload.get("trilha", ""))))
	_montar_cena()
	_montar_ui()
	resized.connect(_ajustar_palco)
	_ajustar_palco()
	_rodar()

static func _chave_trilha(t: String) -> String:
	var base := t.split(":")[0]
	return base if base in TRILHAS else "campanha"

# ---------- Montagem ----------

func _montar_cena() -> void:
	var tex: Texture2D = Tema.textura(str(_payload.get("arte", "")))
	if tex == null:
		tex = Tema.textura("assets/arenas/%s.png" % _arena_id)
	var fundo := ColorRect.new()
	fundo.color = Color.BLACK
	fundo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fundo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fundo)
	var ext := TextureRect.new()
	ext.texture = tex
	ext.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ext.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	ext.modulate = Color(0.32, 0.28, 0.26)
	ext.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ext.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(ext)
	_area = Control.new()
	_area.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_area.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_area.clip_contents = true
	add_child(_area)
	_palco = Node2D.new()
	_area.add_child(_palco)
	var bg := Sprite2D.new()
	bg.centered = false
	bg.texture = tex
	bg.z_index = -10
	if tex:
		bg.scale = PALCO / tex.get_size()
	_palco.add_child(bg)
	_plateia = PlateiaLuta.new()
	_plateia.vel = vel
	_palco.add_child(_plateia)
	_plateia.montar(_arena_id, str(_payload.get("plateia", "meia")))
	_criar_lutadores()
	_flash = ColorRect.new()
	_flash.color = Color(1, 1, 1, 0)
	_flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_flash.z_index = 2500
	add_child(_flash)

func _ajustar_palco() -> void:
	if _palco == null:
		return
	var s := minf(size.x / PALCO.x, size.y / PALCO.y)
	_palco.scale = Vector2(s, s)
	_palco_pos = (size - PALCO * s) / 2.0
	_palco.position = _palco_pos

func _posicoes(n: int, lado: String, centro: float, f: float) -> Array:
	var s := -1.0 if lado == "A" else 1.0
	if n == 1:
		return [Vector2(centro + s * 75.0 * f * E, Y_PES)]
	return [Vector2(centro + s * 150.0 * f * E, Y_PES - 30.0 * f * E), Vector2(centro + s * 80.0 * f * E, Y_PES + 28.0 * f * E)]

func _criar_lutadores() -> void:
	var centro: float = CENTRO.get(_arena_id, CENTRO_PADRAO)
	var f: float = FATOR_ARENA[_arena_id]
	for lado in ["A", "B"]:
		var lista: Array = _payload["lutadores" + lado]
		var pos := _posicoes(lista.size(), lado, centro, f)
		for i in range(lista.size()):
			var v: Dictionary = lista[i]
			var escala := (1.0 if lista.size() == 1 else 0.76) * f
			var l := LutadorLuta.new(str(v["id"]), str(v["classe"]), escala, lado == "B", f, pos[i])
			l.z_index = int(pos[i].y)
			_palco.add_child(l)
			_lutadores[v["id"]] = l
			_fichas[v["id"]] = {"lado": lado, "hp": int(v["hpMax"]), "hp_max": int(v["hpMax"]), "carga": 0, "efeitos": {}, "chips": {}, "visual": v}

func _montar_ui() -> void:
	# Barra superior
	var topo := PanelContainer.new()
	var sb := Tema.caixa(Color(0.05, 0.03, 0.02, 0.72), Tema.OURO_ESCURO, 0, 0, 6)
	sb.border_width_bottom = 1
	topo.add_theme_stylebox_override("panel", sb)
	topo.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	topo.z_index = 2000
	add_child(topo)
	var h := Tema.hbox(10)
	topo.add_child(h)
	var tit := Tema.rotulo(str(_payload.get("titulo", "")), 24, Tema.OURO, true)
	tit.autowrap_mode = TextServer.AUTOWRAP_OFF
	h.add_child(tit)
	var sub_txt := str(_payload.get("arenaNome", ""))
	if sub_txt != "" and sub_txt != str(_payload.get("titulo", "")):
		var sub := Tema.rotulo("· " + sub_txt, 18, Tema.CINZA)
		sub.autowrap_mode = TextServer.AUTOWRAP_OFF
		sub.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		h.add_child(sub)
	var esp := Control.new()
	esp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(esp)
	_b_vel = Tema.botao("Velocidade 1x")
	_b_vel.pressed.connect(_alternar_vel)
	h.add_child(_b_vel)
	_b_pular = Tema.botao("Pular luta (−10%)", "ouro")
	_b_pular.pressed.connect(_pular)
	h.add_child(_b_pular)
	_b_desistir = Tema.botao("Desistir", "primario")
	_b_desistir.pressed.connect(_confirmar_desistencia)
	h.add_child(_b_desistir)

	# Faixa inferior com as fichas
	var faixa := PanelContainer.new()
	var sf := Tema.caixa(Color(0.04, 0.025, 0.02, 0.78), Tema.OURO_ESCURO, 0, 0, 8)
	sf.border_width_top = 1
	faixa.add_theme_stylebox_override("panel", sf)
	faixa.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	faixa.grow_vertical = Control.GROW_DIRECTION_BEGIN
	faixa.z_index = 2000
	add_child(faixa)
	var hb := Tema.hbox(40)
	faixa.add_child(hb)
	var col_a := Tema.vbox(6)
	col_a.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var col_b := Tema.vbox(6)
	col_b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hb.add_child(col_a)
	hb.add_child(col_b)
	for lado in ["A", "B"]:
		var lista: Array = _payload["lutadores" + lado]
		for v in lista:
			(col_a if lado == "A" else col_b).add_child(_criar_ficha(v, lado, lista.size() > 1))

func _criar_ficha(v: Dictionary, lado: String, compacto: bool) -> Control:
	var info: Dictionary = _fichas[v["id"]]
	var espelhado := lado == "B"
	var ps := 46 if compacto else 62
	var linha := Tema.hbox(10)
	linha.layout_direction = Control.LAYOUT_DIRECTION_RTL if espelhado else Control.LAYOUT_DIRECTION_LTR
	# retrato (cabeça e ombros do sprite)
	var moldura := PanelContainer.new()
	moldura.add_theme_stylebox_override("panel", Tema.caixa(Color(0.12, 0.08, 0.06), (COR_A if lado == "A" else COR_B), 6, 2, 0))
	moldura.custom_minimum_size = Vector2(ps, ps)
	var tr := TextureRect.new()
	var tex: Texture2D = Sprites.pose(str(v["classe"]), "guarda")
	if tex:
		var at := AtlasTexture.new()
		at.atlas = tex
		var tam := tex.get_size()
		at.region = Rect2(0, 0, tam.x, minf(tam.y, tam.x * 1.15))
		tr.texture = at
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tr.material = Sprites.material_variante(str(v["id"]))
	tr.custom_minimum_size = Vector2(ps, ps)
	tr.flip_h = espelhado
	moldura.add_child(tr)
	linha.add_child(moldura)
	var col := Tema.vbox(2)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.layout_direction = Control.LAYOUT_DIRECTION_LTR
	linha.add_child(col)
	var nome_h := Tema.hbox(8)
	var cl: String = str(Model.classes()[v["classe"]]["nome"]) if Model.classes().has(v["classe"]) else str(v["classe"])
	var nome := Tema.rotulo(str(v["nome"]), 17 if compacto else 20, COR_B if espelhado else COR_A, true)
	nome.autowrap_mode = TextServer.AUTOWRAP_OFF
	var classe_l := Tema.rotulo(cl, 15, Tema.CINZA)
	classe_l.autowrap_mode = TextServer.AUTOWRAP_OFF
	var chips := Tema.hbox(4)
	if espelhado:
		var e1 := Control.new()
		e1.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		nome_h.add_child(e1)
		nome_h.add_child(chips)
		nome_h.add_child(classe_l)
		nome_h.add_child(nome)
	else:
		nome_h.add_child(nome)
		nome_h.add_child(classe_l)
		nome_h.add_child(chips)
	col.add_child(nome_h)
	var barra := Barra.new()
	barra.espelhado = espelhado
	barra.alt_hp = 18.0 if compacto else 22.0
	barra.hp_max = int(v["hpMax"])
	barra.hp_atual = int(v["hpMax"])
	barra.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_child(barra)
	info["barra"] = barra
	info["nome_lbl"] = nome
	info["linha"] = linha
	info["chips_box"] = chips
	info["classe_lbl"] = classe_l
	return linha

# ---------- Controles ----------

func _alternar_vel() -> void:
	vel = 2.0 if vel == 1.0 else 1.0
	_b_vel.text = "Velocidade %dx" % int(vel)
	_plateia.vel = vel
	for id in _lutadores:
		_lutadores[id].vel = vel

func _pular() -> void:
	if _fim_mostrado or _sobreposicao != null:
		return
	_fim_mostrado = true
	_encerrado = true
	var perda := 0
	if _ao_pular.is_valid():
		perda = int(_ao_pular.call())
	var d := _payload.duplicate()
	d["ouro"] = maxi(0, int(d.get("ouro", 0)) - perda)
	d["moedas"] = 0
	d["bonusPct"] = 0 if int(d["ouro"]) <= 0 else int(d.get("bonusPct", 0))
	_mostrar_resultado(d, perda)

func _confirmar_desistencia() -> void:
	if _fim_mostrado or _sobreposicao != null:
		return
	_pausado = true
	var sc := ColorRect.new()
	sc.color = Color(0, 0, 0, 0.7)
	sc.z_index = 3000
	sc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(sc)
	_sobreposicao = sc
	var cc := CenterContainer.new()
	cc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	sc.add_child(cc)
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", Tema.caixa(Color("1a1208"), Tema.OURO, 10, 2, 22))
	cc.add_child(p)
	var v := Tema.vbox(14)
	v.custom_minimum_size = Vector2(460, 0)
	p.add_child(v)
	var t := Tema.titulo("Desistir da luta?", 28)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(t)
	var m := Tema.rotulo("Conta como derrota, sem recompensa.\nA energia gasta não volta.", 19)
	m.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(m)
	var hb := Tema.hbox(12)
	hb.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(hb)
	var b1 := Tema.botao("Continuar lutando", "ouro")
	b1.custom_minimum_size = Vector2(200, 44)
	b1.pressed.connect(func() -> void:
		sc.queue_free()
		_sobreposicao = null
		_pausado = false)
	hb.add_child(b1)
	var b2 := Tema.botao("Desistir", "primario")
	b2.custom_minimum_size = Vector2(200, 44)
	b2.pressed.connect(func() -> void:
		sc.queue_free()
		_sobreposicao = null
		_pausado = false
		if _fim_mostrado:
			return
		_fim_mostrado = true
		_encerrado = true
		if _ao_desistir.is_valid():
			_ao_desistir.call()
		_fechar())
	hb.add_child(b2)

func _fechar() -> void:
	Som.musica("gestao")
	if _ao_fim.is_valid():
		_ao_fim.call()
	var camada := get_parent()
	queue_free()
	if camada is CanvasLayer:
		camada.queue_free()

# ---------- Reprodução ----------

func _esperar(t: float) -> void:
	var acc := 0.0
	while acc < t:
		await get_tree().process_frame
		if _encerrado:
			return
		if not _pausado:
			acc += get_process_delta_time() * vel

func _rodar() -> void:
	var eventos: Array = _payload.get("eventos", [])
	var principais := 0
	for ev in eventos:
		if ev["tipo"] != "carga":
			principais += 1
	var intervalo := clampf(20.0 / maxf(1.0, float(principais)), 0.42, 0.9)
	await _esperar(0.8)
	for ev in eventos:
		if _encerrado:
			return
		_mostrar(ev)
		match ev["tipo"]:
			"carga":
				pass
			"aplicado", "morte", "rendicao":
				await _esperar(intervalo * 0.7)
			_:
				await _esperar(intervalo)
	if _encerrado:
		return
	await _esperar(0.8)
	if _encerrado:
		return
	_terminar()

func _alvo_x(id: String) -> float:
	return _lutadores[id].base.x if _lutadores.has(id) else 640.0

func _mostrar(ev: Dictionary) -> void:
	var tipo: String = ev["tipo"]
	match tipo:
		"esquiva":
			_golpe(ev["ator"], ev["alvo"], "esquiva", false, "Esquiva", Color("e8d5b0"), 24, -1)
		"defesa":
			_golpe(ev["ator"], ev["alvo"], "defesa", false, "Bloqueado", Color("9bb7e0"), 24, -1)
		"acerto":
			var pes: bool = bool(ev.get("pesado", false))
			var crit: bool = bool(ev.get("critico", false))
			var txt := "−%d" % int(ev["dano"])
			if pes:
				txt = "PESADO −%d" % int(ev["dano"])
			elif crit:
				txt = "CRÍTICO −%d" % int(ev["dano"])
			var cor := Color("fff0a8") if pes else (Color("ff4a3a") if crit else Color("ff9a8a"))
			_golpe(ev["ator"], ev["alvo"], "acerto", crit or pes, txt, cor, 44 if (crit or pes) else 30, int(ev["hpRestante"]))
		"carga":
			_carga(ev["alvo"], int(ev["valor"]), int(ev["max"]))
		"aplicado":
			var nome: String = ev["nome"]
			_flutuar(_alvo_x(ev["alvo"]), "%s!" % NOME_EFEITO[nome], COR_EFEITO[nome].lightened(0.25), 26)
			_marcar_efeito(ev["alvo"], nome)
			if _lutadores.has(ev["alvo"]):
				_lutadores[ev["alvo"]].tingir(COR_EFEITO[nome])
		"efeito":
			var nome2: String = ev["nome"]
			_flutuar(_alvo_x(ev["alvo"]), "%s −%d" % [NOME_EFEITO[nome2], int(ev["dano"])], COR_EFEITO[nome2].lightened(0.3), 22)
			_definir_hp(ev["alvo"], int(ev["hpRestante"]))
			_tique_efeito(ev["alvo"], nome2)
			if _lutadores.has(ev["alvo"]):
				_lutadores[ev["alvo"]].tingir(COR_EFEITO[nome2])
		"atordoado":
			_flutuar(_alvo_x(ev["alvo"]), "Atordoado", Tema.OURO, 26)
			_remover_chip(ev["alvo"], "contusao")
		"rendicao":
			_flutuar(_alvo_x(ev["alvo"]), "Rende-se!", Tema.OURO, 30)
			if _lutadores.has(ev["alvo"]):
				_lutadores[ev["alvo"]].recolher()
			_apagar_ficha(ev["alvo"], " (rendeu-se)")
		"morte":
			_flutuar(_alvo_x(ev["alvo"]), "Morreu", Color("ff5555"), 34)
			if _lutadores.has(ev["alvo"]):
				_lutadores[ev["alvo"]].cair()
			_apagar_ficha(ev["alvo"], " (morto)")
			_tremer(6.0)

func _golpe(ator: String, alvo: String, resultado: String, forte: bool, texto: String, cor: Color, tam: int, hp: int) -> void:
	var atk: LutadorLuta = _lutadores.get(ator)
	var alv: LutadorLuta = _lutadores.get(alvo)
	if atk == null or alv == null:
		return
	var arma = _fichas[ator]["visual"]["aparencia"]["equipamento"].get("arma", null)
	var impacto := atk.golpear(atk.tipo_do_golpe(arma))
	if resultado == "esquiva":
		alv.esquivar(maxf(0.0, impacto - 90.0))
	var depois := func() -> void:
		if not is_instance_valid(self) or _encerrado:
			return
		_flutuar(alv.base.x, texto, cor, tam)
		match resultado:
			"acerto":
				alv.reagir(forte)
				_faiscas(alv, Color("ff5a4a") if forte else Color("ffd27a"), 16 if forte else 9)
				_tremer(12.0 if forte else 5.0)
				if forte:
					_clarao()
				_definir_hp(alvo, hp)
			"defesa":
				alv.defender(randf() < 0.3)
				_faiscas(alv, Color("cfe0ff"), 6)
	get_tree().create_timer(impacto / 1000.0 / vel).timeout.connect(depois)

func _carga(id: String, valor: int, maximo: int) -> void:
	if not _fichas.has(id):
		return
	var f: Dictionary = _fichas[id]
	var encheu := valor >= maximo and int(f["carga"]) < maximo
	f["carga"] = valor
	var b: Barra = f["barra"]
	b.carga_max = maximo
	b.carga = valor
	if encheu:
		get_tree().create_timer(0.38 / vel).timeout.connect(func() -> void:
			if is_instance_valid(self) and not _encerrado:
				_flutuar(_alvo_x(id), "Golpe pesado pronto!", Color("fff0a8"), 24))

func _definir_hp(id: String, hp: int) -> void:
	if not _fichas.has(id):
		return
	_fichas[id]["hp"] = hp
	var b: Barra = _fichas[id]["barra"]
	b.definir_hp(hp)

func _apagar_ficha(id: String, sufixo: String) -> void:
	if not _fichas.has(id):
		return
	var f: Dictionary = _fichas[id]
	(f["linha"] as Control).modulate = Color(0.62, 0.62, 0.62, 0.9)
	(f["nome_lbl"] as Label).text = str(f["visual"]["nome"]) + sufixo
	for t in f["chips"].keys():
		_remover_chip(id, t)

# ---------- Efeitos persistentes (marcadores) ----------

func _marcar_efeito(id: String, tipo: String) -> void:
	if not _fichas.has(id):
		return
	var f: Dictionary = _fichas[id]
	var dur: int = int(DURACAO_EFEITO[tipo])
	if dur > 0:
		f["efeitos"][tipo] = int(f["efeitos"].get(tipo, 0)) + dur
	else:
		f["efeitos"][tipo] = -1
	_atualizar_chip(id, tipo)

func _tique_efeito(id: String, tipo: String) -> void:
	if not _fichas.has(id):
		return
	var f: Dictionary = _fichas[id]
	if not f["efeitos"].has(tipo):
		return
	f["efeitos"][tipo] = int(f["efeitos"][tipo]) - 1
	if int(f["efeitos"][tipo]) <= 0:
		_remover_chip(id, tipo)
	else:
		_atualizar_chip(id, tipo)

func _atualizar_chip(id: String, tipo: String) -> void:
	var f: Dictionary = _fichas[id]
	var n: int = int(f["efeitos"][tipo])
	var txt: String = NOME_EFEITO[tipo] + ("" if n < 0 else " ×%d" % n)
	if f["chips"].has(tipo):
		(f["chips"][tipo] as Label).text = txt
		return
	var l := Tema.rotulo(txt, 14, Color.WHITE)
	l.autowrap_mode = TextServer.AUTOWRAP_OFF
	var cor: Color = COR_EFEITO[tipo]
	l.add_theme_stylebox_override("normal", Tema.caixa(cor.darkened(0.45), cor, 8, 1, 1))
	(f["chips_box"] as Control).add_child(l)
	f["chips"][tipo] = l

func _remover_chip(id: String, tipo: String) -> void:
	if not _fichas.has(id):
		return
	var f: Dictionary = _fichas[id]
	f["efeitos"].erase(tipo)
	if f["chips"].has(tipo):
		(f["chips"][tipo] as Control).queue_free()
		f["chips"].erase(tipo)

# ---------- Efeitos visuais ----------

func _flutuar(x: float, texto: String, cor: Color, tam: int = 24) -> void:
	var l := Label.new()
	l.text = texto
	l.add_theme_font_override("font", Tema.fonte_titulo)
	l.add_theme_font_size_override("font_size", tam)
	l.add_theme_color_override("font_color", cor)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.95))
	l.add_theme_constant_override("outline_size", maxi(4, tam / 5))
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.z_index = 1500
	_palco.add_child(l)
	l.reset_size()
	var y0 := 380.0 + randf_range(-14.0, 14.0)
	for id in _lutadores:
		var lt: LutadorLuta = _lutadores[id]
		if absf(lt.base.x - x) < 5.0:
			y0 = lt.topo() - 20.0 + randf_range(-10.0, 10.0)
			break
	var chave := int(x)
	var pilha: int = int(_pilha.get(chave, 0))
	_pilha[chave] = pilha + 1
	y0 -= 30.0 * pilha
	l.position = Vector2(x - l.size.x / 2.0 + randf_range(-16.0, 16.0), y0)
	l.pivot_offset = l.size / 2.0
	l.scale = Vector2(0.6, 0.6)
	var tw := create_tween()
	tw.set_speed_scale(vel)
	tw.set_parallel(true)
	tw.tween_property(l, "scale", Vector2.ONE, 0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(l, "position:y", y0 - 56.0, 1.0).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(l, "modulate:a", 0.0, 0.4).set_delay(0.65)
	tw.chain().tween_callback(func() -> void:
		_pilha[chave] = maxi(0, int(_pilha.get(chave, 1)) - 1)
		l.queue_free())

func _faiscas(alvo: LutadorLuta, cor: Color, n: int) -> void:
	var p := CPUParticles2D.new()
	p.position = Vector2(alvo.base.x - alvo.frente * 14.0, alvo.base.y - 120.0 * alvo.tamanho)
	p.z_index = 1400
	p.one_shot = true
	p.emitting = true
	p.amount = n
	p.lifetime = 0.45
	p.explosiveness = 1.0
	p.direction = Vector2(-alvo.frente, -0.4)
	p.spread = 70.0
	p.initial_velocity_min = 160.0
	p.initial_velocity_max = 380.0
	p.gravity = Vector2(0, 900)
	p.scale_amount_min = 3.0
	p.scale_amount_max = 6.0
	p.color = cor
	_palco.add_child(p)
	get_tree().create_timer(1.0).timeout.connect(p.queue_free)

func _tremer(forca: float) -> void:
	var tw := create_tween()
	for i in range(5):
		var f := forca * (1.0 - i / 5.0)
		tw.tween_property(_palco, "position", _palco_pos + Vector2(randf_range(-f, f), randf_range(-f, f)), 0.025)
	tw.tween_property(_palco, "position", _palco_pos, 0.03)

func _clarao() -> void:
	_flash.color = Color(1, 0.92, 0.8, 0.28)
	create_tween().tween_property(_flash, "color:a", 0.0, 0.25)

# ---------- Fim da luta ----------

func _terminar() -> void:
	if _fim_mostrado:
		return
	_fim_mostrado = true
	var venceu: bool = bool(_payload["vitoriaA"])
	for id in _lutadores:
		var f: Dictionary = _fichas[id]
		if (f["lado"] == "A") == venceu and not _lutadores[id].parado:
			_lutadores[id].comemorar()
	var moedas := int(_payload.get("moedas", 0))
	if moedas > 0:
		_chuva_de_moedas(moedas)
		await get_tree().create_timer(0.9 + moedas * 0.09 + 0.7).timeout
	else:
		await get_tree().create_timer(0.7).timeout
	if not is_instance_valid(self):
		return
	_mostrar_resultado(_payload, 0)

func _chuva_de_moedas(n: int) -> void:
	var origens: Array = _plateia.espectadores
	for i in range(n):
		var o: Vector2 = Vector2(640, 260)
		if origens.size() > 0:
			var s: Dictionary = origens[randi() % origens.size()]
			o = Vector2(float(s["x"]), float(s["y"]) - 20.0)
		var m := Moeda.new()
		m.position = o
		m.modulate.a = 0.0
		m.z_index = 1300
		_palco.add_child(m)
		var alvo := Vector2(randf_range(380.0, 900.0), randf_range(Y_PES - 50.0, Y_PES + 60.0))
		var tw := create_tween()
		tw.set_parallel(true)
		var atraso := i * 0.09
		tw.tween_property(m, "modulate:a", 1.0, 0.08).set_delay(atraso)
		tw.tween_property(m, "position:x", alvo.x, 0.9).set_delay(atraso).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tw.tween_property(m, "position:y", alvo.y, 1.0).set_delay(atraso).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
		tw.tween_property(m, "rotation", TAU * randi_range(1, 3), 0.9).set_delay(atraso)
		if i < 12:
			get_tree().create_timer(atraso + 0.5).timeout.connect(func() -> void: Som.sfx("sfx/moeda", 0.8))

func _mostrar_resultado(d: Dictionary, perda: int) -> void:
	_b_pular.disabled = true
	_b_desistir.disabled = true
	_b_vel.disabled = true
	var venceu: bool = bool(d["vitoriaA"])
	var sc := ColorRect.new()
	sc.color = Color(0, 0, 0, 0.0)
	sc.z_index = 3000
	sc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(sc)
	create_tween().tween_property(sc, "color:a", 0.74, 0.35)
	var cc := CenterContainer.new()
	cc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	sc.add_child(cc)
	var cor_borda := Tema.OURO if venceu else Tema.SANGUE_CLARO
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", Tema.caixa(Color("1a1208"), cor_borda, 12, 3, 24))
	cc.add_child(p)
	var v := Tema.vbox(10)
	v.custom_minimum_size = Vector2(620, 0)
	p.add_child(v)
	var t := Tema.titulo(str(d.get("titulo", "")), 24)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(t)
	var r := Tema.rotulo("VITÓRIA" if venceu else "DERROTA", 56, Color("9be05a") if venceu else Color("d88a6a"), true)
	r.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	r.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	r.add_theme_constant_override("outline_size", 6)
	v.add_child(r)
	var res := Tema.rotulo(str(d.get("resumo", "")), 20)
	res.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(res)
	v.add_child(HSeparator.new())
	var ouro := int(d.get("ouro", 0))
	if venceu and ouro > 0:
		var txt := "+%d ouro" % ouro
		if int(d.get("bonusPct", 0)) > 0:
			txt += "  (bônus da plateia: +%d%%)" % int(d["bonusPct"])
		var lo := Tema.rotulo(txt, 26, Tema.OURO, true)
		lo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(lo)
	if perda > 0:
		var lp := Tema.rotulo("Luta pulada: −%d de ouro na recompensa (10%%)." % perda, 18, Tema.CINZA)
		lp.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(lp)
	if int(d.get("moedas", 0)) > 0:
		var lm := Tema.rotulo("A plateia lançou %d moedas na areia." % int(d["moedas"]), 18, Tema.OURO_ESCURO)
		lm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(lm)
	var efs: Array = d.get("efeitosNovos", [])
	var le := Tema.rotulo(("Efeitos: " + " · ".join(efs)) if efs.size() > 0 else "Sem efeitos persistentes.", 18, Color("c79cff") if efs.size() > 0 else Tema.CINZA)
	le.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(le)
	for m in d.get("marcos", []):
		var lm2 := Tema.rotulo(str(m), 19, Tema.OURO)
		lm2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(lm2)
	v.add_child(Tema.espaco(6))
	var b := Tema.botao("Continuar", "primario", 22)
	b.custom_minimum_size = Vector2(220, 50)
	b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	b.pressed.connect(_fechar)
	v.add_child(b)
	cc.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(cc, "modulate:a", 1.0, 0.35)
	await get_tree().process_frame
	if is_instance_valid(p):
		p.pivot_offset = p.size / 2.0
		p.scale = Vector2(0.92, 0.92)
		create_tween().tween_property(p, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

# ---------- Peças ----------

## Barra de vida (com rastro do dano) e barra do golpe pesado, desenhadas à mão.
class Barra extends Control:
	var espelhado := false
	var alt_hp := 22.0
	var hp_max := 1
	var hp_atual := 1
	var carga := 0:
		set(v):
			carga = v
			queue_redraw()
	var carga_max := 4
	var frac := 1.0:
		set(v):
			frac = v
			queue_redraw()
	var trilha := 1.0:
		set(v):
			trilha = v
			queue_redraw()
	var _lbl: Label
	var _pulso := 0.0

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _ready() -> void:
		custom_minimum_size = Vector2(120, alt_hp + 12.0)
		_lbl = Label.new()
		_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_lbl.add_theme_font_size_override("font_size", 15)
		_lbl.add_theme_color_override("font_outline_color", Color.BLACK)
		_lbl.add_theme_constant_override("outline_size", 4)
		_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_lbl)
		_texto()
		resized.connect(func() -> void:
			_lbl.position = Vector2.ZERO
			_lbl.size = Vector2(size.x, alt_hp))
		_lbl.size = Vector2(size.x, alt_hp)

	func _texto() -> void:
		if _lbl:
			_lbl.text = "%d / %d" % [maxi(0, hp_atual), hp_max]

	func definir_hp(hp: int) -> void:
		hp_atual = hp
		_texto()
		var alvo := clampf(float(hp) / float(maxi(1, hp_max)), 0.0, 1.0)
		var tw := create_tween()
		tw.tween_property(self, "frac", alvo, 0.18).set_trans(Tween.TRANS_SINE)
		tw.tween_interval(0.25)
		tw.tween_property(self, "trilha", alvo, 0.45).set_trans(Tween.TRANS_SINE)

	func _process(delta: float) -> void:
		if carga >= carga_max:
			_pulso += delta * 6.0
			queue_redraw()

	func _preencher(y: float, h: float, f: float, cor: Color) -> void:
		var w := size.x * clampf(f, 0.0, 1.0)
		if w <= 0.0:
			return
		var x := size.x - w if espelhado else 0.0
		draw_rect(Rect2(x, y, w, h), cor)

	func _draw() -> void:
		var w := size.x
		draw_rect(Rect2(0, 0, w, alt_hp), Color(0, 0, 0, 0.7))
		_preencher(0, alt_hp, trilha, Color("f0e6c8", 0.85))
		var cor := Color("6fae4a") if frac > 0.5 else (Color("d9a62e") if frac > 0.25 else Color("c0392b"))
		_preencher(0, alt_hp, frac, cor)
		_preencher(0, alt_hp * 0.4, frac, cor.lightened(0.28))
		draw_rect(Rect2(0, 0, w, alt_hp), Tema.OURO_ESCURO, false, 1.5)
		# barra do golpe pesado
		var y := alt_hp + 3.0
		var h := 8.0
		draw_rect(Rect2(0, y, w, h), Color(0, 0, 0, 0.7))
		var cheia := carga >= carga_max
		var cc := Color("fff0a8") if cheia else Color("e6cf8a")
		if cheia:
			cc = cc.lerp(Color("ffffff"), 0.35 + 0.35 * sin(_pulso))
		_preencher(y, h, float(carga) / float(maxi(1, carga_max)), cc)
		for i in range(1, carga_max):
			var x := w * i / float(carga_max)
			draw_rect(Rect2(x - 1.0, y, 2.0, h), Color(0, 0, 0, 0.75))
		draw_rect(Rect2(0, y, w, h), Color("8a6a2a") if not cheia else Color("fff0a8"), false, 1.0)

## Moeda dourada que a plateia joga na areia.
class Moeda extends Node2D:
	func _draw() -> void:
		draw_circle(Vector2.ZERO, 11.0, Color("7a5a14"))
		draw_circle(Vector2.ZERO, 9.0, Color("e6b93a"))
		draw_circle(Vector2(-2, -2), 5.0, Color("ffe27a"))
		draw_arc(Vector2.ZERO, 6.0, 0.4, 2.2, 8, Color("b8861e"), 1.5)
