class_name FichaGladiador
extends PanelContainer
## Ficha do gladiador no estilo "Fogueira" (tela de subir de nível): cabeçalho, faixa de Glória, 6 atributos com
## botão "+" de treino, estatísticas derivadas e barra de carga. Tudo vem do núcleo (Model/Combat/Game).
## Uso: var f := FichaGladiador.new(); f.construir(g); depois f.atualizar(g_novo) quando o gladiador mudar.

const COR_LINHA := Color("3a2a1a")
const COR_CAIXA := Color("0a0705")
const COR_FAIXA := {"leve": Color("6aa6d8"), "normal": Color("8fbf7a"), "pesado": Color("d9a63e"), "sobrecarga": Color("c0392b")}
const NOME_FAIXA := {"leve": "Leve", "normal": "Normal", "pesado": "Pesado", "sobrecarga": "Sobrecarga"}

var g: Dictionary = {}
## false: esconde o cabeçalho (nome/classe), p.ex. quando a modal já mostra isso.
var mostrar_cabecalho := true
var _corpo: BoxContainer


func construir(g_: Dictionary) -> void:
	g = g_
	add_theme_stylebox_override("panel", _estilo_moldura())
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	resized.connect(_ao_redimensionar)
	_montar()


func atualizar(g_: Dictionary = {}) -> void:
	if not g_.is_empty():
		g = g_
	_montar()


func _estilo_moldura() -> StyleBoxFlat:
	var sb := Tema.caixa(Color("0e0a08"), Tema.OURO_ESCURO, 2, 1, 14)
	sb.content_margin_left = 18
	sb.content_margin_right = 18
	return sb


func _draw() -> void:
	# moldura interna fina (efeito de duplo filete)
	draw_rect(Rect2(Vector2(5, 5), size - Vector2(10, 10)), Color(Tema.OURO_ESCURO, 0.35), false, 1.0)


func _ao_redimensionar() -> void:
	queue_redraw()
	if _corpo:
		_corpo.vertical = size.x < 520.0


# ---------- Montagem ----------

func _montar() -> void:
	Tema.limpar(self)
	if g.is_empty() or Jogo.e.is_empty():
		return
	var e: Dictionary = Jogo.e
	var casa := Game.lanista_da_casa(e)
	var esp := str(casa.get("especialidade", ""))
	var extra := Game.extra_da_casa(e)
	var lut := Model.para_lutador(g, esp, extra)
	var stats: Dictionary = lut["stats"]
	var v := Tema.vbox(10)
	add_child(v)

	# Cabeçalho
	if mostrar_cabecalho:
		var cab := Tema.hbox(10)
		v.add_child(cab)
		var nome := Tema.rotulo(str(g["nome"]), 24, Tema.OURO, true)
		nome.autowrap_mode = TextServer.AUTOWRAP_OFF
		nome.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		nome.clip_text = true
		cab.add_child(nome)
		var cl := "Sem estilo" if g.get("semEstilo", false) else str(Model.classes()[g["classe"]]["nome"])
		var sub := Tema.rotulo("%s · Nível %d" % [cl, int(g["nivel"])], 16, Tema.CINZA)
		sub.autowrap_mode = TextServer.AUTOWRAP_OFF
		cab.add_child(sub)


	# Glória
	v.add_child(_faixa_gloria(e))

	# Corpo: atributos | derivados
	_corpo = BoxContainer.new()
	_corpo.vertical = size.x < 520.0 and size.x > 0.0
	_corpo.add_theme_constant_override("separation", 18)
	v.add_child(_corpo)
	var col_a := Tema.vbox(0)
	col_a.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col_a.size_flags_stretch_ratio = 1.55
	_corpo.add_child(col_a)
	var tem_palus := Game.tem_melhoria(e, "palus")
	for i in range(Model.ATRIBUTOS.size()):
		col_a.add_child(_linha_atributo(Model.ATRIBUTOS[i], int(stats[Model.ATRIBUTOS[i]]), tem_palus, e, i == 0))
	var col_d := Tema.vbox(6)
	col_d.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_corpo.add_child(col_d)
	_derivados(col_d, lut, int(stats["aura"]))
	_carga(col_d, esp, extra)


