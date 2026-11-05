class_name TelaArmeiro
extends Tela
## Aba "armeiro" (forja): cena com ferreiro animado e brasa, ofertas do armeiro mestre, catálogo e inventário.

const CENA := {
	"w": 1376.0, "h": 768.0, "fundo": "assets/armeiro/fundo.jpg",
	"fogo": Rect2(116, 381, 150, 74), "ferreiro": Rect2(557, 180, 590, 458),
}
const BIGORNA_IMPACTO := 1.05
const BIGORNA_CICLO := 2.688

var _aviso_box: Control
var _principal: Control
var _cena: CenaFracao
var _ferreiro: Anim
var _lista_inv: VBoxContainer
var _t_inv: Label
var _conteudo: VBoxContainer
var _b_mestre: Button
var _b_catalogo: Button
var _b_amu: Button
var _regiao := ""
var _modo := "mestre"
var _filtro_slot := ""
var _filtro_classe := ""
var _t_bigorna := 0.0
var _prox_bigorna := BIGORNA_IMPACTO
var _tocando := false
var _glad_id := ""
var _sel_glad: OptionButton
var _barra_carga: CargaBarra
var _l_forca: Label

func construir() -> void:
	# ---- Aviso (armaria não construída)
	var cm := CenterContainer.new()
	cm.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(cm)
	_aviso_box = cm
	var ap := Tema.painel(Tema.PAINEL, Tema.OURO_ESCURO)
	cm.add_child(ap)
	var av := Tema.vbox(12)
	ap.add_child(av)
	av.add_child(Tema.titulo("Armeiro", 26))
	var al := Tema.rotulo("Construa a armaria no ludus para usar o armeiro.", 20, Tema.OCRE)
	al.custom_minimum_size = Vector2(420, 0)
	av.add_child(al)
	var ir := Tema.botao("Ir ao ludus", "primario")
	ir.pressed.connect(func(): Jogo.abrir_aba.emit("ludus"))
	av.add_child(ir)

	# ---- Principal
	var mg := MarginContainer.new()
	mg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for lado in ["left", "right", "top", "bottom"]:
		mg.add_theme_constant_override("margin_" + lado, 12)
	add_child(mg)
	_principal = mg
	var raiz := Tema.hbox(14)
	mg.add_child(raiz)

	# Coluna esquerda: cena + inventário
	var esq := Tema.vbox(10)
	esq.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	esq.size_flags_stretch_ratio = 0.85
	esq.custom_minimum_size = Vector2(380, 0)
	raiz.add_child(esq)
	var moldura := PanelContainer.new()
	moldura.add_theme_stylebox_override("panel", Tema.caixa(Color("1a110a"), Color("5a3a20"), 10, 2, 3))
	esq.add_child(moldura)
	esq.resized.connect(func():
		moldura.custom_minimum_size.y = maxf(0.0, (esq.size.x - 10.0) * float(CENA["h"]) / float(CENA["w"]) + 10.0))
	_cena = CenaFracao.new(Tema.textura(CENA["fundo"]), Vector2(CENA["w"], CENA["h"]))
	_cena.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_cena.size_flags_vertical = Control.SIZE_EXPAND_FILL
	moldura.add_child(_cena)
	var f: Rect2 = CENA["fogo"]
	_cena.brilho(Rect2(f.position.x - 70, f.position.y - 60, f.size.x + 140, f.size.y + 120))
	_cena.adicionar(Anim.criar("brasa"), f)
	_ferreiro = Anim.criar("ferreiro")
	_cena.adicionar(_ferreiro, CENA["ferreiro"])

	var inv := Tema.painel(Tema.PAINEL, Tema.BORDA)
	inv.size_flags_vertical = Control.SIZE_EXPAND_FILL
	esq.add_child(inv)
	var iv := Tema.vbox(6)
	inv.add_child(iv)
	_t_inv = Tema.titulo("No armeiro", 20)
	iv.add_child(_t_inv)
	var isc := ScrollContainer.new()
	isc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	isc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	iv.add_child(isc)
	_lista_inv = Tema.vbox(4)
	_lista_inv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	isc.add_child(_lista_inv)

	# Coluna direita: loja
	var dir := Tema.painel(Tema.PAINEL, Tema.OURO_ESCURO)
	dir.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dir.size_flags_stretch_ratio = 1.15
	dir.custom_minimum_size = Vector2(420, 0)
	raiz.add_child(dir)
	var dv := Tema.vbox(8)
	dir.add_child(dv)
	var gh := Tema.hbox(8)
	dv.add_child(gh)
	var lg := Tema.rotulo("Gladiador", 16, Tema.CINZA)
	lg.autowrap_mode = TextServer.AUTOWRAP_OFF
	gh.add_child(lg)
	_sel_glad = OptionButton.new()
	_sel_glad.focus_mode = Control.FOCUS_NONE
	_sel_glad.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_sel_glad.item_selected.connect(func(i): _glad_id = str(_sel_glad.get_item_metadata(i)); atualizar())
	gh.add_child(_sel_glad)
	_l_forca = Tema.rotulo("", 16, Tema.OCRE)
	_l_forca.autowrap_mode = TextServer.AUTOWRAP_OFF
	gh.add_child(_l_forca)
	_barra_carga = CargaBarra.new()
	dv.add_child(_barra_carga)
	var cab := Tema.hbox(8)
	dv.add_child(cab)
	_b_mestre = Tema.botao("Armeiro mestre", "normal", 18)
	_b_mestre.toggle_mode = true
	_b_mestre.pressed.connect(func(): _modo = "mestre"; atualizar())
	cab.add_child(_b_mestre)
	_b_catalogo = Tema.botao("Catálogo", "normal", 18)
	_b_catalogo.toggle_mode = true
	_b_catalogo.pressed.connect(func(): _modo = "catalogo"; atualizar())
	cab.add_child(_b_catalogo)
	_b_amu = Tema.botao("Amuletos", "normal", 18)
	_b_amu.toggle_mode = true
	_b_amu.pressed.connect(func(): _modo = "amuletos"; _regiao = ""; atualizar())
	cab.add_child(_b_amu)
	var dsc := ScrollContainer.new()
	dsc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	dsc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	dv.add_child(dsc)
	_conteudo = Tema.vbox(8)
	_conteudo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dsc.add_child(_conteudo)

