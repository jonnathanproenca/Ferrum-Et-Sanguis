class_name TelaLudus
extends Tela
## Aba "ludus": cena do morro, cartões dos gladiadores (treino, estilo, tratamento, venda, equipamento) e registro.

const ABREV := {"forca": "FOR", "agilidade": "AGI", "vitalidade": "VIT", "sorte": "SOR"}
const COR_ATRIBUTO := {"forca": Color("c0553a"), "agilidade": Color("7fbf6a"), "vitalidade": Color("d49a3a"), "sorte": Color("6aa6d8")}
const NOME_CONDICAO := {"jovem": "Jovem", "maduro": "Maduro", "cicatrizado": "Cicatrizado"}
const ESCALA_STAT := 24.0
const LARGURA_CARTA := 600

var _raiz: VBoxContainer
var _caixa_cena: Control
var _cena: CenaLudus
var _fim: PanelContainer
var _l_fim_sub: Label
var _l_fim_stats: Label
var _l_contagem: Label
var _regras: HFlowContainer
var _grade: GridContainer
var _registro: VBoxContainer
var _cartas := {}  ## id do gladiador -> Carta


func construir() -> void:
	_raiz = rolagem(12)
	_raiz.resized.connect(_ao_redimensionar)
	resized.connect(_ao_redimensionar)

	# Cena do morro (altura proporcional à largura 1024:572, limitada a ~45% da altura da tela)
	_caixa_cena = Control.new()
	_caixa_cena.clip_contents = true
	_caixa_cena.custom_minimum_size = Vector2(0, 300)
	_raiz.add_child(_caixa_cena)
	_cena = CenaLudus.new()
	_cena.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_caixa_cena.add_child(_cena)

	# Fim de jogo
	_fim = Tema.painel(Color("2a0f0c"), Tema.OURO_ESCURO)
	var sb := Tema.caixa(Color("2a0f0c"), Tema.OURO, 10, 3, 22)
	sb.shadow_color = Color(0.72, 0.16, 0.1, 0.45)
	sb.shadow_size = 18
	_fim.add_theme_stylebox_override("panel", sb)
	_fim.visible = false
	_raiz.add_child(_fim)
	var vf := Tema.vbox(10)
	_fim.add_child(vf)
	var t := Tema.titulo("Fim de jogo", 44)
	t.add_theme_color_override("font_color", Tema.SANGUE_CLARO)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vf.add_child(t)
	_l_fim_sub = Tema.rotulo("", 22, Tema.AREIA)
	_l_fim_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vf.add_child(_l_fim_sub)
	_l_fim_stats = Tema.rotulo("", 18, Tema.CINZA)
	_l_fim_stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vf.add_child(_l_fim_stats)
	var cb := CenterContainer.new()
	vf.add_child(cb)
	var b := Tema.botao("Voltar ao menu", "primario", 22)
	b.custom_minimum_size = Vector2(240, 52)
	b.pressed.connect(func(): Jogo.navegar.emit("menu"))
	cb.add_child(b)

	# Cabeçalho
	var cab := Tema.hbox(12)
	_raiz.add_child(cab)
	_l_contagem = Tema.rotulo("", 22, Tema.OURO, true)
	_l_contagem.autowrap_mode = TextServer.AUTOWRAP_OFF
	cab.add_child(_l_contagem)
	_regras = HFlowContainer.new()
	_regras.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_regras.alignment = FlowContainer.ALIGNMENT_END
	_regras.add_theme_constant_override("h_separation", 6)
	cab.add_child(_regras)

	# Cartões
	_grade = GridContainer.new()
	_grade.columns = 2
	_grade.add_theme_constant_override("h_separation", 14)
	_grade.add_theme_constant_override("v_separation", 14)
	_raiz.add_child(_grade)

	# Registro
	_raiz.add_child(Tema.espaco(4))
	var pr := Tema.painel(Color("181010"), Tema.BORDA)
	_raiz.add_child(pr)
	var vr := Tema.vbox(4)
	pr.add_child(vr)
	vr.add_child(Tema.rotulo("Registro", 20, Tema.OURO, true))
	_registro = Tema.vbox(3)
	vr.add_child(_registro)
	call_deferred("_ao_redimensionar")