func _faixa_gloria(e: Dictionary) -> Control:
	var gl := int(g.get("gloria", 0))
	var prog := Model.progresso_gloria(gl)
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", Tema.caixa(Color("100b08"), COR_LINHA, 2, 1, 6))
	p.tooltip_text = "Glória do gladiador. Fama do ludus: %d." % Game.fama_do_ludus(e)
	var h := Tema.hbox(10)
	p.add_child(h)
	h.add_child(Glifo.novo("coroa", 24, Tema.OURO))
	var t := Tema.rotulo(str(prog["titulo"]), 18, Tema.OURO, true)
	t.autowrap_mode = TextServer.AUTOWRAP_OFF
	h.add_child(t)
	var meio := Control.new()
	meio.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(meio)
	var prox := int(prog["proximo"])
	if prox >= 0:
		var pr := Tema.rotulo("próximo título em %d" % prox, 14, Tema.CINZA)
		pr.autowrap_mode = TextServer.AUTOWRAP_OFF
		h.add_child(pr)
	var n := Tema.rotulo(str(gl), 22, Tema.OURO, true)
	n.autowrap_mode = TextServer.AUTOWRAP_OFF
	h.add_child(n)
	return p


func _dica_atributo(a: String) -> String:
	match a:
		"forca": return "Dano base +%s por ponto. Também aumenta a carga que ele aguenta." % _n(Combat.DANO_POR_FOR)
		"destreza": return "Chance de acerto +%s%% por ponto." % _n(Combat.ACERTO_POR_DES)
		"vitalidade": return "Vida +%d por ponto." % Combat.HP_POR_VIT
		"resistencia": return "Estamina +%d por ponto." % Combat.EST_POR_RES
		"inteligencia": return "Esquiva e defesa +%s%% por ponto." % _n(Combat.DEFESA_POR_INT)
		"aura": return "Cada ponto soma +%s%% de chance de bônus de Aura (máx %d%%)." % [_n(Game.AURA_CHANCE * 100.0), int(Game.AURA_CHANCE_MAX * 100.0)]
	return ""


static func _n(x: float) -> String:
	return str(snappedf(x, 0.01))


func _linha_atributo(a: String, valor: int, tem_palus: bool, e: Dictionary, primeira: bool) -> Control:
	var treino := int(g["treino"].get(a, 0))
	var cor: Color = Tema.COR_ATRIBUTO[a]
	var linha := PanelContainer.new()
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0, 0, 0, 0)
	normal.border_color = COR_LINHA
	normal.border_width_bottom = 1
	if primeira:
		normal.border_width_top = 1
	normal.content_margin_top = 5
	normal.content_margin_bottom = 5
	normal.content_margin_left = 6
	normal.content_margin_right = 4
	var destaque := normal.duplicate() as StyleBoxFlat
	destaque.bg_color = Color(Tema.OURO, 0.08)
	destaque.border_width_left = 3
	destaque.border_color = Tema.OURO
	destaque.border_width_bottom = 1
	linha.add_theme_stylebox_override("panel", normal)
	linha.tooltip_text = "%s: %d\nTreino %d/%d. %s" % [Model.NOME_ATRIBUTO[a], valor, treino, Game.TREINO_MAXIMO, _dica_atributo(a)]
	linha.mouse_entered.connect(func() -> void: linha.add_theme_stylebox_override("panel", destaque))
	linha.mouse_exited.connect(func() -> void: linha.add_theme_stylebox_override("panel", normal))
	var h := Tema.hbox(8)
	linha.add_child(h)
	h.add_child(Glifo.novo(a, 22, cor))
	var nome := Tema.rotulo(str(Model.NOME_ATRIBUTO[a]), 17, Tema.AREIA)
	nome.autowrap_mode = TextServer.AUTOWRAP_OFF
	nome.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nome.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(nome)
	# caixinha de valor com a seta (decorativa) à esquerda
	h.add_child(Glifo.novo("seta_esq", 12, Color(Tema.OURO_ESCURO, 0.7)))
	var cx := PanelContainer.new()
	cx.add_theme_stylebox_override("panel", Tema.caixa(COR_CAIXA, COR_LINHA, 2, 1, 1))
	cx.custom_minimum_size = Vector2(44, 0)
	cx.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var lv := Tema.rotulo(str(valor), 19, cor)
	lv.autowrap_mode = TextServer.AUTOWRAP_OFF
	lv.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lv.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cx.add_child(lv)
	h.add_child(cx)
	h.add_child(_botao_mais(a, treino, tem_palus, e))
	return linha


