class_name Modal
extends Control
## Janela modal simples: fundo escurecido, painel com título e botão de fechar. Cobre a tela inteira (sobe até o Control mais alto).

signal fechado

var _corpo: VBoxContainer
var _painel: PanelContainer
var _vw := 1280.0

## Abre uma modal sobre `pai`. `conteudo` é colocado dentro de uma rolagem; `largura` é a largura do painel.
static func abrir(pai: Node, titulo: String, conteudo: Control, largura: float = 560.0, com_fechar: bool = true) -> Modal:
	var topo: Node = pai
	while topo.get_parent() is Control:
		topo = topo.get_parent()
	var m := Modal.new()
	m._vw = pai.get_viewport_rect().size.x if pai.is_inside_tree() else 1280.0
	m._montar(titulo, conteudo, largura, com_fechar)
	topo.add_child(m)
	return m

func _montar(titulo: String, conteudo: Control, largura: float, com_fechar: bool) -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	z_as_relative = false
	z_index = 3500
	mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.01, 0.01, 0.78)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.gui_input.connect(func(ev: InputEvent):
		if com_fechar and ev is InputEventMouseButton and ev.pressed:
			fechar())
	add_child(dim)
	var centro := CenterContainer.new()
	centro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	centro.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(centro)
	_painel = PanelContainer.new()
	var sb := Tema.caixa(Color("1d1411"), Tema.OURO_ESCURO, 10, 2, 14)
	sb.shadow_color = Color(0, 0, 0, 0.7)
	sb.shadow_size = 24
	_painel.add_theme_stylebox_override("panel", sb)
	_painel.custom_minimum_size = Vector2(minf(largura, maxf(_vw - 24.0, 320.0)), 0)
	centro.add_child(_painel)
	_corpo = Tema.vbox(10)
	_painel.add_child(_corpo)
	var topo := Tema.hbox(8)
	_corpo.add_child(topo)
	var t := Tema.titulo(titulo, 24)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	topo.add_child(t)
	if com_fechar:
		var x := Tema.botao("Fechar")
		x.pressed.connect(fechar)
		topo.add_child(x)
	_corpo.add_child(HSeparator.new())
	var sc := ScrollContainer.new()
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sc.custom_minimum_size = Vector2(0, 80)
	_corpo.add_child(sc)
	conteudo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(conteudo)
	sc.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	_ajustar.call_deferred(sc, conteudo)
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.15)

## Limita a altura da rolagem ao que cabe na janela (espera o layout para medir os textos com quebra de linha).
func _ajustar(sc: ScrollContainer, conteudo: Control) -> void:
	for i in range(2):
		await get_tree().process_frame
		if not is_inside_tree():
			return
	var maxh: float = get_viewport_rect().size.y - 150.0
	sc.custom_minimum_size.y = minf(conteudo.get_combined_minimum_size().y, maxh)

func fechar() -> void:
	fechado.emit()
	queue_free()