func ao_mostrar() -> void:
	super.ao_mostrar()
	# Realinha a bigorna com o quadro do martelo.
	_ferreiro._t = 0.0
	_ferreiro._frame = 0
	_t_bigorna = 0.0
	_prox_bigorna = BIGORNA_IMPACTO

func _process(delta: float) -> void:
	if not is_visible_in_tree() or not _principal.visible:
		return
	_t_bigorna += delta
	while _t_bigorna >= _prox_bigorna:
		if _t_bigorna - _prox_bigorna < 0.5:
			Som.sfx("cena/bigorna")
		_prox_bigorna += BIGORNA_CICLO

# ---------- Atualização ----------

func atualizar() -> void:
	var e: Dictionary = Jogo.e
	var tem: bool = Game.tem_melhoria(e, "armaria")
	_aviso_box.visible = not tem
	_principal.visible = tem
	if not tem:
		return
	if not e.has("armeiroMestre") or e["armeiroMestre"] == null:
		Game.gerar_armeiro_mestre(e)
	_b_mestre.button_pressed = _modo == "mestre"
	_b_catalogo.button_pressed = _modo == "catalogo"
	_b_amu.button_pressed = _modo == "amuletos"
	_gladiador(e)
	_inventario(e)
	Tema.limpar(_conteudo)
	if _modo == "mestre":
		_pagina_mestre(e)
	elif _modo == "amuletos":
		_pagina_amuletos(e)
	else:
		_pagina_catalogo(e)

