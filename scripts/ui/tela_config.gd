class_name TelaConfig
extends Tela
## Aba "Opções": som, partida (tutorial, reiniciar, voltar ao menu), cheats (quando liberados) e créditos.
## Também expõe construtores estáticos reutilizados pelo menu e pela seleção (painel de áudio e de cheats).

const VERSAO := "1.0 (Godot 4.4)"

static var _bolinha: ImageTexture

var _col: VBoxContainer
var _meta: Label
var _cheats_box: VBoxContainer

# ---------- Construtores estáticos reutilizáveis ----------

static func _tex_bolinha() -> ImageTexture:
	if _bolinha == null:
		var n := 22
		var img := Image.create(n, n, false, Image.FORMAT_RGBA8)
		var c := Vector2(n / 2.0 - 0.5, n / 2.0 - 0.5)
		for y in range(n):
			for x in range(n):
				var d := Vector2(x, y).distance_to(c)
				var a: float = clampf(n / 2.0 - d, 0.0, 1.0)
				var cor := Tema.OURO if d < n / 2.0 - 3.0 else Tema.SANGUE
				img.set_pixel(x, y, Color(cor, a))
		_bolinha = ImageTexture.create_from_image(img)
	return _bolinha

static func slider(valor: float) -> HSlider:
	var s := HSlider.new()
	s.min_value = 0.0
	s.max_value = 1.0
	s.step = 0.05
	s.value = valor
	s.custom_minimum_size = Vector2(220, 28)
	s.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	s.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	s.focus_mode = Control.FOCUS_NONE
	s.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var fundo := Tema.caixa(Color("0c0706"), Tema.BORDA, 4, 1, 0)
	fundo.content_margin_top = 4
	fundo.content_margin_bottom = 4
	s.add_theme_stylebox_override("slider", fundo)
	s.add_theme_stylebox_override("grabber_area", Tema.caixa(Tema.SANGUE_CLARO, Tema.SANGUE_CLARO, 4, 0, 0))
	s.add_theme_stylebox_override("grabber_area_highlight", Tema.caixa(Tema.OURO_ESCURO, Tema.OURO_ESCURO, 4, 0, 0))
	s.add_theme_icon_override("grabber", _tex_bolinha())
	s.add_theme_icon_override("grabber_highlight", _tex_bolinha())
	s.add_theme_icon_override("grabber_disabled", _tex_bolinha())
	return s

## Painel de áudio: botão de áudio ligado/desligado e sliders de música e efeitos (grava em Som.definir_prefs).
static func painel_audio() -> Control:
	var v := Tema.vbox(10)
	var p: Dictionary = Jogo.prefs["audio"]
	var b := Tema.botao("")
	b.toggle_mode = true
	b.custom_minimum_size = Vector2(0, 42)
	var atualizar_b := func():
		var on: bool = Jogo.prefs["audio"]["ativo"]
		b.set_pressed_no_signal(on)
		b.text = "Áudio ligado" if on else "Áudio desligado"
		b.add_theme_stylebox_override("normal", Tema.caixa(Tema.SANGUE if on else Tema.PAINEL, Tema.OURO_ESCURO if on else Tema.BORDA, 6, 1, 6))
		b.add_theme_stylebox_override("pressed", Tema.caixa(Tema.SANGUE, Tema.OURO, 6, 1, 6))
	atualizar_b.call()
	b.pressed.connect(func():
		Som.definir_prefs({"ativo": not Jogo.prefs["audio"]["ativo"]})
		atualizar_b.call())
	v.add_child(b)
	for par in [["Música", "musica"], ["Efeitos", "efeitos"]]:
		var h := Tema.hbox(12)
		var l := Tema.rotulo(par[0], 19)
		l.custom_minimum_size = Vector2(90, 0)
		h.add_child(l)
		var s := slider(float(p[par[1]]))
		var pct := Tema.rotulo("%d%%" % roundi(float(p[par[1]]) * 100.0), 17, Tema.OCRE)
		pct.custom_minimum_size = Vector2(48, 0)
		pct.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		var chave: String = par[1]
		s.value_changed.connect(func(x: float):
			pct.text = "%d%%" % roundi(x * 100.0)
			Som.definir_prefs({chave: x}))
		# toca um efeito ao soltar, para ouvir o volume
		if chave == "efeitos":
			s.drag_ended.connect(func(_c: bool): Som.sfx("sfx/moeda"))
		h.add_child(s)
		h.add_child(pct)
		v.add_child(h)
	return v