func _botao_mais(a: String, treino: int, tem_palus: bool, e: Dictionary) -> Control:
	var b := Button.new()
	b.focus_mode = Control.FOCUS_NONE
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.add_theme_font_size_override("font_size", 13)
	b.custom_minimum_size = Vector2(150, 28)
	b.alignment = HORIZONTAL_ALIGNMENT_RIGHT
	b.add_theme_stylebox_override("normal", _sb_botao(Color("3a2a14"), Tema.OURO_ESCURO))
	b.add_theme_stylebox_override("hover", _sb_botao(Color("4a3618"), Tema.OURO))
	b.add_theme_stylebox_override("pressed", _sb_botao(Color("6a1414"), Tema.OURO))
	b.add_theme_stylebox_override("disabled", _sb_botao(Color("181010"), Color("2a1c16")))
	b.add_theme_color_override("font_color", Tema.OURO)
	var custo := Game.custo_treino(e, g, a)
	var motivo := ""
	if not tem_palus:
		motivo = "Construa o palus para treinar."
	elif not g["vivo"]:
		motivo = "Gladiador morto."
	elif treino >= Game.TREINO_MAXIMO:
		motivo = "Treino máximo atingido neste atributo."
	elif int(e["ouro"]) < custo:
		motivo = "Faltam %d de ouro." % (custo - int(e["ouro"]))
	elif int(e["energia"]) < 1:
		motivo = "Sem energia neste turno."
	if not tem_palus:
		b.text = "sem palus"
	elif treino >= Game.TREINO_MAXIMO:
		b.text = "máximo"
	else:
		b.text = "%d ouro · 1 energia" % custo
	b.disabled = motivo != ""
	b.tooltip_text = motivo if motivo != "" else "Treinar %s: %d de ouro e 1 de energia." % [Model.NOME_ATRIBUTO[a], custo]
	var gl := Glifo.novo("mais", 16, Tema.OURO if not b.disabled else Color("6b5a4a"))
	gl.position = Vector2(7, 6)
	gl.size = Vector2(16, 16)
	b.add_child(gl)
	var id := str(g["id"])
	b.pressed.connect(func() -> void:
		if Jogo.resultado(Game.treinar(Jogo.e, id, a)):
			Som.sfx("sfx/moeda"))
	return b


func _sb_botao(fundo: Color, borda: Color) -> StyleBoxFlat:
	var sb := Tema.caixa(fundo, borda, 3, 1, 2)
	sb.content_margin_left = 26
	sb.content_margin_right = 8
	return sb