func _inventario(e: Dictionary) -> void:
	Tema.limpar(_lista_inv)
	var contagem := {}
	for id in e["inventario"]:
		contagem[id] = int(contagem.get(id, 0)) + 1
	_t_inv.text = "No armeiro (%d)" % e["inventario"].size()
	if contagem.is_empty():
		_lista_inv.add_child(Tema.rotulo("Nenhum item guardado.", 16, Tema.CINZA))
		return
	var g := _glad_sel(e)
	for id in contagem:
		var item := Model.item_por_id(id)
		if item.is_empty():
			continue
		var h := Tema.hbox(8)
		h.add_child(IconeItem.criar(item, 38))
		var v := Tema.vbox(0)
		v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var nome := Tema.rotulo(_nome_item(item), 17, IconeItem.cor_qualidade(item["qualidade"]))
		v.add_child(nome)
		var bonus_txt := IconeItem.fmt_bonus(item["bonus"])
		if item.get("amuleto", false):
			bonus_txt = "%s · %s" % [Model.terra_por_id(item["terra"])["nome"], bonus_txt]
		v.add_child(Tema.rotulo(bonus_txt, 14, Tema.CINZA))
		if not item.get("amuleto", false):
			v.add_child(Tema.rotulo(_req_texto(item), 13, Tema.CINZA))
		h.add_child(v)
		var q := Tema.rotulo("×%d" % int(contagem[id]), 18, Tema.OURO)
		q.autowrap_mode = TextServer.AUTOWRAP_OFF
		h.add_child(q)
		var motivo := _motivo_equipar(e, g, item)
		var be := Tema.botao("Equipar", "normal", 15)
		be.custom_minimum_size = Vector2(84, 32)
		be.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		be.disabled = g.is_empty() or (motivo != "" and (motivo.begins_with("Este item não serve") or motivo.begins_with("Este amuleto")))
		if motivo != "":
			be.tooltip_text = motivo
		var iid: String = str(id)
		var sl: String = str(item["slot"])
		be.pressed.connect(func():
			if g.is_empty():
				return
			Jogo.resultado(Game.equipar(Jogo.e, str(g["id"]), sl, iid)))
		h.add_child(be)
		var bv := Tema.botao("Vender %d" % Game.valor_venda_item(e, item), "ouro", 15)
		bv.custom_minimum_size = Vector2(96, 32)
		bv.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		bv.disabled = bool(item.get("basico", false))
		bv.tooltip_text = "O kit básico não pode ser vendido." if bv.disabled else "Recupera 40%% do valor pago (%d de ouro)." % Game.valor_venda_item(e, item)
		bv.pressed.connect(func(): Jogo.resultado(Game.vender_item(Jogo.e, iid)))
		h.add_child(bv)
		if motivo != "" and not be.disabled:
			var av := Tema.rotulo(motivo, 13, Color("e06a5a"))
			var col := Tema.vbox(2)
			col.add_child(h)
			col.add_child(av)
			_lista_inv.add_child(col)
		else:
			_lista_inv.add_child(h)

## Gladiador escolhido na lista (primeiro vivo com estilo se nada escolhido).
func _glad_sel(e: Dictionary) -> Dictionary:
	var vivos := _vivos(e)
	for g in vivos:
		if str(g["id"]) == _glad_id:
			return g
	return vivos[0] if not vivos.is_empty() else {}

func _vivos(e: Dictionary) -> Array:
	return e["gladiadores"].filter(func(g): return g["vivo"] and not g.get("semEstilo", false))

func _esp(e: Dictionary) -> String:
	return str(Game.lanista_da_casa(e).get("especialidade", ""))

## Atualiza o seletor e a barra de carga do gladiador escolhido.
func _gladiador(e: Dictionary) -> void:
	var vivos := _vivos(e)
	_sel_glad.clear()
	var g := _glad_sel(e)
	for i in vivos.size():
		_sel_glad.add_item(str(vivos[i]["nome"]))
		_sel_glad.set_item_metadata(i, vivos[i]["id"])
		if not g.is_empty() and vivos[i]["id"] == g["id"]:
			_sel_glad.select(i)
	_sel_glad.disabled = vivos.is_empty()
	if g.is_empty():
		_glad_id = ""
		_l_forca.text = ""
		_barra_carga.definir(0, 0)
		return
	_glad_id = str(g["id"])
	var extra := Game.extra_da_casa(e)
	var fs: int = int(Model.stats_sem_itens(g, _esp(e), extra)["forca"])
	_l_forca.text = "Força %d" % fs
	_barra_carga.definir(Model.carga_atual(g), Model.carga_maxima(g, _esp(e), extra))

## Texto de requisitos: Peso, Força mínima e Fama mínima.
func _req_texto(item: Dictionary) -> String:
	var t := "Peso %d" % int(item.get("peso", 0))
	if int(item.get("forcaMin", 0)) > 0:
		t += " · Força mín. %d" % int(item["forcaMin"])
	if int(item.get("famaMin", 0)) > 0:
		t += " · Fama mín. %d" % int(item["famaMin"])
	return t

