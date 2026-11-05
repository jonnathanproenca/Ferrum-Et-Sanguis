class_name TelaCampanha
extends Tela
## Aba "campanha": trilha dos 10 passos, salão dos lanistas, duelo do passo atual, escalação e tela final.

const FUNDO := "assets/lanistas/fundo.jpg"
const FUNDO_W := 1376.0
const FUNDO_H := 768.0
const VIDEO := "res://assets/video/entrada-espartaco.ogv"
## Tamanho (px) dos sprites dos lanistas no arquivo original.
const SPRITES_LANISTA := {
	"lanista-1": Vector2(134, 283), "lanista-2": Vector2(120, 286), "lanista-3": Vector2(145, 289), "lanista-4": Vector2(122, 283),
	"lanista-5": Vector2(151, 286), "lanista-6": Vector2(134, 288), "lanista-7": Vector2(158, 273), "lanista-8": Vector2(145, 282),
	"lanista-9": Vector2(158, 294), "lanista-10": Vector2(137, 290), "batiatus": Vector2(133, 282), "espartaco": Vector2(186, 292),
}
const COR_FUTURO := Color(0.0, 0.0, 0.0, 0.72)
const VERMELHO_VIVO := Color("d6452f")

var _raiz: VBoxContainer
var _video_visto := false
var _camada_video: CanvasLayer

func construir() -> void:
	_raiz = rolagem(12)

func ao_mostrar() -> void:
	Som.musica("campanha")
	super.ao_mostrar()

func atualizar() -> void:
	Tema.limpar(_raiz)
	if Game.proximo_desafio(Jogo.e).is_empty():
		_final()
	else:
		_desafio()

# ---------- Utilidades ----------

static func tempo_jogado(ms: int) -> String:
	var minutos: int = ms / 60000
	var h: int = minutos / 60
	return "%d h %02d min" % [h, minutos % 60] if h > 0 else "%d min" % maxi(1, minutos)

static func milhar(n: int) -> String:
	var s := str(absi(n))
	var out := ""
	while s.length() > 3:
		out = "." + s.substr(s.length() - 3) + out
		s = s.substr(0, s.length() - 3)
	return ("-" if n < 0 else "") + s + out

func _tex_rect(tex: Texture2D, flip := false, modular := Color.WHITE) -> TextureRect:
	var tr := TextureRect.new()
	tr.texture = tex
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tr.flip_h = flip
	tr.modulate = modular
	return tr

func _sprite_gladiador(g: Dictionary, altura: float, flip: bool) -> TextureRect:
	var tr := Sprites.controle_gladiador(g, altura)
	tr.flip_h = flip
	return tr

# ---------- Passo atual ----------

func _desafio() -> void:
	var e: Dictionary = Jogo.e
	var d: Dictionary = Game.proximo_desafio(e)
	var passos: Array = Game.passos()
	var indice: int = d["indice"]
	var passo: Dictionary = d["passo"]
	var formato: int = int(passo.get("formato", 1))
	var final: bool = indice == d["sequencia"].size() - 1
	var misterio: bool = final and not d["pronto"]

	# Cabeça + trilha
	var cab := Tema.vbox(2)
	cab.alignment = BoxContainer.ALIGNMENT_CENTER
	_raiz.add_child(cab)
	var small := Tema.rotulo("PASSO %d DE %d" % [indice + 1, passos.size()], 14, Tema.OURO_ESCURO)
	small.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cab.add_child(small)
	var t := Tema.titulo(str(passo["titulo"]), 34)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.add_theme_color_override("font_shadow_color", Color(0.54, 0.11, 0.11, 0.9))
	t.add_theme_constant_override("shadow_offset_y", 2)
	t.add_theme_constant_override("shadow_outline_size", 10)
	cab.add_child(t)
	cab.add_child(_trilha(indice, passos))

	# Palco + duelo (lado a lado; empilha em telas estreitas)
	var corpo := BoxContainer.new()
	corpo.add_theme_constant_override("separation", 16)
	_raiz.add_child(corpo)
	var palco := _palco(d, final, misterio)
	palco.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	palco.size_flags_stretch_ratio = 1.55
	palco.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	corpo.add_child(palco)
	var duelo := _duelo(d, final, misterio, formato)
	duelo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	duelo.size_flags_stretch_ratio = 1.0
	duelo.custom_minimum_size.x = 400
	corpo.add_child(duelo)
	corpo.resized.connect(func(): corpo.vertical = corpo.size.x < 940)

	# Escalação
	var esc := Tema.painel(Tema.PAINEL, Tema.BORDA)
	_raiz.add_child(esc)
	var ev := Tema.vbox(8)
	esc.add_child(ev)
	ev.add_child(Tema.rotulo("Escalação (%d contra %d)" % [formato, formato], 22, Tema.OURO, true))
	var painel := PainelEscalacao.new()
	painel.formato = formato
	painel.mudou_equipe.connect(atualizar)
	ev.add_child(painel)

