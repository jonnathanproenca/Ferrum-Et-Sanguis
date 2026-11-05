class_name TelaArenas
extends Tela
## Aba "arenas": escalação de 1 ou 2 gladiadores e cartões das arenas (Pompeia, Cápua, Coliseu e Poço) com o botão "Lutar".
## A luta é aberta por `Jogo.iniciar_luta` (o Hud liga o sinal a `TelaLuta.abrir`); sem ninguém ligado, abre a TelaLuta direto.

const LARGURA_MIN := 290.0
const ESPACO := 14.0

var _painel: PainelEscalacao
var _info: Label
var _grade: GridContainer
var _cartoes: Array = []

func construir() -> void:
	var v := rolagem(10)
	var topo := Tema.hbox(14)
	v.add_child(topo)
	topo.add_child(Tema.titulo("Arenas", 30))
	_info = Tema.rotulo("", 18, Tema.CINZA)
	_info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_info.autowrap_mode = TextServer.AUTOWRAP_OFF
	topo.add_child(_info)
	var moldura := Tema.painel(Color("1a110d"), Tema.BORDA)
	v.add_child(moldura)
	_painel = PainelEscalacao.new()
	_painel.formato = 0
	_painel.titulo = "Escalação para a arena"
	_painel.mudou_equipe.connect(atualizar)
	moldura.add_child(_painel)
	_grade = GridContainer.new()
	_grade.columns = 4
	_grade.add_theme_constant_override("h_separation", int(ESPACO))
	_grade.add_theme_constant_override("v_separation", int(ESPACO))
	_grade.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_child(_grade)
	_grade.resized.connect(_ajustar_larguras)

func _ajustar_larguras() -> void:
	var w := _grade.size.x
	if w <= 0.0 or _cartoes.is_empty():
		return
	var cols := clampi(int(floor((w + ESPACO) / (LARGURA_MIN + ESPACO))), 1, 4)
	_grade.columns = cols
	var cw := floorf((w - (cols - 1) * ESPACO) / cols)
	for c in _cartoes:
		(c as Control).custom_minimum_size.x = cw

func atualizar() -> void:
	var e: Dictionary = Jogo.e
	_info.text = "Energia %d   ·   Fama %d (máx. %d)" % [int(e["energia"]), int(e.get("fama", 0)), int(e.get("famaMax", 0))]
	_painel.atualizar()
	Tema.limpar(_grade)
	_cartoes.clear()
	var sel: Array = Jogo.equipe_valida()
	for a in Game.arenas():
		var c := _cartao(e, a, sel)
		_grade.add_child(c)
		_cartoes.append(c)
	_ajustar_larguras()