## "" se o gladiador consegue vestir; senão o motivo (classe, Força ou peso).
func _motivo_equipar(e: Dictionary, g: Dictionary, item: Dictionary) -> String:
	if g.is_empty():
		return "Sem gladiador com estilo."
	if item.get("amuleto", false) and item["terra"] != g["terra"]:
		return "Este amuleto pertence a %s; %s é de %s." % [Model.terra_por_id(item["terra"])["nome"], g["nome"], Model.terra_por_id(g["terra"])["nome"]]
	if not (g["classe"] in item["classes"]):
		return "Este item não serve ao estilo de %s." % g["nome"]
	var extra := Game.extra_da_casa(e)
	var fs: int = int(Model.stats_sem_itens(g, _esp(e), extra)["forca"])
	if fs < int(item.get("forcaMin", 0)):
		return "Exige Força %d (%s tem %d)." % [int(item["forcaMin"]), g["nome"], fs]
	var atual: int = Model.carga_atual(g)
	var antigo = g["equipamento"].get(item["slot"])
	if antigo != null:
		atual -= int(Model.item_por_id(antigo).get("peso", 0))
	var maxima: int = Model.carga_maxima(g, _esp(e), extra)
	if atual + int(item.get("peso", 0)) > maxima:
		return "Peso demais (carga máxima %d)." % maxima
	return ""

func _nome_item(item: Dictionary) -> String:
	var q: String = (" [%s]" % Model.QUALIDADES[item["qualidade"]]) if int(item["qualidade"]) > 0 else ""
	return "%s%s" % [item["nome"], q]

func _pagina_mestre(e: Dictionary) -> void:
	var rt := RichTextLabel.new()
	rt.bbcode_enabled = true
	rt.fit_content = true
	rt.scroll_active = false
	rt.add_theme_font_size_override("normal_font_size", 15)
	rt.add_theme_color_override("default_color", Tema.CINZA)
	var c: Array = Model.COR_QUALIDADE
	rt.text = "Cinco peças especiais, sorteadas a cada rodada (no máximo 3 Superiores, 2 Raras, 2 Épicas e 1 Lendária). Todo gladiador já recebe o kit básico ao escolher o estilo, então aqui só há peças melhores. Chances: [color=%s]Superior 60%%[/color] · [color=%s]Rara 25%%[/color] · [color=%s]Épica 11%%[/color] · [color=%s]Lendária 4%%[/color]." % [c[1], c[2], c[3], c[4]]
	_conteudo.add_child(rt)
	var ofertas: Array = e["armeiroMestre"]
	if ofertas.is_empty():
		_conteudo.add_child(Tema.rotulo("Tudo vendido. Novas peças na próxima rodada.", 18, Tema.OCRE))
		return
	var grade := _grade()
	_conteudo.add_child(grade)
	for id in ofertas:
		var item := Model.item_por_id(id)
		if item.is_empty():
			continue
		grade.add_child(_carta(e, item, true))

func _pagina_amuletos(e: Dictionary) -> void:
	var intro := Tema.rotulo("Cada amuleto pertence a uma região: só gladiadores nascidos nela podem usá-lo. Bônus de +1 a +5 em um atributo, conforme a raridade.", 15, Tema.CINZA)
	_conteudo.add_child(intro)
	var regs: Array = []
	for g in e["gladiadores"]:
		if g["vivo"] and not regs.has(str(g["terra"])):
			regs.append(str(g["terra"]))
	if regs.is_empty():
		_conteudo.add_child(Tema.rotulo("Nenhum gladiador vivo no ludus: sem região para comprar amuletos.", 17, Tema.OCRE))
		return
	if not regs.has(_regiao):
		var g := _glad_sel(e)
		_regiao = str(g["terra"]) if not g.is_empty() and regs.has(str(g["terra"])) else regs[0]
	var rh := Tema.hbox(8)
	_conteudo.add_child(rh)
	var lr := Tema.rotulo("Região", 16, Tema.CINZA)
	lr.autowrap_mode = TextServer.AUTOWRAP_OFF
	rh.add_child(lr)
	var os := OptionButton.new()
	os.focus_mode = Control.FOCUS_NONE
	os.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for i in regs.size():
		var n := 0
		for g in e["gladiadores"]:
			if g["vivo"] and g["terra"] == regs[i]:
				n += 1
		os.add_item("%s (%d)" % [Model.terra_por_id(regs[i])["nome"], n])
	os.select(regs.find(_regiao))
	os.item_selected.connect(func(i): _regiao = regs[i]; atualizar())
	rh.add_child(os)
	var cat := Game.catalogo_amuletos(_regiao)
	var grade := GridContainer.new()
	grade.columns = 6
	grade.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grade.add_theme_constant_override("h_separation", 4)
	grade.add_theme_constant_override("v_separation", 4)
	_conteudo.add_child(grade)
	grade.add_child(Control.new())
	for q in range(Model.QUALIDADE_MAX + 1):
		var lq := Tema.rotulo(Model.QUALIDADES[q], 12, IconeItem.cor_qualidade(q))
		lq.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lq.autowrap_mode = TextServer.AUTOWRAP_OFF
		lq.clip_text = true
		lq.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		lq.custom_minimum_size = Vector2(50, 0)
		grade.add_child(lq)
	var fama := Game.fama_efetiva(e)
	for a in Model.ATRIBUTOS:
		var base := Model.item_por_id(cat[a][0])
		var hc := Tema.hbox(4)
		hc.custom_minimum_size = Vector2(150, 0)
		hc.add_child(Glifo.novo(a, 20, Tema.OURO))
		var vc := Tema.vbox(0)
		vc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var ln := Tema.rotulo(str(base["nome"]), 12, Tema.AREIA)
		ln.autowrap_mode = TextServer.AUTOWRAP_OFF
		ln.clip_text = true
		ln.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		vc.add_child(ln)
		var le := Tema.rotulo("+ %s" % Model.NOME_ATRIBUTO[a], 12, Tema.CINZA)
		le.autowrap_mode = TextServer.AUTOWRAP_OFF
		vc.add_child(le)
		hc.add_child(vc)
		grade.add_child(hc)
		for id in cat[a]:
			grade.add_child(_celula_amuleto(e, Model.item_por_id(id), fama))