func _trilha(indice: int, passos: Array) -> Control:
	var h := Tema.hbox(0)
	h.alignment = BoxContainer.ALIGNMENT_CENTER
	for i in range(passos.size()):
		if i > 0:
			var linha := ColorRect.new()
			linha.custom_minimum_size = Vector2(26, 2)
			linha.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			linha.color = Tema.OURO_ESCURO if i <= indice else Color("3a2a20")
			h.add_child(linha)
		var feito := i < indice
		var atual := i == indice
		var pc := PanelContainer.new()
		pc.custom_minimum_size = Vector2(30, 30)
		pc.tooltip_text = str(passos[i]["titulo"])
		var cor := Tema.OURO_ESCURO if feito else (Tema.SANGUE if atual else Color("140d0a"))
		var borda := Tema.OURO_ESCURO if feito else (VERMELHO_VIVO if atual else Color("3a2a20"))
		var sb := Tema.caixa(cor, borda, 15, 2, 0)
		if atual:
			sb.shadow_color = Color(VERMELHO_VIVO, 0.7)
			sb.shadow_size = 8
		pc.add_theme_stylebox_override("panel", sb)
		var l := Tema.rotulo("v" if feito else str(i + 1), 15, Color("1a0f08") if feito else (Color.WHITE if atual else Color("7a6650")))
		l.autowrap_mode = TextServer.AUTOWRAP_OFF
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		pc.add_child(l)
		h.add_child(pc)
		if atual:
			var tw := pc.create_tween().set_loops()
			tw.tween_property(pc, "modulate", Color(1.35, 1.1, 1.0), 0.8)
			tw.tween_property(pc, "modulate", Color.WHITE, 0.8)
	return h

# ---------- Palco ----------

