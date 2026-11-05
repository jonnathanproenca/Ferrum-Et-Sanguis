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
var _modo := "mestre"
var _filtro_slot := ""
var _filtro_classe := ""
var _t_bigorna := 0.0
var _prox_bigorna := BIGORNA_IMPACTO
var _tocando := false

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
	_inventario(e)
	Tema.limpar(_conteudo)
	if _modo == "mestre":
		_pagina_mestre(e)
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
		v.add_child(Tema.rotulo(IconeItem.fmt_bonus(item["bonus"]), 14, Tema.CINZA))
		h.add_child(v)
		var q := Tema.rotulo("×%d" % int(contagem[id]), 18, Tema.OURO)
		q.autowrap_mode = TextServer.AUTOWRAP_OFF
		h.add_child(q)
		_lista_inv.add_child(h)

func _nome_item(item: Dictionary) -> String:
	var peso: String = (" (%s)" % item["peso"]) if item.get("peso", "") != "" else ""
	var q: String = (" [%s]" % Model.QUALIDADES[item["qualidade"]]) if int(item["qualidade"]) > 0 else ""
	return "%s%s%s" % [item["nome"], q, peso]

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
	var sem_ouro: bool = int(e["ouro"]) < preco
	var b := Tema.botao("Comprar · %d ouro" % preco, "primario", 17)
	b.custom_minimum_size = Vector2(0, 36)
	b.disabled = sem_ouro
	if sem_ouro:
		b.tooltip_text = "Faltam %d de ouro." % (preco - int(e["ouro"]))
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