func _derivados(c: VBoxContainer, lut: Dictionary, aura: int) -> void:
	var t := Tema.rotulo("Estatísticas", 16, Tema.OURO_ESCURO, true)
	t.autowrap_mode = TextServer.AUTOWRAP_OFF
	c.add_child(t)
	var gr := GridContainer.new()
	gr.columns = 2
	gr.add_theme_constant_override("h_separation", 14)
	gr.add_theme_constant_override("v_separation", 4)
	c.add_child(gr)
	var bonus_aura := minf(Game.AURA_CHANCE_MAX, Game.AURA_CHANCE * float(aura)) * 100.0
	var linhas := [
		["Vida", str(int(lut["hpMax"])), ""],
		["Estamina", str(int(lut["estMax"])), ""],
		["Dano base", "%.1f" % Combat.dano_base(lut), ""],
		["Chance de acerto", "%d%%" % int(round(Combat.chance_acerto(lut))), ""],
		["Esquiva e defesa", "%d%%" % int(round(Combat.chance_defesa(lut))), ""],
		["Bônus de Aura", "%s%%" % (str(int(bonus_aura)) if is_equal_approx(bonus_aura, floorf(bonus_aura)) else _n(bonus_aura)), "bom" if bonus_aura > 0.0 else ""],
	]
	for l in linhas:
		var a := Tema.rotulo(l[0], 16, Tema.CINZA)
		a.autowrap_mode = TextServer.AUTOWRAP_OFF
		a.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		gr.add_child(a)
		var b := Tema.rotulo(l[1], 17, Tema.VERDE if l[2] == "bom" else Tema.AREIA)
		b.autowrap_mode = TextServer.AUTOWRAP_OFF
		b.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		gr.add_child(b)


func _carga(c: VBoxContainer, esp: String, extra: Dictionary) -> void:
	var atual := Model.carga_atual(g)
	var maxima := Model.carga_maxima(g, esp, extra)
	var faixa := Model.faixa_carga(atual, maxima)
	var cor: Color = COR_FAIXA[faixa]
	c.add_child(Tema.espaco(2))
	var h := Tema.hbox(6)
	c.add_child(h)
	var t := Tema.rotulo("Carga %d/%d" % [atual, maxima], 16, Tema.CINZA)
	t.autowrap_mode = TextServer.AUTOWRAP_OFF
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(t)
	var f := Tema.rotulo(str(NOME_FAIXA[faixa]), 16, cor, true)
	f.autowrap_mode = TextServer.AUTOWRAP_OFF
	h.add_child(f)
	var barra := BarraCarga.new()
	barra.fracao = float(atual) / float(maxi(1, maxima))
	barra.cor = cor
	c.add_child(barra)
	var d: float = Combat.FAIXA_DEFESA[faixa]
	var r: int = Combat.FAIXA_REGEN[faixa]
	var tip := "Equipamento vestido: %d de %d de carga." % [atual, maxima]
	if d != 0.0 or r != 0:
		tip += "\n%s: defesa %s%d%%, regeneração de estamina %s%d." % [NOME_FAIXA[faixa], "+" if d > 0 else "", int(d), "+" if r > 0 else "", r]
	else:
		tip += "\nNormal: sem bônus nem penalidade."
	tip += "\nLeve (até 30%) dá bônus; Pesado (acima de 70%) e Sobrecarga dão penalidade."
	c.tooltip_text = tip
	barra.tooltip_text = tip


## Barra de carga com marcas em 30% e 70%.
class BarraCarga extends Control:
	var fracao := 0.0
	var cor := Color.WHITE
	func _init() -> void:
		custom_minimum_size = Vector2(0, 12)
		mouse_filter = Control.MOUSE_FILTER_PASS
	func _draw() -> void:
		var r := Rect2(Vector2.ZERO, size)
		draw_rect(r, Color("0a0705"))
		draw_rect(Rect2(0, 0, size.x * clampf(fracao, 0.0, 1.0), size.y), cor)
		draw_rect(r, Color("3a2a1a"), false, 1.0)
		for m in [0.3, 0.7]:
			var x := roundf(size.x * m)
			draw_line(Vector2(x, 0), Vector2(x, size.y), Color(0, 0, 0, 0.8), 2.0)
			draw_line(Vector2(x, 0), Vector2(x, size.y), Color(Tema.OURO, 0.55), 1.0)