func _palco(d: Dictionary, final: bool, misterio: bool) -> Control:
	var seq: Array = d["sequencia"]
	var indice: int = d["indice"]
	var lanista: Dictionary = d["lanista"]
	var moldura := PanelContainer.new()
	moldura.add_theme_stylebox_override("panel", Tema.caixa(Color.BLACK, Tema.OURO_ESCURO, 8, 2, 0))
	moldura.clip_contents = true
	var palco := Control.new()
	palco.clip_contents = true
	palco.custom_minimum_size = Vector2(300, 300 * FUNDO_H / FUNDO_W)
	moldura.add_child(palco)
	palco.resized.connect(func():
		var alvo: float = palco.size.x * FUNDO_H / FUNDO_W
		if absf(palco.custom_minimum_size.y - alvo) > 0.5:
			palco.custom_minimum_size.y = alvo)
	var fundo := _tex_rect(Tema.textura(FUNDO))
	fundo.stretch_mode = TextureRect.STRETCH_SCALE
	fundo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	palco.add_child(fundo)
	var sombra := ColorRect.new()
	sombra.color = Color(0, 0, 0, 0.18)
	sombra.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	sombra.mouse_filter = Control.MOUSE_FILTER_IGNORE
	palco.add_child(sombra)

	var lineup: Array = [lanista] if final else seq.slice(0, seq.size() - 1)
	var n: int = lineup.size()
	var aspecto := FUNDO_W / FUNDO_H
	var ordem: Array = range(n)
	# o ativo por último (desenhado por cima); futuros mais distantes embaixo
	ordem.sort_custom(func(a, b): return absi(a - indice) > absi(b - indice))
	for i in ordem:
		var l: Dictionary = lineup[i]
		var sz: Vector2 = SPRITES_LANISTA[l["id"]]
		var escala := 1.7 if final else 0.98
		var wf: float = sz.x * escala / FUNDO_W
		var cx: float = 0.5 if final else 0.08 + (0.84 / float(maxi(1, n - 1))) * i
		var estado := "futuro" if misterio else ("ativo" if final else ("vencido" if i < indice else ("ativo" if i == indice else "futuro")))
		var hf: float = wf * aspecto * sz.y / sz.x
		var base := 0.88 - (0.03 if estado == "ativo" else 0.0)
		var wf2 := wf * (1.06 if estado == "ativo" else 1.0)
		var hf2 := hf * (1.06 if estado == "ativo" else 1.0)
		var fig := Control.new()
		fig.mouse_filter = Control.MOUSE_FILTER_IGNORE
		fig.anchor_left = cx - wf2 / 2.0
		fig.anchor_right = cx + wf2 / 2.0
		fig.anchor_bottom = base
		fig.anchor_top = base - hf2
		palco.add_child(fig)
		# sombra no chão
		var chao := Panel.new()
		var csb := StyleBoxFlat.new()
		csb.bg_color = Color(0, 0, 0, 0.45)
		csb.set_corner_radius_all(40)
		csb.shadow_color = Color(0, 0, 0, 0.35)
		csb.shadow_size = 8
		chao.add_theme_stylebox_override("panel", csb)
		chao.mouse_filter = Control.MOUSE_FILTER_IGNORE
		chao.anchor_left = 0.05
		chao.anchor_right = 0.95
		chao.anchor_top = 0.93
		chao.anchor_bottom = 1.04
		fig.add_child(chao)
		var cor := Color.WHITE
		match estado:
			"vencido":
				cor = Color(0.38, 0.38, 0.38)
			"futuro":
				cor = COR_FUTURO
		var tr := _tex_rect(Tema.textura(SpriteLanista.caminho(l["id"])), false, cor)
		tr.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		fig.add_child(tr)
		if estado == "ativo" and l["id"] != "batiatus":
			var tw := fig.create_tween().set_loops()
			tw.tween_property(tr, "position:y", -3.0, 1.1).set_trans(Tween.TRANS_SINE)
			tw.tween_property(tr, "position:y", 2.0, 1.1).set_trans(Tween.TRANS_SINE)
		if estado == "vencido":
			var x := Tema.rotulo("X", 30, VERMELHO_VIVO)
			x.autowrap_mode = TextServer.AUTOWRAP_OFF
			x.add_theme_color_override("font_outline_color", Color.BLACK)
			x.add_theme_constant_override("outline_size", 6)
			x.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
			x.grow_horizontal = Control.GROW_DIRECTION_BOTH
			x.grow_vertical = Control.GROW_DIRECTION_BOTH
			fig.add_child(x)
		if not final:
			var num := PanelContainer.new()
			var nsb := Tema.caixa(Color(0.06, 0.035, 0.024, 0.9), Tema.OURO_ESCURO if estado != "futuro" else Color("5a4630"), 3, 1, 1)
			nsb.content_margin_left = 6
			nsb.content_margin_right = 6
			num.add_theme_stylebox_override("panel", nsb)
			var nl := Tema.rotulo(str(i + 1), 14, Tema.AREIA if estado != "futuro" else Tema.CINZA)
			nl.autowrap_mode = TextServer.AUTOWRAP_OFF
			num.add_child(nl)
			num.mouse_filter = Control.MOUSE_FILTER_IGNORE
			num.anchor_left = 0.5
			num.anchor_right = 0.5
			num.anchor_top = 1.0
			num.anchor_bottom = 1.0
			num.offset_top = 6
			num.grow_horizontal = Control.GROW_DIRECTION_BOTH
			fig.add_child(num)

	# Placa de título no topo
	var info := PanelContainer.new()
	var isb := Tema.caixa(Color(0.06, 0.035, 0.024, 0.78), Tema.OURO_ESCURO, 4, 1, 4)
	info.add_theme_stylebox_override("panel", isb)
	info.mouse_filter = Control.MOUSE_FILTER_IGNORE
	info.anchor_left = 0.5
	info.anchor_right = 0.5
	info.offset_top = 10
	info.grow_horizontal = Control.GROW_DIRECTION_BOTH
	var iv := Tema.vbox(0)
	iv.mouse_filter = Control.MOUSE_FILTER_IGNORE
	info.add_child(iv)
	var titulo_txt := "Um último desafio" if misterio else str(lanista["nome"])
	var sub: String
	if misterio:
		sub = "Cumpra os requisitos para revelar o lanista de Cápua."
	elif final:
		sub = "Seu gladiador: %s" % Jogo.e["campeoesRivais"][lanista["id"]]["nome"]
	else:
		sub = str(lanista.get("titulo", "Escola de %s" % Model.classes()[lanista["especialidade"]]["nome"]))
	var lt := Tema.rotulo(titulo_txt, 24, Tema.OURO, true)
	lt.autowrap_mode = TextServer.AUTOWRAP_OFF
	lt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var ls := Tema.rotulo(sub, 16, Tema.AREIA)
	ls.autowrap_mode = TextServer.AUTOWRAP_OFF
	ls.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	iv.add_child(lt)
	iv.add_child(ls)
	palco.add_child(info)
	return moldura