func _ao_redimensionar() -> void:
	if _raiz == null:
		return
	var w: float = _raiz.size.x
	if w <= 0.0:
		return
	var altura: float = minf(w * 572.0 / 1024.0, size.y * 0.88)
	_caixa_cena.custom_minimum_size.y = maxf(120.0, altura)
	_grade.columns = clampi(int(w / LARGURA_CARTA), 1, 3)


func ao_mostrar() -> void:
	super.ao_mostrar()
	call_deferred("_ao_redimensionar")


func atualizar() -> void:
	var e: Dictionary = Jogo.e
	var casa := Game.lanista_da_casa(e)
	var fim := Game.game_over(e)
	_fim.visible = fim
	if fim:
		_l_fim_sub.text = "O ludus de %s ficou sem gladiadores e sem ouro para recrutar outro." % casa.get("nome", "")
		_l_fim_stats.text = "%d vitórias em %d turnos." % [int(e["vitoriasTotais"]), int(e["turno"])]

	_l_contagem.text = "Gladiadores: %d/%d" % [e["gladiadores"].size(), Game.capacidade_ludus(e)]

	# Regras: o que falta construir
	Tema.limpar(_regras)
	for r in [["palus", "Treino: construa os palus."], ["enfermaria", "Ferido: construa a enfermaria."], ["armaria", "Equipamento: construa a armaria."]]:
		if not Game.tem_melhoria(e, r[0]):
			_regras.add_child(_chip(r[1], Color("2a1c16"), Tema.BORDA, Tema.CINZA, 15))

	# Cartões: campeões primeiro (ordem estável)
	var ordenados: Array = e["gladiadores"].filter(func(g): return g["campeao"])
	ordenados.append_array(e["gladiadores"].filter(func(g): return not g["campeao"]))
	var vivos_ids := {}
	for g in ordenados:
		vivos_ids[g["id"]] = true
	for id in _cartas.keys():
		if not vivos_ids.has(id):
			var c: Control = _cartas[id]
			_grade.remove_child(c)
			c.queue_free()
			_cartas.erase(id)
	for i in range(ordenados.size()):
		var g: Dictionary = ordenados[i]
		var carta: Carta = _cartas.get(g["id"])
		if carta == null:
			carta = Carta.new()
			_cartas[g["id"]] = carta
			_grade.add_child(carta)
		_grade.move_child(carta, i)
		carta.atualizar(g)

	# Registro (8 últimos)
	Tema.limpar(_registro)
	var n := 0
	for l in e["log"]:
		if n >= 8:
			break
		var lb := Tema.rotulo("•  " + str(l), 16, Tema.AREIA if n == 0 else Tema.CINZA)
		_registro.add_child(lb)
		n += 1
	if n == 0:
		_registro.add_child(Tema.rotulo("Nada a registrar ainda.", 16, Tema.CINZA))


# ---------- Helpers estáticos ----------

static func _chip(texto: String, fundo: Color, borda: Color, cor_texto: Color, tam: int = 14, titulo: bool = false) -> PanelContainer:
	var p := PanelContainer.new()
	var sb := Tema.caixa(fundo, borda, 10, 1, 1)
	sb.content_margin_left = 8
	sb.content_margin_right = 8
	p.add_theme_stylebox_override("panel", sb)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var l := Tema.rotulo(texto, tam, cor_texto, titulo)
	l.autowrap_mode = TextServer.AUTOWRAP_OFF
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_child(l)
	return p


static func cor_qualidade(q: int) -> Color:
	return Color(Model.COR_QUALIDADE[clampi(q, 0, Model.QUALIDADE_MAX)])


static func fmt_bonus(b: Dictionary) -> String:
	var partes: Array = []
	for a in Model.ATRIBUTOS:
		var v: int = int(b.get(a, 0))
		if v != 0:
			partes.append("%s %s%d" % [ABREV[a], "+" if v > 0 else "", v])
	return ", ".join(partes) if partes.size() > 0 else "sem bônus"


