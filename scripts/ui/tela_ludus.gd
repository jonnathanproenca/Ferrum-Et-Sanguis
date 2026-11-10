class_name TelaLudus
extends Tela
## Aba "ludus": cena do morro, cartões compactos dos gladiadores (estilo, tratamento, venda; ficha e equipamento na modal) e registro.

const NOME_CONDICAO := {"jovem": "Jovem", "maduro": "Maduro", "cicatrizado": "Cicatrizado"}
const ESCALA_STAT := 24.0
const LARGURA_CARTA := 600

var _raiz: VBoxContainer
var _caixa_cena: Control
var _cena: Control
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
	_caixa_cena.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_caixa_cena.custom_minimum_size = Vector2(0, 300)
	_raiz.add_child(_caixa_cena)
	_criar_cena()

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


func _criar_cena() -> void:
	if _cena != null:
		_caixa_cena.remove_child(_cena)
		_cena.queue_free()
	_cena = CenaLudus2.new()
	_cena.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_caixa_cena.add_child(_cena)


func _ao_redimensionar() -> void:
	if _raiz == null:
		return
	var w: float = _raiz.size.x
	if w <= 0.0:
		return
	var cw: float = minf(w, 1180.0)
	# em telas baixas (celular na horizontal) a cena cabe inteira na área visível; os cartões ficam abaixo, na rolagem
	var h_vis: float = size.y
	if h_vis > 100.0 and h_vis < 600.0:
		cw = minf(cw, maxf(h_vis - 8.0, 160.0) * 1024.0 / 572.0)
	_caixa_cena.custom_minimum_size = Vector2(cw, maxf(120.0, cw * 572.0 / 1024.0))
	_grade.columns = clampi(int(w / LARGURA_CARTA), 1, 3)


func ao_mostrar() -> void:
	super.ao_mostrar()
	call_deferred("_ao_redimensionar")
	call_deferred("_mostrar_oferta_nova")


## Depois da luta: abre a oferta de patrocínio que ainda não foi vista.
func _mostrar_oferta_nova() -> void:
	if not is_inside_tree() or Jogo.e.is_empty():
		return
	for o in Patrocinio.ofertas(Jogo.e):
		if not bool(o.get("vista", true)):
			ModalPatrocinio.abrir(self, str(o["id"]))
			return


func atualizar() -> void:
	var e: Dictionary = Jogo.e
	var casa := Game.lanista_da_casa(e)
	_l_contagem.text = "Gladiadores: %d/%d" % [e["gladiadores"].size(), Game.capacidade_ludus(e)]

	# Regras: o que falta construir
	Tema.limpar(_regras)
	for r in [["palus", "Treino: construa os palus."], ["enfermaria", "Ferido: construa a enfermaria."], ["armaria", "Equipamento: construa a armaria."]]:
		if not Game.tem_melhoria(e, r[0]):
			_regras.add_child(_chip(r[1], Color("2a1c16"), Tema.BORDA, Tema.CINZA, 15))

	if Game.tem_melhoria(e, "palus"):
		var bt := Tema.botao("Treino de combate", "ouro", 15)
		bt.custom_minimum_size = Vector2(0, 30)
		bt.pressed.connect(func() -> void:
			var vivos: Array = e["gladiadores"].filter(func(g): return g["vivo"] and not g.get("semEstilo", false))
			TelaTreinoCombate.abrir(self, vivos[0] if vivos.size() > 0 else {}))
		_regras.add_child(bt)
	else:
		_regras.add_child(_chip("Treino de combate: construa os palus.", Color("2a1c16"), Tema.BORDA, Tema.CINZA, 15))
	var n_of := Patrocinio.ofertas(e).size()
	var n_ct := Patrocinio.contratos(e).size()
	var bp := Tema.botao("Patrocínios (%d)" % (n_of + n_ct) if n_of + n_ct > 0 else "Patrocínios", "ouro" if n_of > 0 else "normal", 15)
	bp.custom_minimum_size = Vector2(0, 30)
	bp.pressed.connect(func(): ModalPatrocinio.abrir(self))
	_regras.add_child(bp)

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
		var lb := Tema.rotulo("·  " + str(l), 16, Tema.AREIA if n == 0 else Tema.CINZA)
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
			partes.append("%s %s%d" % [Model.SIGLA_ATRIBUTO[a], "+" if v > 0 else "", v])
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
	var sel_classe := 0
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
		var ct := Patrocinio.contrato_do(Jogo.e, str(g["id"]))
		if not ct.is_empty():
			var tp := Patrocinio.tipo_por_id(str(ct["tipo"]))
			var chip_p := TelaLudus._chip("%s %s · +%d/rodada" % [tp["nome"], ct["patrono"], int(ct["ouro"])], Color("2a2410"), Tema.OURO_ESCURO, Tema.OURO, 14)
			chip_p.tooltip_text = "Meta: %s (feitas %d)" % [Patrocinio.texto_meta(ct), int(ct["vitorias"])]
			cs.add_child(chip_p)

		# Passiva
		var passiva: Label
		if sem:
			passiva = Tema.rotulo("Sem estilo: não luta nas arenas até você definir como ele vai lutar. O kit básico vem junto.", 15, Tema.AREIA)
		else:
			passiva = Tema.rotulo("%s: %s" % [classe["passivaNome"], classe["passivaDescricao"]], 15, Tema.AREIA)
		passiva.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		passiva.modulate = Color(1, 1, 1, 0.9)
		v.add_child(passiva)

		# Efeitos persistentes do Poço
		if g["efeitos"].size() > 0:
			var fe := HFlowContainer.new()
			fe.add_theme_constant_override("h_separation", 6)
			v.add_child(fe)
			for ef in g["efeitos"]:
				fe.add_child(TelaLudus._chip("%s %d" % [Game.NOME_EFEITO[ef["tipo"]], int(ef["severidade"])], Color("3a1010"), Color("aa3333"), Color("ffb3a0"), 14))

		var bf := Tema.botao("Ficha e equipamento", "ouro", 18)
		bf.custom_minimum_size = Vector2(0, 44)
		bf.tooltip_text = "Atributos, treino, Glória e equipamento de %s." % g["nome"]
		var gid: String = g["id"]
		bf.pressed.connect(func(): ModalGladiador.abrir(self, gid))
		v.add_child(bf)
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
				var cls: String = Model.CLASSES_IDS[sel_estilo]
				(func() -> void: Jogo.resultado(Game.escolher_estilo(Jogo.e, id, cls))).call_deferred())
			par.add_child(b)
		var h2 := _linha()
		v.add_child(h2)
		if not (g["campeao"] or g.get("semEstilo", false)):
			var cl: Array = Model.CLASSES_IDS.filter(func(c): return c != g["classe"])
			var nomes_cl: Array = cl.map(func(c): return Model.classes()[c]["nome"])
			var par_c := Tema.hbox(4)
			h2.add_child(par_c)
			par_c.add_child(_opcoes(cl, nomes_cl, sel_classe, func(i): sel_classe = i))
			var bc := Tema.botao("Trocar estilo", "normal", 17)
			bc.tooltip_text = "%d de ouro e %d de energia." % [Game.preco_troca_estilo(e, g), 2 if g["origem"] == "livre" else 1]
			bc.pressed.connect(func():
				var cls: String = cl[mini(sel_classe, cl.size() - 1)]
				(func() -> void: Jogo.resultado(Game.trocar_classe(Jogo.e, id, cls))).call_deferred())
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