# ---------- Duelo ----------

func _duelo(d: Dictionary, final: bool, misterio: bool, formato: int) -> Control:
	var e: Dictionary = Jogo.e
	var passo: Dictionary = d["passo"]
	var lanista: Dictionary = d["lanista"]
	var regra: Dictionary = passo["regra"]
	var letal: bool = regra.get("letal", false)
	var rival: Dictionary = e["campeoesRivais"][lanista["id"]]
	var sel: Array = Jogo.equipe_valida()

	var p := PanelContainer.new()
	var sb := Tema.caixa(Color("2a1812"), VERMELHO_VIVO if letal else Tema.OURO_ESCURO, 8, 2, 12)
	if letal:
		sb.shadow_color = Color(VERMELHO_VIVO, 0.5)
		sb.shadow_size = 14
	p.add_theme_stylebox_override("panel", sb)
	var v := Tema.vbox(8)
	p.add_child(v)

	# lados
	var lados := HBoxContainer.new()
	lados.add_theme_constant_override("separation", 8)
	lados.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(lados)
	var lr := Tema.vbox(2)
	lr.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lr.alignment = BoxContainer.ALIGNMENT_END
	lados.add_child(lr)
	var figs_r := Tema.hbox(6)
	figs_r.alignment = BoxContainer.ALIGNMENT_CENTER
	lr.add_child(figs_r)
	if misterio:
		var sil := _tex_rect(Sprites.pose("dimachaerus", "guarda"), true, COR_FUTURO)
		sil.custom_minimum_size = Vector2(110, 140)
		sil.tooltip_text = "Gladiador desconhecido"
		figs_r.add_child(sil)
	else:
		figs_r.add_child(_lutador(rival, str(rival["nome"]) if final else str(lanista["nome"]), false))
	if final and not misterio:
		lr.add_child(_pequeno("campeão de %s" % lanista["nome"]))
	if formato > 1:
		lr.add_child(_pequeno("e um companheiro"))
	var vs := Tema.vbox(0)
	vs.alignment = BoxContainer.ALIGNMENT_CENTER
	var vl := Tema.rotulo("VS", 46, VERMELHO_VIVO, true)
	vl.autowrap_mode = TextServer.AUTOWRAP_OFF
	vl.add_theme_color_override("font_outline_color", Color.BLACK)
	vl.add_theme_constant_override("outline_size", 8)
	vs.add_child(vl)
	var fl := Tema.rotulo("%d×%d" % [formato, formato], 16, Tema.OURO_ESCURO)
	fl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vs.add_child(fl)
	lados.add_child(vs)
	var lt := Tema.hbox(6)
	lt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lt.alignment = BoxContainer.ALIGNMENT_CENTER
	if sel.is_empty():
		var pq := _pequeno("Escale seu time abaixo.")
		pq.autowrap_mode = TextServer.AUTOWRAP_OFF
		lt.add_child(pq)
	for g in sel:
		lt.add_child(_lutador(g, str(g["nome"]), true))
	lados.add_child(lt)

	v.add_child(HSeparator.new())

	# regra
	var rg := Tema.vbox(2)
	if misterio:
		var a := Tema.rotulo("Regra oculta", 20, Tema.OURO)
		a.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		var b := Tema.rotulo("Revelada quando você cumprir os requisitos.", 17, Tema.AREIA)
		b.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		rg.add_child(a)
		rg.add_child(b)
	else:
		var a := Tema.rotulo(str(regra["nome"]), 20, Tema.OURO)
		a.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		var b := Tema.rotulo(str(regra["descricao"]), 17, Tema.AREIA)
		b.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		rg.add_child(a)
		rg.add_child(b)
	v.add_child(rg)
	var morte := Tema.rotulo("☠ Até a morte: nesta luta ninguém se rende.", 17, Color("ff8a72"))
	morte.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(morte)

	# requisitos
	var rq := Tema.vbox(2)
	for r in d["requisitos"]:
		var ok: bool = r["ok"]
		rq.add_child(Tema.rotulo("%s %s" % ["+" if ok else "-", r["texto"]], 18, Tema.VERDE if ok else Color("d98a6a")))
	v.add_child(rq)

	var pronto: bool = d["pronto"] and sel.size() == formato and int(e["energia"]) >= formato
	var status := ""
	if sel.size() != formato:
		status = "Escale %d gladiador%s." % [formato, "es" if formato > 1 else ""]
	elif int(e["energia"]) < formato:
		status = "Energia insuficiente (precisa de %d)." % formato
	if status != "":
		var s := Tema.rotulo(status, 17, Color("e0b060"))
		s.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(s)
	var btn := Tema.botao("ENTRAR NA ARENA", "primario", 22)
	btn.custom_minimum_size = Vector2(0, 52)
	btn.disabled = not pronto
	btn.pressed.connect(_entrar)
	v.add_child(btn)
	return p