static func _alternar(rotulo: String, chave: String, padrao: bool = false) -> Control:
	var h := Tema.hbox(12)
	var b := Tema.botao("")
	b.toggle_mode = true
	b.custom_minimum_size = Vector2(124, 36)
	var pintar := func(on: bool) -> void:
		b.set_pressed_no_signal(on)
		b.text = "LIGADO" if on else "desligado"
		b.add_theme_stylebox_override("normal", Tema.caixa(Tema.SANGUE if on else Tema.PAINEL, Tema.OURO_ESCURO if on else Tema.BORDA, 6, 1, 4))
		b.add_theme_stylebox_override("pressed", Tema.caixa(Tema.SANGUE, Tema.OURO, 6, 1, 4))
	pintar.call(bool(Jogo.prefs.get(chave, padrao)))
	b.pressed.connect(func() -> void:
		var novo: bool = not bool(Jogo.prefs.get(chave, padrao))
		Jogo.prefs[chave] = novo
		Jogo.salvar_prefs()
		pintar.call(novo))
	h.add_child(b)
	var l := Tema.rotulo(rotulo, 18)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(l)
	return h

## Tamanho da interface (zoom). Automático amplia em telas de toque.
static func painel_escala() -> Control:
	var h := Tema.hbox(12)
	var ob := OptionButton.new()
	ob.focus_mode = Control.FOCUS_NONE
	ob.custom_minimum_size = Vector2(190, 40)
	ob.add_theme_font_size_override("font_size", 17)
	var vals := [0.0, 1.0, 1.25, 1.5, 1.8]
	var nomes := ["Automático", "Normal", "Grande", "Muito grande", "Máximo"]
	var atual := float(Jogo.prefs.get("escalaUi", 0.0))
	var sel := 0
	for i in range(vals.size()):
		ob.add_item(nomes[i])
		if is_equal_approx(vals[i], atual):
			sel = i
	ob.selected = sel
	ob.item_selected.connect(func(i: int) -> void:
		Jogo.prefs["escalaUi"] = vals[i]
		Jogo.salvar_prefs()
		Jogo.aplicar_escala())
	h.add_child(ob)
	var l := Tema.rotulo("Tamanho da interface", 18)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(l)
	return h

static func cheat_liberado() -> bool:
	return bool(Jogo.prefs.get("cheatLiberado", false))

## Lista de cheats com botões LIGADO/desligado. Grava em Jogo.prefs["cheats"] e, havendo partida, em Jogo.e["cheats"].
static func painel_cheats(so_prefs: bool = false) -> Control:
	var v := Tema.vbox(8)
	var com_partida: bool = not so_prefs and not Jogo.e.is_empty()
	var atual: Dictionary = Jogo.e.get("cheats", Jogo.prefs.get("cheats", {})) if com_partida else Jogo.prefs.get("cheats", {})
	var intro := Tema.rotulo("Para testar as funções sem jogar. As opções valem para este ludus e ficam salvas para os próximos.", 16, Tema.OCRE)
	v.add_child(intro)
	for k in Game.CHEATS_NOMES:
		var chave: String = k
		var h := Tema.hbox(12)
		var b := Tema.botao("")
		b.toggle_mode = true
		b.custom_minimum_size = Vector2(124, 36)
		var pintar := func(on: bool):
			b.set_pressed_no_signal(on)
			b.text = "LIGADO" if on else "desligado"
			b.add_theme_stylebox_override("normal", Tema.caixa(Tema.SANGUE if on else Tema.PAINEL, Tema.OURO_ESCURO if on else Tema.BORDA, 6, 1, 4))
			b.add_theme_stylebox_override("pressed", Tema.caixa(Tema.SANGUE, Tema.OURO, 6, 1, 4))
		pintar.call(bool(atual.get(chave, false)))
		b.pressed.connect(func():
			var novo: bool = not bool(Jogo.prefs["cheats"].get(chave, false))
			if com_partida:
				novo = not bool(Jogo.e.get("cheats", {}).get(chave, false))
			definir_cheat(chave, novo, not com_partida)
			pintar.call(novo))
		h.add_child(b)
		var l := Tema.rotulo(str(Game.CHEATS_NOMES[chave]), 18)
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		h.add_child(l)
		v.add_child(h)
	return v

static func definir_cheat(chave: String, ligado: bool, so_prefs: bool = false) -> void:
	if chave == "ouro" and ligado and not so_prefs and not Jogo.e.is_empty():
		Jogo.e["ouro"] = maxi(int(Jogo.e["ouro"]), 9999999)
		Jogo.mudou.emit()
	var c: Dictionary = Jogo.prefs.get("cheats", {})
	c[chave] = ligado
	Jogo.prefs["cheats"] = c
	Jogo.salvar_prefs()
	if not so_prefs and not Jogo.e.is_empty():
		var ec: Dictionary = Jogo.e.get("cheats", {})
		ec[chave] = ligado
		Jogo.e["cheats"] = ec
		if chave == "lendario" and ligado:
			Game.gerar_armeiro_mestre(Jogo.e)
		Jogo.notificar()

## Painel de opções completo (áudio e, se liberado, cheats) para uma modal.
static func conteudo_opcoes() -> Control:
	var v := Tema.vbox(14)
	v.add_child(_secao("Som"))
	v.add_child(painel_audio())
	v.add_child(_secao("Visual"))
	v.add_child(painel_escala())
	if cheat_liberado():
		v.add_child(_secao("Cheat mode"))
		v.add_child(painel_cheats())
	return v

