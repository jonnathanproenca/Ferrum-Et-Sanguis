class_name TelaPerfis
extends Control
## Três perfis de jogo: resumo da campanha, renomear, jogar e apagar.

const COR_FIM := {"gameover": Color("d85a4a"), "prazo": Color("d8a04a"), "vitoria": Color("7fc98a")}
const TEXTO_FIM := {"gameover": "GAME OVER", "prazo": "PRAZO ESGOTADO", "vitoria": "CAMPANHA CONCLUÍDA"}

var _linha: HFlowContainer
var _aviso: Label

## Arena ao fundo, escurecida (compartilhado com a tela de modos).
static func montar_fundo(pai: Control) -> void:
	var t := TextureRect.new()
	t.texture = Tema.textura("assets/arenas/coliseu.png")
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	t.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	t.modulate = Color(0.42, 0.34, 0.3)
	pai.add_child(t)

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	clip_contents = true
	Som.musica("menu")
	montar_fundo(self)
	var raiz := Tema.vbox(10)
	raiz.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 24)
	add_child(raiz)
	var topo := Tema.hbox(12)
	raiz.add_child(topo)
	var voltar := Tema.botao("Voltar", "normal", 20)
	voltar.custom_minimum_size = Vector2(120, 46)
	voltar.pressed.connect(func(): Jogo.navegar.emit("menu"))
	topo.add_child(voltar)
	var t := Tema.titulo("Perfis", 44)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	topo.add_child(t)
	var folga := Control.new()
	folga.custom_minimum_size = Vector2(120, 0)
	topo.add_child(folga)
	_aviso = Tema.rotulo("", 18, Tema.SANGUE_CLARO)
	_aviso.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	raiz.add_child(_aviso)
	var rol := ScrollContainer.new()
	rol.size_flags_vertical = Control.SIZE_EXPAND_FILL
	rol.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	raiz.add_child(rol)
	var centro := CenterContainer.new()
	centro.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rol.add_child(centro)
	_linha = HFlowContainer.new()
	_linha.alignment = FlowContainer.ALIGNMENT_CENTER
	_linha.add_theme_constant_override("h_separation", 16)
	_linha.add_theme_constant_override("v_separation", 16)
	_linha.custom_minimum_size = Vector2(minf(1240.0, maxf(320.0, size.x - 60.0)), 0)
	centro.add_child(_linha)
	_montar()

func _montar() -> void:
	Tema.limpar(_linha)
	for s in range(1, Jogo.MAX_PERFIS + 1):
		_linha.add_child(_cartao(s))