func _celula_amuleto(e: Dictionary, item: Dictionary, fama: int) -> Control:
	var q: int = int(item["qualidade"])
	var cor := IconeItem.cor_qualidade(q)
	var preco: int = Game.preco_item(e, item)
	var fama_min := int(item.get("famaMin", 0))
	var sem_fama: bool = fama < fama_min
	var sem_ouro: bool = int(e["ouro"]) < preco
	var b := Button.new()
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(50, 78)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var bloq := sem_fama or sem_ouro
	var borda := Color("8a2a22") if sem_fama else (cor.darkened(0.4) if sem_ouro else cor)
	b.add_theme_stylebox_override("normal", Tema.caixa(Color("211612").lerp(cor, 0.1), borda, 6, 2, 3))
	b.add_theme_stylebox_override("hover", Tema.caixa(Color("2c1d15").lerp(cor, 0.2), borda.lightened(0.3), 6, 2, 3))
	b.add_theme_stylebox_override("pressed", Tema.caixa(Color("160e0a"), borda, 6, 2, 3))
	b.add_theme_stylebox_override("disabled", Tema.caixa(Color("1a1210"), borda, 6, 2, 3))
	b.disabled = bloq
	if sem_fama:
		b.tooltip_text = "Trancado: exige %d de fama (você tem %d)." % [fama_min, fama]
	elif sem_ouro:
		b.tooltip_text = "Faltam %d de ouro." % (preco - int(e["ouro"]))
	else:
		b.tooltip_text = "%s (%s): %s. Comprar por %d de ouro." % [item["nome"], Model.QUALIDADES[q], IconeItem.fmt_bonus(item["bonus"]), preco]
	var v := Tema.vbox(0)
	v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var topo := Tema.hbox(0)
	topo.alignment = BoxContainer.ALIGNMENT_CENTER
	topo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if sem_fama:
		topo.add_child(Glifo.novo("cadeado", 28, Color("e0483a")))
	else:
		var ic := IconeItem.criar(item, 28)
		if sem_ouro:
			ic.modulate = Color(1, 1, 1, 0.55)
		topo.add_child(ic)
	v.add_child(topo)
	var lb := Tema.rotulo("+%d" % int(item["bonus"].values()[0]), 15, cor)
	lb.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lb.autowrap_mode = TextServer.AUTOWRAP_OFF
	lb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(lb)
	var lp := Tema.rotulo(str(preco), 13, Color("e06a5a") if sem_ouro else Tema.OURO)
	lp.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lp.autowrap_mode = TextServer.AUTOWRAP_OFF
	lp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(lp)
	b.add_child(v)
	var iid: String = str(item["id"])
	b.pressed.connect(func():
		if Jogo.resultado(Game.comprar_item(Jogo.e, iid)):
			Som.sfx("sfx/moeda"))
	return b

