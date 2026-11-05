class_name PainelEscalacao
extends VBoxContainer
## Escolha dos gladiadores da próxima luta (compartilha `Jogo.equipe`), usada nas Arenas e na Campanha.
## Cartões com o sprite do gladiador, nível, atributos finais e marca de seleção numerada; limite de `formato` (0 = até 2).
## API: `formato` (1 ou 2 gladiadores; 0 = livre entre 1 e 2), `atualizar()`, `ids()`. Sinal `mudou_equipe`.
signal mudou_equipe

const ABREV := {"forca": "FOR", "agilidade": "AGI", "vitalidade": "VIT", "sorte": "SOR"}
const COR_ATRIB := {"forca": Color("e07a5f"), "agilidade": Color("8fd0a0"), "vitalidade": Color("e8b4b4"), "sorte": Color("f2d28a")}
const LARGURA_CARTAO := 156.0

var formato := 0:
	set(v):
		formato = v
		if is_node_ready():
			atualizar()
var titulo := "Escalação"          ## texto do cabeçalho (ex.: "Escalação (2 contra 2)")

var _cab: Label
var _contagem: Label
var _b_limpar: Button
var _dica: Label
var _rolagem: ScrollContainer
var _faixa: HBoxContainer

func _ready() -> void:
	add_theme_constant_override("separation", 8)
	var h := Tema.hbox(12)
	add_child(h)
	_cab = Tema.rotulo(titulo, 22, Tema.OURO, true)
	_cab.autowrap_mode = TextServer.AUTOWRAP_OFF
	h.add_child(_cab)
	_contagem = Tema.rotulo("", 20, Tema.AREIA)
	_contagem.autowrap_mode = TextServer.AUTOWRAP_OFF
	h.add_child(_contagem)
	_dica = Tema.rotulo("", 16, Tema.CINZA)
	_dica.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_dica.autowrap_mode = TextServer.AUTOWRAP_OFF
	_dica.clip_text = true
	h.add_child(_dica)
	_b_limpar = Tema.botao("Limpar", "normal", 16)
	_b_limpar.custom_minimum_size = Vector2(0, 32)
	_b_limpar.pressed.connect(_limpar)
	h.add_child(_b_limpar)
	_rolagem = ScrollContainer.new()
	_rolagem.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_rolagem.custom_minimum_size = Vector2(0, 226)
	_rolagem.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(_rolagem)
	_faixa = Tema.hbox(10)
	_rolagem.add_child(_faixa)
	Jogo.mudou.connect(func() -> void:
		if is_visible_in_tree():
			atualizar())
	visibility_changed.connect(func() -> void:
		if is_visible_in_tree():
			atualizar())
	atualizar()

func maximo() -> int:
	return formato if formato > 0 else 2

func ids() -> Array:
	return Jogo.equipe_valida().map(func(g): return g["id"])

func _limpar() -> void:
	Jogo.equipe.clear()
	atualizar()
	mudou_equipe.emit()

func _alternar(id: String) -> void:
	if id in Jogo.equipe:
		Jogo.equipe.erase(id)
	else:
		var max_n := maximo()
		if Jogo.equipe.size() >= max_n:
			if max_n > 1:
				Jogo.aviso.emit("Equipe completa: tire alguém antes.")
				return
			Jogo.equipe.clear()   # formato de 1: trocar de escolhido
		Jogo.equipe.append(id)
	atualizar()
	mudou_equipe.emit()

func atualizar() -> void:
	if Jogo.e.is_empty() or _faixa == null:
		return
	_cab.text = titulo
	Tema.limpar(_faixa)
	var sel: Array = Jogo.equipe_valida()
	var max_n := maximo()
	var vivos: Array = Jogo.e["gladiadores"].filter(func(g): return g["vivo"] and not g.get("semEstilo", false))
	_contagem.text = "%d/%d" % [sel.size(), max_n]
	_contagem.add_theme_color_override("font_color", Tema.VERDE if sel.size() > 0 else Tema.CINZA)
	_b_limpar.disabled = sel.is_empty()
	if vivos.is_empty():
		_dica.text = ""
		var l := Tema.rotulo("Nenhum gladiador pronto para lutar: escolha o estilo dos escravos no ludus.", 18, Tema.OURO_ESCURO)
		l.custom_minimum_size = Vector2(600, 0)
		_faixa.add_child(l)
		return
	_dica.text = "Toque nos gladiadores para escalar." if sel.is_empty() else ", ".join(sel.map(func(g): return str(g["nome"])))
	var casa := Game.lanista_da_casa(Jogo.e)
	var extra := Game.extra_da_casa(Jogo.e)
	for g in vivos:
		_faixa.add_child(_cartao(g, sel.size(), max_n, Jogo.equipe.find(g["id"]), casa, extra))