func _cartao(s: int) -> Control:
	var p := PanelContainer.new()
	p.custom_minimum_size = Vector2(380, 0)
	p.add_theme_stylebox_override("panel", Tema.caixa(Color(0.09, 0.05, 0.04, 0.92), Tema.OURO_ESCURO, 10, 2, 16))
	var v := Tema.vbox(8)
	p.add_child(v)
	v.add_child(Tema.rotulo("PERFIL %d" % s, 14, Tema.OURO_ESCURO, true))
	if not Jogo.perfil_existe(s):
		var vazio := Tema.rotulo("Vazio", 30, Tema.CINZA, true)
		vazio.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(Tema.espaco(40))
		v.add_child(vazio)
		v.add_child(Tema.espaco(40))
		var novo := Tema.botao("Novo perfil", "primario", 22)
		novo.custom_minimum_size = Vector2(0, 50)
		novo.pressed.connect(func():
			Jogo.slot_novo = s
			Jogo.nome_novo = ""
			Jogo.navegar.emit("modos"))
		v.add_child(novo)
		return p
	var e := Jogo.ler_perfil(s)
	if e.is_empty():
		v.add_child(Tema.rotulo("Não foi possível ler este save (%s)." % Jogo.erro_save, 18, Tema.SANGUE_CLARO))
		var ap := Tema.botao("Apagar", "normal", 18)
		ap.pressed.connect(func(): _confirmar_apagar(s, "perfil ilegível"))
		v.add_child(ap)
		return p
	var r := Game.resumo_perfil(e)
	var nome := LineEdit.new()
	nome.text = str(r["nome"])
	nome.max_length = 24
	nome.add_theme_font_size_override("font_size", 24)
	nome.add_theme_font_override("font", Tema.fonte_titulo)
	nome.add_theme_color_override("font_color", Tema.OURO)
	nome.add_theme_stylebox_override("normal", Tema.caixa(Color(0.16, 0.1, 0.08), Tema.BORDA, 6, 1, 6))
	nome.add_theme_stylebox_override("focus", Tema.caixa(Color(0.2, 0.12, 0.09), Tema.OURO, 6, 2, 6))
	nome.tooltip_text = "Toque para renomear"
	var salvar_nome := func(txt: String) -> void:
		Jogo.renomear_perfil(s, txt)
	nome.text_submitted.connect(func(t): salvar_nome.call(t); nome.release_focus())
	nome.focus_exited.connect(func(): salvar_nome.call(nome.text))
	v.add_child(nome)
	v.add_child(Tema.rotulo("toque no nome para renomear", 13, Tema.CINZA))
	var fim: String = r["fim"]
	if TEXTO_FIM.has(fim):
		var f := Tema.rotulo(TEXTO_FIM[fim], 22, COR_FIM[fim], true)
		f.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(f)
	var g := GridContainer.new()
	g.columns = 2
	g.add_theme_constant_override("h_separation", 14)
	g.add_theme_constant_override("v_separation", 3)
	v.add_child(g)
	var rodada := "%d de %d" % [mini(int(r["turno"]), int(r["dias"])), int(r["dias"])] if int(r["dias"]) > 0 else "%d (sem prazo)" % int(r["turno"])
	var linhas: Array = [
		["Modo", r["modo"]], ["Lanista", "%s · %s" % [r["casa"], r["dificuldade"]]], ["Rodadas", rodada],
		["Campanha", "%d de %d passos" % [int(r["campanha"]), int(r["passos"])]],
		["Lutas", "%d  (%d vitórias · %d derrotas)" % [int(r["lutas"]), int(r["vitorias"]), int(r["derrotas"])]],
		["Gladiadores", "%d atua%s · %d no histórico" % [int(r["atuais"]), "l" if int(r["atuais"]) == 1 else "is", int(r["historico"])]],
		["Mortos", str(int(r["mortes"]))], ["Ouro", "%s (acumulou %s)" % [TelaCampanha.milhar(int(r["ouro"])), TelaCampanha.milhar(int(r["ouroGanho"]))]],
		["Fama máxima", str(int(r["fama"]))], ["Tempo de jogo", TelaCampanha.tempo_jogado(int(r["tempoMs"]))],
	]
	for l in linhas:
		var a := Tema.rotulo(str(l[0]), 16, Tema.CINZA)
		a.autowrap_mode = TextServer.AUTOWRAP_OFF
		g.add_child(a)
		var b := Tema.rotulo(str(l[1]), 16, Tema.AREIA)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		g.add_child(b)
	v.add_child(Tema.espaco(4))
	var h := Tema.hbox(8)
	v.add_child(h)
	var jogar := Tema.botao("Ver o fim" if Game.fim_bloqueia(e) else "Jogar", "primario", 22)
	jogar.custom_minimum_size = Vector2(0, 48)
	jogar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	jogar.pressed.connect(func():
		if Jogo.continuar(s):
			Jogo.equipe = []
			Jogo.navegar.emit("jogo")
		else:
			_aviso.text = "Não foi possível carregar o perfil (%s)." % Jogo.erro_save)
	h.add_child(jogar)
	var apagar := Tema.botao("Apagar", "normal", 18)
	apagar.custom_minimum_size = Vector2(110, 48)
	apagar.pressed.connect(func(): _confirmar_apagar(s, str(r["nome"])))
	h.add_child(apagar)
	return p

func _confirmar_apagar(s: int, nome: String) -> void:
	var v := Tema.vbox(14)
	v.add_child(Tema.rotulo("Apagar o perfil \"%s\"? Gladiadores, construções, ouro e progresso da campanha serão perdidos. Não dá para desfazer." % nome, 19))
	var h := Tema.hbox(10)
	h.alignment = BoxContainer.ALIGNMENT_END
	v.add_child(h)
	var m := Modal.abrir(self, "Apagar perfil %d?" % s, v, 520.0, false)
	var cancelar := Tema.botao("Cancelar")
	cancelar.pressed.connect(m.fechar)
	h.add_child(cancelar)
	var ok := Tema.botao("Apagar", "primario")
	ok.pressed.connect(func():
		m.fechar()
		Jogo.apagar_save(s)
		_montar())
	h.add_child(ok)