func _grade() -> GridContainer:
	var g := GridContainer.new()
	g.columns = 2
	g.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	g.add_theme_constant_override("h_separation", 8)
	g.add_theme_constant_override("v_separation", 8)
	return g

func _pagina_catalogo(e: Dictionary) -> void:
	var fh := Tema.hbox(8)
	_conteudo.add_child(fh)
	var os := OptionButton.new()
	os.focus_mode = Control.FOCUS_NONE
	os.add_item("Todos os tipos")
	var slots: Array = [""]
	for s in Model.SLOTS:
		os.add_item(Model.NOME_SLOT[s])
		slots.append(s)
	os.select(slots.find(_filtro_slot))
	os.item_selected.connect(func(i): _filtro_slot = slots[i]; atualizar())
	fh.add_child(os)
	var oc := OptionButton.new()
	oc.focus_mode = Control.FOCUS_NONE
	oc.add_item("Todas as classes")
	var classes: Array = [""]
	for c in Model.CLASSES_IDS:
		oc.add_item(Model.classes()[c]["nome"])
		classes.append(c)
	oc.select(classes.find(_filtro_classe))
	oc.item_selected.connect(func(i): _filtro_classe = classes[i]; atualizar())
	fh.add_child(oc)
	var grade := _grade()
	_conteudo.add_child(grade)
	var n := 0
	for it in Model.itens():
		if it.get("basico", false):
			continue
		if _filtro_slot != "" and it["slot"] != _filtro_slot:
			continue
		if _filtro_classe != "" and not (it["classes"] as Array).has(_filtro_classe):
			continue
		grade.add_child(_carta(e, Model.item_por_id(it["id"]), false))
		n += 1
	if n == 0:
		_conteudo.add_child(Tema.rotulo("Nenhum item com esse filtro.", 18, Tema.OCRE))

func _carta(e: Dictionary, item: Dictionary, mestre: bool) -> Control:
	var q: int = int(item["qualidade"])
	var cor := IconeItem.cor_qualidade(q)
	var preco: int = Game.preco_item(e, item)
	var p := PanelContainer.new()
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var sb := Tema.caixa(Color("211612").lerp(cor, 0.07), cor if q > 0 else Tema.BORDA, 8, 2 if q > 0 else 1, 8)
	if q >= 4:
		sb.shadow_color = Color(cor, 0.5)
		sb.shadow_size = 10
	p.add_theme_stylebox_override("panel", sb)
	var v := Tema.vbox(4)
	p.add_child(v)
	var h := Tema.hbox(8)
	v.add_child(h)
	h.add_child(IconeItem.criar(item, 56))
	var t := Tema.vbox(0)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(t)
	var nome := Tema.rotulo(str(item["nome"]), 19, cor if q > 0 else Tema.AREIA, true)
	t.add_child(nome)
	if q > 0:
		t.add_child(Tema.rotulo(Model.QUALIDADES[q], 14, cor))
	var serve: Array = []
	for c in item["classes"]:
		serve.append(Model.classes()[c]["nome"])
	v.add_child(Tema.rotulo("%s · Serve: %s" % [Model.NOME_SLOT[item["slot"]], ", ".join(serve)], 14, Tema.CINZA))
	var bn := Tema.rotulo(IconeItem.fmt_bonus(item["bonus"]), 17, Tema.OCRE)
	v.add_child(bn)
	# peso / Força mínima
	var rp := Tema.hbox(4)
	rp.add_child(Glifo.novo("peso", 16, Tema.CINZA))
	var forca_min := int(item.get("forcaMin", 0))
	var tp := "Peso %d" % int(item.get("peso", 0)) + ((" · Força mín. %d" % forca_min) if forca_min > 0 else " · sem exigência de Força")
	var g := _glad_sel(e)
	var motivo := _motivo_equipar(e, g, item) if not g.is_empty() else ""
	var outro_estilo: bool = motivo.begins_with("Este item não serve")
	var nao_serve: bool = motivo != "" and not g.is_empty()
	var lp := Tema.rotulo(tp, 15, Color("e06a5a") if (nao_serve and not outro_estilo) else Tema.AREIA)
	lp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rp.add_child(lp)
	v.add_child(rp)
	if nao_serve:
		var ln := Tema.rotulo(motivo if outro_estilo else "%s não consegue equipar: %s" % [g["nome"], motivo], 13, Tema.CINZA if outro_estilo else Color("e06a5a"))
		v.add_child(ln)
	# fama mínima
	var fama_min := int(item.get("famaMin", 0))
	var fama_atual := Game.fama_efetiva(e)
	var trancado: bool = fama_atual < fama_min
	var rf := Tema.hbox(4)
	rf.add_child(Glifo.novo("cadeado" if trancado else "coroa_fama", 16, Color("e0483a") if trancado else Tema.OURO_ESCURO))
	var lf := Tema.rotulo(("Trancado: exige %d de fama (você tem %d)" % [fama_min, fama_atual]) if trancado else ("Fama mín. %d" % fama_min if fama_min > 0 else "Sem exigência de fama"), 15, Color("e0483a") if trancado else Tema.CINZA)
	lf.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rf.add_child(lf)
	v.add_child(rf)
	var sem_ouro: bool = int(e["ouro"]) < preco
	var b := Tema.botao("Comprar · %d ouro" % preco, "primario", 17)
	b.custom_minimum_size = Vector2(0, 36)
	b.disabled = sem_ouro or trancado
	if trancado:
		b.tooltip_text = "Exige %d de fama (você tem %d)." % [fama_min, fama_atual]
	elif sem_ouro:
		b.tooltip_text = "Faltam %d de ouro." % (preco - int(e["ouro"]))
	if trancado:
		sb.border_color = Color("8a2a22")
	var iid: String = str(item["id"])
	b.pressed.connect(func():
		var err: String = Game.comprar_mestre(Jogo.e, iid) if mestre else Game.comprar_item(Jogo.e, iid)
		if Jogo.resultado(err):
			Som.sfx("sfx/moeda"))
	var fim := Control.new()
	fim.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(fim)
	v.add_child(b)
	return p