func _cartao(g: Dictionary, n_sel: int, max_n: int, pos: int, casa: Dictionary, extra: Dictionary) -> Control:
	var marcado := pos >= 0
	var cheio := not marcado and n_sel >= max_n and max_n > 1
	var p := PanelContainer.new()
	p.custom_minimum_size = Vector2(LARGURA_CARTAO, 0)
	var cor_bg := Color("3a2616") if marcado else Tema.PAINEL
	var sb := Tema.caixa(cor_bg, Tema.OURO if marcado else Tema.BORDA, 10, 3 if marcado else 1, 8)
	if marcado:
		sb.shadow_color = Color(0.95, 0.8, 0.45, 0.35)
		sb.shadow_size = 8
	p.add_theme_stylebox_override("panel", sb)
	p.mouse_default_cursor_shape = Control.CURSOR_FORBIDDEN if cheio else Control.CURSOR_POINTING_HAND
	p.tooltip_text = "Equipe completa: tire alguém antes" if cheio else "%s: %s" % [g["nome"], Model.classes()[g["classe"]]["nome"]]
	var v := Tema.vbox(2)
	p.add_child(v)
	# sprite
	var spr := Sprites.controle_gladiador(g, 96)
	spr.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(spr)
	var nome := Tema.rotulo(str(g["nome"]), 18, Tema.OURO, true)
	nome.autowrap_mode = TextServer.AUTOWRAP_OFF
	nome.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nome.clip_text = true
	v.add_child(nome)
	var cl := Tema.rotulo("%s · nv %d" % [Model.classes()[g["classe"]]["nome"], int(g["nivel"])], 15, Tema.AREIA)
	cl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cl.autowrap_mode = TextServer.AUTOWRAP_OFF
	v.add_child(cl)
	var tags: Array = []
	if g["campeao"]:
		tags.append("Campeão")
	if g["lenda"]:
		tags.append("Lenda")
	if g["pocoOnly"]:
		tags.append("Só Poço")
	if g["efeitos"].size() > 0:
		tags.append("Ferido")
	var lt := Tema.rotulo(" · ".join(tags) if tags.size() > 0 else " ", 14, Tema.OURO_ESCURO)
	lt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lt.autowrap_mode = TextServer.AUTOWRAP_OFF
	v.add_child(lt)
	# atributos finais (como na luta)
	var st := Model.stats_do_gladiador(g, str(casa.get("especialidade", "")), extra)
	var grade := GridContainer.new()
	grade.columns = 3
	grade.add_theme_constant_override("h_separation", 8)
	grade.add_theme_constant_override("v_separation", 0)
	for a in Model.ATRIBUTOS:
		var l := Tema.rotulo("%s %d" % [ABREV[a], int(st[a])], 15, COR_ATRIB[a])
		l.autowrap_mode = TextServer.AUTOWRAP_OFF
		grade.add_child(l)
	var lv := Tema.rotulo("PV %d" % (50 + int(st["vitalidade"]) * 5), 15, Tema.CINZA)
	lv.autowrap_mode = TextServer.AUTOWRAP_OFF
	grade.add_child(lv)
	var cg := CenterContainer.new()
	cg.add_child(grade)
	v.add_child(cg)
	_ignorar_mouse(p)
	# selo numerado (sobre o canto do cartão, fora do layout do painel)
	var raiz := Control.new()
	raiz.add_child(p)
	p.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	raiz.custom_minimum_size = p.get_combined_minimum_size()
	p.minimum_size_changed.connect(func() -> void: raiz.custom_minimum_size = p.get_combined_minimum_size())
	if marcado:
		var selo := Label.new()
		selo.text = str(pos + 1)
		selo.add_theme_font_override("font", Tema.fonte_titulo)
		selo.add_theme_font_size_override("font_size", 20)
		selo.add_theme_color_override("font_color", Color("1a1208"))
		selo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		selo.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		selo.add_theme_stylebox_override("normal", Tema.caixa(Tema.OURO, Tema.OURO_ESCURO, 14, 2, 0))
		selo.size = Vector2(30, 30)
		selo.position = Vector2(8, 8)
		selo.mouse_filter = Control.MOUSE_FILTER_IGNORE
		raiz.add_child(selo)
	if cheio:
		p.modulate = Color(1, 1, 1, 0.5)
	p.mouse_filter = Control.MOUSE_FILTER_STOP
	p.gui_input.connect(func(ev: InputEvent) -> void:
		if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
			_alternar(str(g["id"])))
	if not cheio:
		p.mouse_entered.connect(func() -> void: p.modulate = Color(1.12, 1.1, 1.05))
		p.mouse_exited.connect(func() -> void: p.modulate = Color.WHITE)
	return raiz

func _ignorar_mouse(no: Node) -> void:
	for c in no.get_children():
		if c is Control:
			(c as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
		_ignorar_mouse(c)