func _cartao(e: Dictionary, a: Dictionary, sel: Array) -> Control:
	var fama := Game.arena_liberada(e, a)
	var liberada: bool = fama["liberada"]
	var dif := int(Game.jsround((Game.multiplicador_arena(a, str(e.get("config", {}).get("dificuldade", "medio"))) - 1.0) * 100.0))
	var n := sel.size()
	# motivo que impede a luta
	var erro := ""
	for g in sel:
		if not a["honra"] and g["campeao"]:
			erro = "%s é o campeão e não entra no Poço." % g["nome"]
		elif a["honra"] and g["pocoOnly"]:
			erro = "%s já lutou no Poço: fora das arenas de honra." % g["nome"]
		if erro != "":
			break
	var motivo := ""
	if not liberada:
		motivo = "Fechada: abre com %d de fama (faltam %d)." % [int(a["famaMin"]), int(fama["faltam"])]
	elif n == 0:
		motivo = "Escale 1 ou 2 gladiadores acima."
	elif erro != "":
		motivo = erro
	elif int(e["energia"]) < n:
		motivo = "Energia insuficiente (precisa de %d)." % n

	var p := PanelContainer.new()
	var sb := Tema.caixa(Tema.PAINEL if liberada else Color("17100d"), Tema.OURO_ESCURO if liberada else Tema.BORDA, 10, 1, 0)
	p.add_theme_stylebox_override("panel", sb)
	p.clip_contents = true
	var v := Tema.vbox(6)
	p.add_child(v)
	# arte com faixa de tipo e cadeado
	var arte := Control.new()
	arte.custom_minimum_size = Vector2(0, 150)
	arte.clip_contents = true
	v.add_child(arte)
	var img := TextureRect.new()
	img.texture = Tema.textura("assets/arenas/%s-mini.png" % a["id"])
	img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	img.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if not liberada:
		img.modulate = Color(0.32, 0.3, 0.3)
	arte.add_child(img)
	var degrade := ColorRect.new()
	degrade.color = Color(0, 0, 0, 0.0)
	degrade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	arte.add_child(degrade)
	var faixa := Tema.rotulo("ARENA DE HONRA" if a["honra"] else "O POÇO", 13, Color("1a1208") if a["honra"] else Color("f0d8d0"), true)
	faixa.autowrap_mode = TextServer.AUTOWRAP_OFF
	faixa.add_theme_stylebox_override("normal", Tema.caixa(Tema.OURO if a["honra"] else Tema.SANGUE, Tema.OURO_ESCURO, 4, 1, 2))
	faixa.position = Vector2(8, 8)
	arte.add_child(faixa)
	if not liberada:
		var cad := Tema.rotulo("FECHADA", 26, Color("e8d5b0"), true)
		cad.autowrap_mode = TextServer.AUTOWRAP_OFF
		cad.add_theme_color_override("font_outline_color", Color.BLACK)
		cad.add_theme_constant_override("outline_size", 6)
		cad.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
		cad.grow_horizontal = Control.GROW_DIRECTION_BOTH
		cad.grow_vertical = Control.GROW_DIRECTION_BOTH
		arte.add_child(cad)
	v.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var corpo := MarginContainer.new()
	corpo.size_flags_vertical = Control.SIZE_EXPAND_FILL
	for lado in ["left", "right", "bottom"]:
		corpo.add_theme_constant_override("margin_" + lado, 12)
	v.add_child(corpo)
	var c := Tema.vbox(5)
	c.size_flags_vertical = Control.SIZE_EXPAND_FILL
	corpo.add_child(c)
	var nome := Tema.titulo(str(a["nome"]), 24)
	nome.add_theme_color_override("font_color", Tema.OURO if liberada else Tema.CINZA)
	c.add_child(nome)
	var plateia := ("Plateia %s" % a["plateia"]) if a["honra"] else "Plateia sorteada a cada luta"
	c.add_child(Tema.rotulo(plateia + (" · Arena de honra" if a["honra"] else " · golpes causam efeitos persistentes"), 16, Tema.CINZA))
	# fama
	var fama_max := int(e.get("famaMax", 0))
	var fama_min := int(a["famaMin"])
	var fr := Tema.hbox(5)
	fr.add_child(Glifo.novo("coroa_fama" if liberada else "cadeado", 16, Tema.VERDE if liberada else Color("e0483a")))
	var fama_txt := "Fama: %d/%d" % [mini(fama_max, fama_min), fama_min] if fama_min > 0 else "Fama: sem exigência"
	var lf := Tema.rotulo(fama_txt + (" · aberta" if liberada else " · fechada"), 16, Tema.VERDE if liberada else Tema.OURO_ESCURO)
	lf.autowrap_mode = TextServer.AUTOWRAP_OFF
	fr.add_child(lf)
	c.add_child(fr)
	if not liberada:
		var pb := ProgressBar.new()
		pb.max_value = float(maxi(1, fama_min))
		pb.value = float(fama_max)
		pb.show_percentage = false
		pb.custom_minimum_size = Vector2(0, 8)
		pb.add_theme_stylebox_override("background", Tema.caixa(Color(0, 0, 0, 0.5), Tema.BORDA, 4, 1, 0))
		pb.add_theme_stylebox_override("fill", Tema.caixa(Tema.OURO_ESCURO, Tema.OURO_ESCURO, 4, 0, 0))
		c.add_child(pb)
	var ganho := "Vitória: +%d fama · +%d glória" % [int(a.get("famaVitoria", 0)), int(a.get("gloria", 0))]
	c.add_child(Tema.rotulo(ganho, 16, Color("e0b0f0")))
	if int(a.get("famaDerrota", 0)) > 0:
		c.add_child(Tema.rotulo("Perde %d de fama na derrota." % int(a["famaDerrota"]), 16, Color("e06a5a")))
	var mult := maxi(1, n)
	var r0 := int(a["recompensaOuro"][0])
	var r1 := int(a["recompensaOuro"][1])
	var rec: String
	if not a["honra"]:
		rec = "Recompensa %d ouro + bônus da lotação (10%%, 20%% ou 30%%)" % (r0 * mult)
	elif r0 == r1:
		rec = "Recompensa %d ouro" % (r0 * mult)
	else:
		rec = "Recompensa %d–%d ouro" % [r0 * mult, r1 * mult]
	if n == 2:
		rec += " (×2)"
	c.add_child(Tema.rotulo(rec, 17, Tema.OURO))
	var rv := "Rivais %s" % ("+%d%% mais fortes" % dif if dif > 0 else ("%d%% mais fracos" % -dif if dif < 0 else "no nível base"))
	c.add_child(Tema.rotulo(rv + " · níveis %d–%d" % [int(a["nivelRival"][0]), int(a["nivelRival"][1])], 16, Tema.AREIA))
	c.add_child(Tema.rotulo("Rendição: quem cai abaixo de 25% se rende.", 15, Tema.CINZA))
	if a.has("efeitos"):
		var fl := HFlowContainer.new()
		fl.add_theme_constant_override("h_separation", 5)
		fl.add_theme_constant_override("v_separation", 4)
		for ef in a["efeitos"]:
			var l := Tema.rotulo(str(Game.NOME_EFEITO[ef]), 14, Color.WHITE)
			l.autowrap_mode = TextServer.AUTOWRAP_OFF
			var cor: Color = TelaLuta.COR_EFEITO[ef]
			l.add_theme_stylebox_override("normal", Tema.caixa(cor.darkened(0.5), cor, 8, 1, 1))
			fl.add_child(l)
		c.add_child(fl)
	if motivo != "":
		var lm := Tema.rotulo(motivo, 15, Tema.OURO_ESCURO if liberada else Tema.CINZA)
		c.add_child(lm)
	var txt := "Lutar"
	if n == 1:
		txt = "Lutar 1×1"
	elif n == 2:
		txt = "Lutar 2×2 · 2 energia, ouro ×2"
	var esp := Control.new()
	esp.size_flags_vertical = Control.SIZE_EXPAND_FILL
	c.add_child(esp)
	var b := Tema.botao(txt, "primario", 19)
	b.custom_minimum_size = Vector2(0, 44)
	b.disabled = motivo != ""
	b.pressed.connect(func(): _lutar(str(a["id"])))
	c.add_child(b)
	return p

