class_name TelaModos
extends Control
## Escolha do modo de campanha (antes da escolha do lanista). Toque/clique seleciona e mostra a descrição; "Começar" segue.

var _sel := "imperial"
var _botoes := {}
var _l_desc: Label

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	clip_contents = true
	Som.musica("menu")
	TelaPerfis.montar_fundo(self)
	var centro := CenterContainer.new()
	centro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(centro)
	var v := Tema.vbox(12)
	v.custom_minimum_size = Vector2(560, 0)
	centro.add_child(v)
	var t := Tema.titulo("Escolha o espetáculo", 44)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.add_theme_color_override("font_outline_color", Color("2a0c08"))
	t.add_theme_constant_override("outline_size", 8)
	v.add_child(t)
	v.add_child(Tema.espaco(6))
	for id in Game.MODOS_ORDEM:
		var mid: String = id
		var b := Tema.botao(str(Game.MODOS[mid]["nome"]), "normal", 26)
		b.add_theme_font_override("font", Tema.fonte_titulo)
		b.custom_minimum_size = Vector2(0, 58)
		b.pressed.connect(func(): _sel = mid; _atualizar())
		b.mouse_entered.connect(func(): _sel = mid; _atualizar())
		v.add_child(b)
		_botoes[mid] = b
	_l_desc = Tema.rotulo("", 19, Tema.AREIA)
	_l_desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_l_desc.custom_minimum_size = Vector2(0, 96)
	v.add_child(_l_desc)
	var h := Tema.hbox(12)
	h.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(h)
	var voltar := Tema.botao("Voltar", "normal", 21)
	voltar.custom_minimum_size = Vector2(150, 50)
	voltar.pressed.connect(func(): Jogo.navegar.emit("perfis"))
	h.add_child(voltar)
	var ir := Tema.botao("Começar", "primario", 22)
	ir.add_theme_font_override("font", Tema.fonte_titulo)
	ir.custom_minimum_size = Vector2(260, 50)
	ir.pressed.connect(func():
		Jogo.modo_novo = _sel
		Jogo.navegar.emit("selecao"))
	h.add_child(ir)
	_atualizar()

func _atualizar() -> void:
	for k in _botoes:
		var b: Button = _botoes[k]
		var on: bool = k == _sel
		b.add_theme_stylebox_override("normal", Tema.caixa(Color("a52424") if on else Color("5a1a14"), Tema.OURO if on else Tema.OURO_ESCURO, 6, 2 if on else 1, 8))
		b.add_theme_stylebox_override("hover", Tema.caixa(Color("a52424"), Tema.OURO, 6, 2, 8))
		b.add_theme_stylebox_override("pressed", Tema.caixa(Color("6a1414"), Tema.OURO, 6, 2, 8))
		b.add_theme_color_override("font_color", Tema.OURO if on else Tema.AREIA)
	var m: Dictionary = Game.MODOS[_sel]
	_l_desc.text = str(m["desc"])