func _pequeno(txt: String) -> Label:
	var l := Tema.rotulo(txt, 15, Tema.CINZA)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return l

func _lutador(g: Dictionary, nome: String, espelhar: bool) -> Control:
	var v := Tema.vbox(2)
	v.custom_minimum_size.x = 96
	v.alignment = BoxContainer.ALIGNMENT_END
	var sp := _sprite_gladiador(g, 140, espelhar)
	v.add_child(sp)
	var l := Tema.rotulo(nome, 16, Tema.AREIA)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(l)
	return v

# ---------- Luta ----------

func _entrar() -> void:
	var d: Dictionary = Game.proximo_desafio(Jogo.e)
	if d.is_empty():
		return
	if d["lanista"]["id"] == "batiatus" and not _video_visto:
		_video_visto = true
		_tocar_video(_entrar)
		return
	_video_visto = false
	var ids: Array = Jogo.equipe_valida().map(func(g): return g["id"])
	var antes: Dictionary = Jogo.e.duplicate(true)
	var payload: Dictionary = Game.lutar_campanha(Jogo.e, ids)
	if payload.has("erro"):
		Jogo.aviso.emit(str(payload["erro"]))
		return
	Jogo.salvar()
	Jogo.mudou.emit()
	var ao_desistir := func():
		Jogo.e = Game.desistir_da_luta(antes, Jogo.e, ids)
		Jogo.salvar()
	var ao_pular := func() -> int:
		var perda: int = Game.pular_luta(Jogo.e, payload)
		Jogo.salvar()
		return perda
	Jogo.iniciar_luta.emit(payload, func(): Jogo.mudou.emit(), ao_desistir, ao_pular)