## Escala a luta: calcula, salva e abre a tela de luta com os callbacks de desistir, pular e fim.
func _lutar(arena_id: String) -> void:
	var ids: Array = _painel.ids()
	if ids.size() < 1 or ids.size() > 2:
		Jogo.aviso.emit("Escolha 1 ou 2 gladiadores.")
		return
	var antes: Dictionary = Jogo.e.duplicate(true)
	var payload: Dictionary = Game.lutar_arena(Jogo.e, ids, arena_id)
	if payload.has("erro"):
		Jogo.aviso.emit(str(payload["erro"]))
		return
	Jogo.salvar()
	Jogo.mudou.emit()
	var ao_fim := func() -> void:
		Jogo.mudou.emit()
	var ao_desistir := func() -> void:
		Jogo.e = Game.desistir_da_luta(antes, Jogo.e, ids)
		Jogo.salvar()
	var ao_pular := func() -> int:
		var perda := Game.pular_luta(Jogo.e, payload)
		Jogo.salvar()
		return perda
	if Jogo.iniciar_luta.get_connections().is_empty():
		TelaLuta.abrir(self, payload, ao_fim, ao_desistir, ao_pular)
	else:
		Jogo.iniciar_luta.emit(payload, ao_fim, ao_desistir, ao_pular)