static func _secao(texto: String) -> Control:
	var v := Tema.vbox(4)
	var l := Tema.rotulo(texto.to_upper(), 15, Tema.OURO_ESCURO, true)
	l.add_theme_constant_override("outline_size", 0)
	v.add_child(l)
	var linha := ColorRect.new()
	linha.color = Tema.BORDA
	linha.custom_minimum_size = Vector2(0, 2)
	v.add_child(linha)
	return v

# ---------- Aba ----------

func construir() -> void:
	var sc := ScrollContainer.new()
	sc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(sc)
	var centro := CenterContainer.new()
	centro.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(centro)
	var m := MarginContainer.new()
	for lado in ["left", "right", "top", "bottom"]:
		m.add_theme_constant_override("margin_" + lado, 16)
	m.custom_minimum_size = Vector2(760, 0)
	centro.add_child(m)
	_col = Tema.vbox(14)
	m.add_child(_col)

	_col.add_child(Tema.titulo("Opções", 30))

	# Som
	var p_som := _cartao()
	p_som.add_child(_secao("Som"))
	p_som.add_child(painel_audio())
	_col.add_child(p_som.get_parent())

	# Partida
	var p_part := _cartao()
	p_part.add_child(_secao("Partida"))
	_meta = Tema.rotulo("", 18, Tema.AREIA)
	p_part.add_child(_meta)
	var h := Tema.hbox(10)
	var b_tut := Tema.botao("Rever tutorial")
	b_tut.pressed.connect(_rever_tutorial)
	h.add_child(b_tut)
	var b_menu := Tema.botao("Voltar ao menu")
	b_menu.pressed.connect(func(): Jogo.salvar(); Jogo.navegar.emit("menu"))
	h.add_child(b_menu)
	var b_rei := Tema.botao("Reiniciar partida", "primario")
	b_rei.pressed.connect(_pedir_reinicio)
	h.add_child(b_rei)
	p_part.add_child(h)
	var dica := Tema.rotulo("Reiniciar apaga o save atual e volta à escolha do lanista.", 15, Tema.CINZA)
	p_part.add_child(dica)
	_col.add_child(p_part.get_parent())

	# Sobre
	var p_sobre := _cartao()
	p_sobre.add_child(_secao("Sobre"))
	p_sobre.add_child(Tema.rotulo("Ferrum et Sanguis · versão %s" % VERSAO, 19, Tema.OURO))
	p_sobre.add_child(Tema.rotulo("Gestão de um ludus romano: compre escravos, escolha estilos, construa e lute da areia de Pompeia ao Coliseu.", 17, Tema.AREIA))
	p_sobre.add_child(Tema.rotulo("Fontes Cinzel e EB Garamond, licença SIL Open Font License (OFL). Porte para Godot 4.4 do jogo original em TypeScript.", 16, Tema.CINZA))
	_col.add_child(p_sobre.get_parent())

	# Cheats (preenchido em atualizar, pois a liberação pode mudar)
	_cheats_box = Tema.vbox(8)
	_col.add_child(_cheats_box)

## Cria um painel de seção e devolve o VBox interno (o PanelContainer é o pai do VBox).
func _cartao() -> VBoxContainer:
	var p := Tema.painel(Tema.PAINEL, Tema.BORDA)
	var v := Tema.vbox(10)
	p.add_child(v)
	return v

func atualizar() -> void:
	var e: Dictionary = Jogo.e
	var lendas := 0
	for g in e["gladiadores"]:
		if g.get("lenda", false):
			lendas += 1
	_meta.text = "Libertos nesta partida: %d · Lendas no ludus: %d · Dificuldade: %s" % [e["libertados"].size(), lendas, Game.regras_de(e)["nome"]]
	Tema.limpar(_cheats_box)
	if cheat_liberado():
		var c := _cartao()
		c.add_child(_secao("Cheat mode"))
		c.add_child(painel_cheats())
		_cheats_box.add_child(c.get_parent())

func _rever_tutorial() -> void:
	Jogo.e["tutorial"] = {"vistos": []}
	Jogo.salvar()
	Jogo.tutorial_pedido.emit("tour")

func _pedir_reinicio() -> void:
	var v := Tema.vbox(14)
	v.add_child(Tema.rotulo("Isto apaga o save desta partida, com todos os gladiadores, construções e ouro, e volta à escolha do lanista. Não dá para desfazer.", 19))
	var h := Tema.hbox(10)
	h.alignment = BoxContainer.ALIGNMENT_END
	v.add_child(h)
	var m := Modal.abrir(self, "Reiniciar partida?", v, 520.0, false)
	var cancelar := Tema.botao("Cancelar")
	cancelar.pressed.connect(m.fechar)
	h.add_child(cancelar)
	var ok := Tema.botao("Apagar e recomeçar", "primario")
	ok.pressed.connect(func():
		m.fechar()
		Jogo.apagar_save()
		Jogo.e = {}
		Jogo.equipe = []
		Jogo.navegar.emit("selecao"))
	h.add_child(ok)