# ---------- Vídeo de entrada do Espártaco ----------

func _tocar_video(depois: Callable) -> void:
	if _camada_video != null:
		return
	if not ResourceLoader.exists(VIDEO):
		depois.call()
		return
	var som_ativo: bool = Jogo.prefs["audio"]["ativo"]
	Som.parar_musica()
	_camada_video = CanvasLayer.new()
	_camada_video.layer = 100
	var fundo := ColorRect.new()
	fundo.color = Color(0, 0, 0, 0)
	fundo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_camada_video.add_child(fundo)
	var vp := VideoStreamPlayer.new()
	vp.stream = load(VIDEO)
	vp.expand = true
	vp.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vp.volume_db = linear_to_db(maxf(0.001, float(Jogo.prefs["audio"]["efeitos"]) + 0.3)) if som_ativo else -80.0
	vp.modulate.a = 0.0
	fundo.add_child(vp)
	var pular := Tema.botao("Pular", "normal", 20)
	pular.theme = Tema.tema()
	pular.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	pular.offset_left = -130
	pular.offset_right = -20
	pular.offset_top = 20
	pular.offset_bottom = 64
	fundo.add_child(pular)
	var terminou := [false]
	var encerrar := func():
		if terminou[0]:
			return
		terminou[0] = true
		if is_instance_valid(vp):
			vp.stop()
		if is_instance_valid(_camada_video):
			_camada_video.queue_free()
		_camada_video = null
		Som.musica("campanha")
		depois.call()
	vp.finished.connect(encerrar)
	pular.pressed.connect(encerrar)
	get_tree().root.add_child(_camada_video)
	# transição suave: escurece a tela, depois o vídeo surge
	var tw_in := _camada_video.create_tween()
	tw_in.tween_property(fundo, "color:a", 1.0, 0.7)
	tw_in.tween_callback(func():
		if is_instance_valid(vp) and not terminou[0]:
			vp.play())
	tw_in.tween_property(vp, "modulate:a", 1.0, 0.8)

# ---------- Tela final ----------