## Barra de carga: marcas em 30% e 70%, cor pela faixa, texto da faixa e "atual / máxima".
class CargaBarra extends Control:
	const FAIXAS := {"leve": ["Leve", Color("6fae5a")], "normal": ["Normal", Color("c9a24a")], "pesado": ["Pesado", Color("d9772c")], "sobrecarga": ["Sobrecarga", Color("c9332a")]}
	var atual := 0
	var maxima := 0

	func _init() -> void:
		custom_minimum_size = Vector2(0, 28)
		mouse_filter = Control.MOUSE_FILTER_PASS

	func definir(a: int, m: int) -> void:
		atual = a
		maxima = m
		var f := Model.faixa_carga(a, m) if m > 0 else "leve"
		tooltip_text = "Carga: peso do equipamento vestido. Leve até 30%%, Normal até 70%%, Pesado até 100%%. %s." % FAIXAS[f][0]
		queue_redraw()

	func _draw() -> void:
		var fonte := ThemeDB.fallback_font
		var larg := size.x
		var altura := size.y
		var tr := Rect2(0, 0, larg, altura)
		draw_rect(tr, Color(0, 0, 0, 0.55))
		var f := Model.faixa_carga(atual, maxima) if maxima > 0 else "leve"
		var cor: Color = FAIXAS[f][1]
		var frac := clampf(float(atual) / float(maxi(1, maxima)), 0.0, 1.0)
		draw_rect(Rect2(1, 1, (larg - 2) * frac, altura - 2), cor.darkened(0.15))
		for m in [0.3, 0.7]:
			draw_line(Vector2(larg * m, 1), Vector2(larg * m, altura - 1), Color(1, 1, 1, 0.55), 2.0)
		draw_rect(tr, Tema.BORDA, false, 1.5)
		var fs := 15
		var t1 := "Carga: %s" % FAIXAS[f][0]
		var t2 := "%d / %d" % [atual, maxima]
		var sombra := Color(0, 0, 0, 0.9)
		var y := altura / 2.0 + fs * 0.35
		var tam2 := fonte.get_string_size(t2, HORIZONTAL_ALIGNMENT_LEFT, -1, fs)
		for pos_txt in [[t1, 8.0], [t2, larg - tam2.x - 8.0]]:
			draw_string(fonte, Vector2(pos_txt[1] + 1, y + 1), pos_txt[0], HORIZONTAL_ALIGNMENT_LEFT, -1, fs, sombra)
			draw_string(fonte, Vector2(pos_txt[1], y), pos_txt[0], HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color("f5ecd8"))
