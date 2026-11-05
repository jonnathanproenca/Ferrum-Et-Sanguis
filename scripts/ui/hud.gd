class_name Hud
extends Control
## Barra superior (casa, ouro, energia, turno, vitórias), abas e área de conteúdo.

const ABAS: Array = [["ludus", "Ludus"], ["upgrades", "Upgrades"], ["mercado", "Mercado"], ["armeiro", "Armeiro"],
	["enfermaria", "Enfermaria"], ["arenas", "Arenas"], ["campanha", "Campanha"], ["config", "Opções"]]

var _telas := {}
var _botoes := {}
var _conteudo: Control
var _aba := "ludus"
var _l_casa: Label
var _l_ouro: Label
var _l_energia: Label
var _l_turno: Label
var _l_vit: Label
var _l_fama: Label
var _b_turno: Button
var _toast: Label
var _toast_tween: Tween

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var raiz := Tema.vbox(0)
	raiz.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(raiz)

	# Barra superior
	var barra := PanelContainer.new()
	var sb := Tema.caixa(Tema.PAINEL, Tema.SANGUE, 0, 0, 6)
	sb.border_width_bottom = 2
	barra.add_theme_stylebox_override("panel", sb)
	raiz.add_child(barra)
	var h := Tema.hbox(18)
	barra.add_child(h)
	_l_casa = Tema.rotulo("", 22, Tema.OURO, true)
	_l_casa.autowrap_mode = TextServer.AUTOWRAP_OFF
	h.add_child(_l_casa)
	_l_ouro = _stat(h, Tema.OURO)
	_l_energia = _stat(h, Color("7fb6e8"))
	_l_turno = _stat(h, Tema.AREIA)
	_l_vit = _stat(h, Tema.AREIA)
	_l_fama = _stat(h, Color("e0b0f0"))
	var esp := Control.new()
	esp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(esp)
	_b_turno = Tema.botao("Próximo turno", "primario")
	_b_turno.pressed.connect(_proximo_turno)
	h.add_child(_b_turno)
	var b_som := Tema.botao("Som")
	b_som.pressed.connect(func(): Som.definir_prefs({"ativo": not Jogo.prefs["audio"]["ativo"]}); _atualizar_som(b_som))
	_atualizar_som(b_som)
	h.add_child(b_som)
	var b_menu := Tema.botao("Menu")
	b_menu.pressed.connect(func(): Jogo.salvar(); Jogo.navegar.emit("menu"))
	h.add_child(b_menu)

	# Abas
	var faixa := PanelContainer.new()
	faixa.add_theme_stylebox_override("panel", Tema.caixa(Tema.BG, Tema.BG, 0, 0, 6))
	raiz.add_child(faixa)
	var ha := Tema.hbox(6)
	faixa.add_child(ha)
	for a in ABAS:
		var b := Tema.botao(a[1])
		b.toggle_mode = true
		b.pressed.connect(func(): abrir(a[0]))
		ha.add_child(b)
		_botoes[a[0]] = b

	# Conteúdo
	_conteudo = Control.new()
	_conteudo.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_conteudo.clip_contents = true
	raiz.add_child(_conteudo)
	for a in ABAS:
		var t: Tela = load("res://scripts/ui/tela_%s.gd" % a[0]).new()
		t.visible = false
		_conteudo.add_child(t)
		_telas[a[0]] = t

	# Aviso (toast)
	_toast = Tema.rotulo("", 20, Tema.AREIA)
	_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast.add_theme_stylebox_override("normal", Tema.caixa(Color(0.1, 0.05, 0.04, 0.95), Tema.SANGUE_CLARO, 8, 2, 10))
	_toast.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_toast.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_toast.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_toast.offset_bottom = -24
	_toast.modulate.a = 0.0
	_toast.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_toast.z_index = 100
	add_child(_toast)

	Jogo.iniciar_luta.connect(func(payload, ao_fim, ao_desistir, ao_pular): TelaLuta.abrir(self, payload, ao_fim, ao_desistir, ao_pular))
	Jogo.mudou.connect(_atualizar_barra)
	Jogo.aviso.connect(avisar)
	Jogo.abrir_aba.connect(abrir)
	_atualizar_barra()
	abrir("ludus")
	Tutorial.verificar(self)

func _stat(pai: Control, cor: Color) -> Label:
	var l := Tema.rotulo("", 20, cor)
	l.autowrap_mode = TextServer.AUTOWRAP_OFF
	pai.add_child(l)
	return l

func _atualizar_som(b: Button) -> void:
	b.text = "Som: sim" if Jogo.prefs["audio"]["ativo"] else "Som: não"

func abrir(aba: String) -> void:
	if not _telas.has(aba):
		return
	_aba = aba
	for k in _telas:
		_telas[k].visible = (k == aba)
		_botoes[k].button_pressed = (k == aba)
	_telas[aba].ao_mostrar()
	Tutorial.verificar(self)

func aba_atual() -> String:
	return _aba

func _proximo_turno() -> void:
	Jogo.resultado(Game.avancar_turno(Jogo.e))

func _atualizar_barra() -> void:
	var e: Dictionary = Jogo.e
	if e.is_empty():
		return
	_l_casa.text = Game.lanista_da_casa(e)["nome"]
	_l_ouro.text = "Ouro %d" % int(e["ouro"])
	_l_energia.text = "Energia %d" % int(e["energia"])
	_l_turno.text = "Turno %d" % int(e["turno"])
	_l_vit.text = "Vitórias %d" % int(e["vitoriasTotais"])
	_l_fama.text = "Fama %d" % int(e.get("fama", 0))
	_b_turno.disabled = false
	Tutorial.verificar(self)

func avisar(texto: String) -> void:
	_toast.text = " " + texto + " "
	if _toast_tween:
		_toast_tween.kill()
	_toast.modulate.a = 1.0
	_toast_tween = create_tween()
	_toast_tween.tween_interval(2.8)
	_toast_tween.tween_property(_toast, "modulate:a", 0.0, 0.6)