static func _arquivo_basico(slot: String, classe: String) -> String:
	var meio := classe == "murmilo" or classe == "samnita"
	match slot:
		"arma":
			return "tridente" if classe == "retiario" else ("sica" if classe == "tracio" else "gladio")
		"acessorio":
			if classe == "retiario": return "rede"
			if classe == "tracio": return "escudo_redondo_pequeno"
			if classe == "samnita": return "escudo_oval"
			return "escudo_quadrado"
		"elmo":
			if classe == "murmilo": return "elmo_murmilo"
			if classe == "retiario": return "galero"
			if classe == "tracio": return "capacete_frigio"
			return "elmo_viseira"
		"peito":
			return "peito_leve"
		"pe":
			return "bota_legionaria" if meio else "sandalia"
	return "perneira_couro" if meio else "faixa_coxa"


## Ícone do item (arquivo de assets/itens) com moldura na cor da qualidade. item vazio -> moldura tracejada.
static func icone_item(item: Dictionary, tam: int = 44) -> Control:
	var p := PanelContainer.new()
	p.custom_minimum_size = Vector2(tam, tam)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := StyleBoxFlat.new()
	sb.set_corner_radius_all(7)
	sb.set_content_margin_all(3)
	if item.is_empty():
		sb.bg_color = Color(0, 0, 0, 0.25)
		sb.border_color = Color(0.95, 0.82, 0.54, 0.3)
		sb.set_border_width_all(2)
		p.add_theme_stylebox_override("panel", sb)
		return p
	var cor := cor_qualidade(int(item["qualidade"]))
	sb.bg_color = Color(0, 0, 0, 0.45)
	sb.border_color = cor
	sb.set_border_width_all(2)
	if int(item["qualidade"]) >= 3:
		sb.shadow_color = Color(cor, 0.4)
		sb.shadow_size = 5
	p.add_theme_stylebox_override("panel", sb)
	var arq: String = _arquivo_basico(item["slot"], item["classes"][0]) if item.get("basico", false) else str(Model.separar_id(item["id"])["base"])
	var tr := TextureRect.new()
	tr.texture = Tema.textura("assets/itens/%s.png" % arq)
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_child(tr)
	p.tooltip_text = "%s · %s" % [item["nome"], Model.QUALIDADES[int(item["qualidade"])]]
	return p


## Barra fina de atributo.
class BarraStat extends Control:
	var valor := 0.0
	var maximo := 24.0
	var cor := Color.WHITE
	func _init() -> void:
		custom_minimum_size = Vector2(0, 6)
		mouse_filter = Control.MOUSE_FILTER_IGNORE
	func _draw() -> void:
		var r := Rect2(Vector2.ZERO, size)
		draw_rect(r, Color(0, 0, 0, 0.5))
		var f := clampf(valor / maximo, 0.0, 1.0)
		draw_rect(Rect2(0, 0, size.x * f, size.y), cor)
		draw_rect(r, Color(1, 1, 1, 0.08), false, 1.0)