func _final() -> void:
	var e: Dictionary = Jogo.e
	var st: Dictionary = Game.estatisticas(e)
	var lutas: int = Game.batalhas_do_ludus(e)
	var casa: Dictionary = Game.lanista_da_casa(e)
	var vit: int = int(e["vitoriasTotais"])
	var dados: Array = [
		["Tempo de jogo", tempo_jogado(int(st["tempoMs"]))],
		["Ouro acumulado", "%s ouro" % milhar(int(st["ouroGanho"]))],
		["Lutas", str(lutas)],
		["Vitórias", str(vit)],
		["Derrotas", str(maxi(0, lutas - vit))],
		["Rodadas", str(int(e["turno"]))],
		["Gladiadores recrutados", str(int(st["recrutados"]))],
		["Gladiadores mortos", str(int(st["mortes"]))],
		["Libertos", str(e["libertados"].size())],
		["Dificuldade", str(Game.regras_de(e)["nome"])],
	]
	var centro := CenterContainer.new()
	centro.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_raiz.add_child(centro)
	var p := PanelContainer.new()
	var sb := Tema.caixa(Color("170d09"), Tema.OURO_ESCURO, 10, 2, 24)
	sb.shadow_color = Color(Tema.OURO_ESCURO, 0.25)
	sb.shadow_size = 18
	p.add_theme_stylebox_override("panel", sb)
	p.custom_minimum_size.x = clampf(size.x - 60.0, 320.0, 980.0)
	centro.add_child(p)
	var v := Tema.vbox(10)
	p.add_child(v)
	var s := Tema.rotulo("FIM DA CAMPANHA", 16, Tema.OURO_ESCURO)
	s.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(s)
	var h2 := Tema.rotulo("Roma se curva ao %s" % casa["nome"], 40, Tema.OURO, true)
	h2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	h2.add_theme_color_override("font_shadow_color", Color(0.54, 0.11, 0.11, 0.9))
	h2.add_theme_constant_override("shadow_outline_size", 4)
	v.add_child(h2)
	var tx := Tema.rotulo("Você derrotou todos os lanistas, de Pompeia até Lêntulo Batiatus e seu campeão Espártaco.", 20)
	tx.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(tx)

	var gr := GridContainer.new()
	gr.columns = 5
	gr.add_theme_constant_override("h_separation", 8)
	gr.add_theme_constant_override("v_separation", 8)
	gr.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(gr)
	for k in dados:
		var c := PanelContainer.new()
		c.custom_minimum_size.x = 170
		c.add_theme_stylebox_override("panel", Tema.caixa(Color("22140d"), Color("5a3a20"), 4, 1, 8))
		var cv := Tema.vbox(0)
		var a := Tema.rotulo(str(k[0]), 14, Tema.OURO_ESCURO)
		a.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		var b := Tema.rotulo(str(k[1]), 22, Color("f2e6c8"))
		b.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cv.add_child(a)
		cv.add_child(b)
		c.add_child(cv)
		gr.add_child(c)

	if not e["gladiadores"].is_empty():
		var h3 := Tema.rotulo("Seu ludus", 24, Tema.OURO, true)
		h3.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(h3)
		var elenco: Array = e["gladiadores"].duplicate()
		elenco.sort_custom(func(a, b): return int(a["vitorias"]) > int(b["vitorias"]))
		var lista := Tema.vbox(2)
		for g in elenco:
			var cls: String = "sem estilo" if g.get("semEstilo", false) else str(Model.classes()[g["classe"]]["nome"])
			var vt: int = int(g["vitorias"])
			var extra := " · lenda" if g.get("lenda", false) else (" · campeão" if g.get("campeao", false) else "")
			var linha := Tema.hbox(10)
			if not g.get("semEstilo", false):
				var mini_sp := _sprite_gladiador(g, 56, false)
				if not g["vivo"]:
					mini_sp.modulate = Color(0.5, 0.5, 0.5)
				linha.add_child(mini_sp)
			var l := Tema.rotulo("%s · %s · nível %d · %d vitória%s%s%s" % [g["nome"], cls, int(g["nivel"]), vt, "" if vt == 1 else "s", extra, "" if g["vivo"] else " · morto"], 18)
			l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			linha.add_child(l)
			lista.add_child(linha)
		v.add_child(lista)
	var nova := Tema.botao("Nova campanha", "primario", 22)
	nova.custom_minimum_size = Vector2(260, 52)
	nova.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	nova.pressed.connect(func():
		Jogo.apagar_save()
		Jogo.navegar.emit("selecao"))
	v.add_child(nova)

## Caminhos dos sprites dos lanistas (arquivos em assets/lanistas/).
class SpriteLanista:
	static func caminho(id: String) -> String:
		return "assets/lanistas/%s.png" % id