## Cartão de um gladiador. Reconstrói o conteúdo a cada atualização, preservando o que é estado de UI.
class Carta extends PanelContainer:
	var g: Dictionary = {}
	var aberto := false
	var sel_estilo := 0
	var sel_atributo := 0
	var sel_classe := 0
	var _slots_box: Control
	var _btn_eq: Button
	var _ult_classe := ""

	func _init() -> void:
		size_flags_horizontal = Control.SIZE_EXPAND_FILL
		size_flags_vertical = Control.SIZE_SHRINK_BEGIN

	func atualizar(novo: Dictionary) -> void:
		g = novo
		if g["classe"] != _ult_classe:
			sel_classe = 0
			_ult_classe = g["classe"]
		Tema.limpar(self)
		var e: Dictionary = Jogo.e
		var campeao: bool = g["campeao"]
		var morto: bool = not g["vivo"]
		var sb := Tema.caixa(Color("211612"), Tema.OURO if campeao else (Color("c24a3a") if g["lenda"] else Tema.BORDA), 10, 2 if (campeao or g["lenda"]) else 1, 12)
		if campeao:
			sb.shadow_color = Color(0.95, 0.82, 0.54, 0.22)
			sb.shadow_size = 12
		add_theme_stylebox_override("panel", sb)
		modulate = Color(1, 1, 1, 0.5) if morto else Color.WHITE

		var v := Tema.vbox(8)
		add_child(v)
		var topo := Tema.hbox(14)
		v.add_child(topo)
		topo.add_child(_thumb(e))
		topo.add_child(_info(e))
		_equipamento(v, e)

	# --- miniatura com moldura da melhor peça ---
	func _thumb(_e: Dictionary) -> Control:
		var q := 0
		if not g.get("semEstilo", false):
			for sl in Model.SLOTS:
				q = maxi(q, Model.qualidade_de(g["equipamento"][sl]))
		var cor := Color(0.95, 0.82, 0.54, 0.9) if g["campeao"] else (TelaLudus.cor_qualidade(q) if q > 0 else Tema.BORDA)
		var m := PanelContainer.new()
		var sb := Tema.caixa(Color(0.08, 0.05, 0.04, 0.85), cor, 10, 2 if (q > 0 or g["campeao"]) else 1, 6)
		if q > 0 or g["campeao"]:
			sb.shadow_color = Color(cor, 0.35)
			sb.shadow_size = 9
		m.add_theme_stylebox_override("panel", sb)
		m.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		var c := CenterContainer.new()
		c.custom_minimum_size = Vector2(168, 190)
		m.add_child(c)
		var spr := Sprites.controle_gladiador(g, 180.0)
		spr.custom_minimum_size = Vector2(168, 186)
		c.add_child(spr)
		return m

	func _info(e: Dictionary) -> Control:
		var classe: Dictionary = Model.classes()[g["classe"]]
		var sem: bool = g.get("semEstilo", false)
		var casa := Game.lanista_da_casa(e)
		var v := Tema.vbox(5)
		v.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		# Título + selos
		var t := HFlowContainer.new()
		t.add_theme_constant_override("h_separation", 8)
		t.add_theme_constant_override("v_separation", 2)
		v.add_child(t)
		var nome := Tema.rotulo(str(g["nome"]), 26, Tema.OURO, true)
		nome.autowrap_mode = TextServer.AUTOWRAP_OFF
		t.add_child(nome)
		var est := Tema.rotulo("Sem estilo" if sem else str(classe["nome"]), 17, Tema.OCRE)
		est.autowrap_mode = TextServer.AUTOWRAP_OFF
		t.add_child(est)
		if g["campeao"]:
			t.add_child(TelaLudus._chip("Campeão", Tema.OURO, Tema.OURO_ESCURO, Color("2a1a10"), 14, true))
		if g["lenda"]:
			t.add_child(TelaLudus._chip("Lenda", Color("c24a3a"), Color("e0705a"), Color.WHITE, 14, true))
		if not g["vivo"]:
			t.add_child(TelaLudus._chip("morto", Color("222222"), Color("555555"), Tema.CINZA, 14))

		# Origem, terra/aparência, nível
		var origem := "Campeão do ludus" if g["campeao"] else ("Livre" if g["origem"] == "livre" else "Escravo")
		var meio := _caracteristicas() if sem else _nome_aparencia()
		v.add_child(Tema.rotulo("%s · %s · Nível %d" % [origem, meio, int(g["nivel"])], 16, Tema.OCRE))

		# Vitórias / Poço / Derrotas
		var cs := HFlowContainer.new()
		cs.add_theme_constant_override("h_separation", 6)
		v.add_child(cs)
		cs.add_child(TelaLudus._chip("Vitórias %d" % int(g["vitorias"]), Color("1f2a18"), Color("4a6a38"), Tema.VERDE, 14))
		cs.add_child(TelaLudus._chip("Poço %d" % int(g["vitoriasPoco"]), Color("2a2216"), Color("6a5230"), Tema.OURO_ESCURO, 14))
		cs.add_child(TelaLudus._chip("Derrotas %d" % int(g["derrotas"]), Color("2a1414"), Color("6a3030"), Color("d88a7a"), 14))

		# Passiva
		var passiva: Label
		if sem:
			passiva = Tema.rotulo("Sem estilo: não luta nas arenas até você definir como ele vai lutar. O kit básico vem junto.", 15, Tema.AREIA)
		else:
			passiva = Tema.rotulo("%s: %s" % [classe["passivaNome"], classe["passivaDescricao"]], 15, Tema.AREIA)
		passiva.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		passiva.modulate = Color(1, 1, 1, 0.9)
		v.add_child(passiva)

		# Atributos finais
		var stats := Model.stats_do_gladiador(g, str(casa.get("especialidade", "")), Game.extra_da_casa(e))
		var hs := Tema.hbox(10)
		v.add_child(hs)
		for a in Model.ATRIBUTOS:
			var col := Tema.vbox(2)
			col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			var hl := Tema.hbox(5)
			var la := Tema.rotulo(TelaLudus.ABREV[a], 14, Tema.OCRE)
			la.autowrap_mode = TextServer.AUTOWRAP_OFF
			hl.add_child(la)
			var lv := Tema.rotulo(str(stats[a]), 22, Tema.AREIA)
			lv.autowrap_mode = TextServer.AUTOWRAP_OFF
			hl.add_child(lv)
			col.add_child(hl)
			var br := BarraStat.new()
			br.valor = float(stats[a])
			br.maximo = TelaLudus.ESCALA_STAT
			br.cor = TelaLudus.COR_ATRIBUTO[a]
			col.add_child(br)
			col.tooltip_text = "%s: %d (treino %d/%d)" % [Model.NOME_ATRIBUTO[a], int(stats[a]), int(g["treino"][a]), Game.TREINO_MAXIMO]
			hs.add_child(col)

		# Efeitos persistentes do Poço
		if g["efeitos"].size() > 0:
			var fe := HFlowContainer.new()
			fe.add_theme_constant_override("h_separation", 6)
			v.add_child(fe)
			for ef in g["efeitos"]:
				fe.add_child(TelaLudus._chip("%s %d" % [Game.NOME_EFEITO[ef["tipo"]], int(ef["severidade"])], Color("3a1010"), Color("aa3333"), Color("ffb3a0"), 14))

		if g["vivo"]:
			_acoes(v, e)
		_venda(v, e)
		return v

	func _caracteristicas() -> String:
		var terra: String = str(Model.terra_por_id(g["terra"]).get("nome", g["terra"]))
		var partes: Array = [terra]
		if g.has("tendencia"):
			partes.append("Tendência: %s" % Model.NOME_ATRIBUTO[g["tendencia"]])
		if g.has("condicao"):
			partes.append(NOME_CONDICAO[g["condicao"]])
		return " · ".join(partes)

	func _nome_aparencia() -> String:
		var t := Model.terra_por_id(g["terra"])
		if t.is_empty():
			return ""
		return "%s (%s)" % [t["looks"][int(g["look"])]["nome"], t["nome"]]

	# --- ações ---
	func _opcoes(valores: Array, nomes: Array, sel: int, ao_escolher: Callable) -> OptionButton:
		var ob := OptionButton.new()
		ob.focus_mode = Control.FOCUS_NONE
		ob.custom_minimum_size = Vector2(130, 40)
		ob.add_theme_font_size_override("font_size", 17)
		for i in range(valores.size()):
			ob.add_item(nomes[i])
			ob.set_item_metadata(i, valores[i])
		ob.selected = clampi(sel, 0, valores.size() - 1)
		ob.item_selected.connect(ao_escolher)
		return ob

	func _nota(texto: String) -> Label:
		var l := Tema.rotulo(texto, 15, Tema.CINZA)
		l.autowrap_mode = TextServer.AUTOWRAP_OFF
		return l

	func _linha() -> HFlowContainer:
		var h := HFlowContainer.new()
		h.add_theme_constant_override("h_separation", 6)
		h.add_theme_constant_override("v_separation", 6)
		return h

	func _acoes(v: VBoxContainer, e: Dictionary) -> void:
		var id: String = g["id"]
		if g.get("semEstilo", false):
			var h := _linha()
			v.add_child(h)
			var ids: Array = Model.CLASSES_IDS.duplicate()
			var nomes: Array = ids.map(func(c): return Model.classes()[c]["nome"])
			var par := Tema.hbox(4)
			h.add_child(par)
			par.add_child(_opcoes(ids, nomes, sel_estilo, func(i): sel_estilo = i))
			var b := Tema.botao("Definir estilo (grátis)", "primario", 17)
			b.pressed.connect(func():
				Jogo.resultado(Game.escolher_estilo(Jogo.e, id, Model.CLASSES_IDS[sel_estilo])))
			par.add_child(b)
		var h2 := _linha()
		v.add_child(h2)
		if Game.tem_melhoria(e, "palus"):
			var at: Array = Model.ATRIBUTOS.duplicate()
			var nomes_at: Array = at.map(func(a): return "%s · %d/%d" % [Model.NOME_ATRIBUTO[a], int(g["treino"][a]), Game.TREINO_MAXIMO])
			var par_t := Tema.hbox(4)
			h2.add_child(par_t)
			par_t.add_child(_opcoes(at, nomes_at, sel_atributo, func(i): sel_atributo = i))
			var bt := Tema.botao("Treinar", "normal", 17)
			bt.tooltip_text = "%d de ouro e 1 de energia." % Game.PRECO_TREINO
			bt.pressed.connect(func(): Jogo.resultado(Game.treinar(Jogo.e, id, Model.ATRIBUTOS[sel_atributo])))
			par_t.add_child(bt)
		else:
			h2.add_child(_nota("Treino: construa os palus."))
		if not (g["campeao"] or g.get("semEstilo", false)):
			var cl: Array = Model.CLASSES_IDS.filter(func(c): return c != g["classe"])
			var nomes_cl: Array = cl.map(func(c): return Model.classes()[c]["nome"])
			var par_c := Tema.hbox(4)
			h2.add_child(par_c)
			par_c.add_child(_opcoes(cl, nomes_cl, sel_classe, func(i): sel_classe = i))
			var bc := Tema.botao("Trocar estilo", "normal", 17)
			bc.tooltip_text = "%d de ouro e %d de energia." % [Game.preco_troca_estilo(e, g), 2 if g["origem"] == "livre" else 1]
			bc.pressed.connect(func(): Jogo.resultado(Game.trocar_classe(Jogo.e, id, cl[mini(sel_classe, cl.size() - 1)])))
			par_c.add_child(bc)
		if g["efeitos"].size() > 0:
			if Game.tem_melhoria(e, "enfermaria"):
				var btr := Tema.botao("Tratar (%d ouro)" % Model.custo_tratamento(g), "primario", 17)
				btr.pressed.connect(func(): Jogo.resultado(Game.tratar(Jogo.e, id)))
				h2.add_child(btr)
			else:
				h2.add_child(_nota("Ferido: construa a enfermaria."))
		if h2.get_child_count() == 0:
			v.remove_child(h2)
			h2.queue_free()

	func _venda(v: VBoxContainer, e: Dictionary) -> void:
		var id: String = g["id"]
		if g["campeao"]:
			v.add_child(Tema.rotulo("O campeão não é vendido nem dispensado.", 15, Tema.CINZA))
		elif g["lenda"]:
			var lib = Game.regras_de(e)["liberdade"]
			var txt := "Lenda: nunca deixa o ludus." if lib == null else "Lenda: é libertado após %d lutas como lenda (%d feitas)." % [int(lib), int(g.get("lutasComoLenda", 0))]
			v.add_child(Tema.rotulo(txt, 15, Tema.CINZA))
		elif g["vivo"] and g["origem"] == "escravo":
			var valor := maxi(20, Model.jsround(float(Model.preco_gladiador(g)) * float(Game.regras_de(e)["precos"]) / 2.0))
			var h := _linha()
			v.add_child(h)
			var b := Tema.botao("Vender · %d ouro" % valor, "ouro", 17)
			b.pressed.connect(func():
				if Jogo.resultado(Game.vender_gladiador(Jogo.e, id)):
					Som.sfx("sfx/moeda"))
			h.add_child(b)

	# --- equipamento ---
	func _opcoes_slot(e: Dictionary, slot: String) -> Array:
		var ids: Array = []
		for id in e["inventario"]:
			var item := Model.item_por_id(id)
			if not item.is_empty() and item["slot"] == slot and g["classe"] in item["classes"] and not ids.has(id):
				ids.append(id)
		var atual = g["equipamento"][slot]
		if atual != null and not ids.has(atual):
			ids.append(atual)
		return ids.map(func(i): return Model.item_por_id(i))

	func _equipamento(v: VBoxContainer, e: Dictionary) -> void:
		if g.get("semEstilo", false):
			v.add_child(Tema.rotulo("Equipamento: defina o estilo primeiro.", 15, Tema.CINZA))
			return
		if not Game.tem_melhoria(e, "armaria"):
			v.add_child(Tema.rotulo("Equipamento: construa a armaria.", 15, Tema.CINZA))
			return
		v.add_child(HSeparator.new())
		var cab := Tema.hbox(10)
		v.add_child(cab)
		_btn_eq = Tema.botao("", "normal", 17)
		_btn_eq.pressed.connect(_alternar)
		cab.add_child(_btn_eq)
		# prévia dos itens equipados
		var prev := Tema.hbox(4)
		prev.alignment = BoxContainer.ALIGNMENT_BEGIN
		cab.add_child(prev)
		for slot in Model.SLOTS:
			var a = g["equipamento"][slot]
			prev.add_child(TelaLudus.icone_item(Model.item_por_id(a) if a != null else {}, 30))

		var gr := GridContainer.new()
		gr.columns = 2
		gr.add_theme_constant_override("h_separation", 12)
		gr.add_theme_constant_override("v_separation", 10)
		_slots_box = gr
		v.add_child(gr)
		for slot in Model.SLOTS:
			gr.add_child(_slot(e, slot))
		_slots_box.visible = aberto
		_atualizar_texto_toggle()

	func _alternar() -> void:
		aberto = not aberto
		if _slots_box:
			_slots_box.visible = aberto
		_atualizar_texto_toggle()

	func _atualizar_texto_toggle() -> void:
		if _btn_eq:
			_btn_eq.text = "Equipamento · " + ("ocultar" if aberto else "mostrar")

	func _slot(e: Dictionary, slot: String) -> Control:
		var atual = g["equipamento"][slot]
		var item_atual := Model.item_por_id(atual) if atual != null else {}
		var v := Tema.vbox(4)
		v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var topo := Tema.hbox(8)
		v.add_child(topo)
		var ic := TelaLudus.icone_item(item_atual, 46)
		ic.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		topo.add_child(ic)
		var info := Tema.vbox(0)
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		topo.add_child(info)
		info.add_child(Tema.rotulo(Model.NOME_SLOT[slot], 14, Tema.OCRE))
		if item_atual.is_empty():
			info.add_child(Tema.rotulo("vazio", 14, Tema.CINZA))
		else:
			var q: int = int(item_atual["qualidade"])
			var ln := Tema.rotulo("%s · %s" % [item_atual["nome"], Model.QUALIDADES[q]], 16, TelaLudus.cor_qualidade(q))
			ln.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			info.add_child(ln)
			info.add_child(Tema.rotulo(TelaLudus.fmt_bonus(item_atual["bonus"]), 14, Tema.CINZA))
		var opcoes := _opcoes_slot(e, slot)
		var ob := OptionButton.new()
		ob.focus_mode = Control.FOCUS_NONE
		ob.fit_to_longest_item = false
		ob.clip_text = true
		ob.add_theme_font_size_override("font_size", 15)
		ob.custom_minimum_size = Vector2(120, 34)
		ob.add_item("— vazio —")
		ob.set_item_metadata(0, "")
		var sel := 0
		for i in range(opcoes.size()):
			var it: Dictionary = opcoes[i]
			var peso := " (%s)" % it["peso"] if it.get("peso") else ""
			var qtxt := " [%s]" % Model.QUALIDADES[int(it["qualidade"])] if int(it["qualidade"]) > 0 else ""
			ob.add_item("%s%s%s · %s" % [it["nome"], qtxt, peso, TelaLudus.fmt_bonus(it["bonus"])])
			ob.set_item_metadata(i + 1, it["id"])
			ob.set_item_icon(i + 1, null)
			if atual != null and it["id"] == atual:
				sel = i + 1
		ob.selected = sel
		var gid: String = g["id"]
		ob.item_selected.connect(func(idx: int):
			var item_id: String = str(ob.get_item_metadata(idx))
			if not Jogo.resultado(Game.equipar(Jogo.e, gid, slot, item_id)):
				atualizar(g))
		v.add_child(ob)
		return v
