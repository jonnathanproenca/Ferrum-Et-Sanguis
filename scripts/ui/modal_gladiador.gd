class_name ModalGladiador
extends VBoxContainer
## Conteúdo da modal de um gladiador: cabeçalho (região, classe, nível), boneco de equipamentos à esquerda e ficha à direita.
## Uso: ModalGladiador.abrir(no, glad_id). Atualiza ao vivo com Jogo.mudou e fecha se o gladiador sumir.

var glad_id := ""
var _modal: Modal
var _cab: HBoxContainer
var _boneco: BonecoEquipamento
var _ficha: FichaGladiador
var _aviso: Label


static func abrir(pai: Node, id: String) -> Modal:
	var g := Game.achar(Jogo.e, id)
	if g.is_empty():
		return null
	var c := ModalGladiador.new()
	c.glad_id = id
	var m := Modal.abrir(pai, str(g["nome"]), c, 1180.0)
	c._modal = m
	c._iniciar()
	return m


func _init() -> void:
	add_theme_constant_override("separation", 10)


func _iniciar() -> void:
	var g := Game.achar(Jogo.e, glad_id)
	_cab = Tema.hbox(12)
	add_child(_cab)
	var cols := Tema.hbox(18)
	cols.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	add_child(cols)
	var esq := Tema.vbox(6)
	esq.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	cols.add_child(esq)
	_boneco = BonecoEquipamento.new()
	_boneco.construir(g)
	_boneco.slot_clicado.connect(_abrir_seletor)
	esq.add_child(_boneco)
	_aviso = Tema.rotulo("", 15, Tema.CINZA)
	_aviso.autowrap_mode = TextServer.AUTOWRAP_OFF
	_aviso.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	esq.add_child(_aviso)
	_ficha = FichaGladiador.new()
	_ficha.mostrar_cabecalho = false
	_ficha.construir(g)
	_ficha.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_ficha.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	cols.add_child(_ficha)
	Jogo.mudou.connect(_ao_mudar)
	_cabecalho(g)
	_texto_aviso(g)


func _ao_mudar() -> void:
	var g := Game.achar(Jogo.e, glad_id)
	if g.is_empty():
		if is_instance_valid(_modal):
			_modal.fechar()
		return
	_boneco.atualizar(g)
	_ficha.atualizar(g)
	_cabecalho(g)
	_texto_aviso(g)


func _texto_aviso(g: Dictionary) -> void:
	if g.get("semEstilo", false):
		_aviso.text = "Defina o estilo no cartão para equipar."
	elif not Game.tem_melhoria(Jogo.e, "armaria"):
		_aviso.text = "Construa a armaria para equipar."
	else:
		_aviso.text = "Clique num slot para equipar ou trocar."


func _cabecalho(g: Dictionary) -> void:
	Tema.limpar(_cab)
	var terra := Model.terra_por_id(str(g["terra"]))
	var tn := str(terra.get("nome", g["terra"]))
	_cab.add_child(Bandeira.novo(tn))
	var r := Tema.rotulo(tn, 18, Tema.AREIA)
	r.autowrap_mode = TextServer.AUTOWRAP_OFF
	_cab.add_child(r)
	var cl := "Sem estilo" if g.get("semEstilo", false) else str(Model.classes()[g["classe"]]["nome"])
	var c := Tema.rotulo("·  %s  ·  Nível %d" % [cl, int(g["nivel"])], 18, Tema.OCRE)
	c.autowrap_mode = TextServer.AUTOWRAP_OFF
	_cab.add_child(c)
	if g["campeao"]:
		_cab.add_child(TelaLudus._chip("Campeão", Tema.OURO, Tema.OURO_ESCURO, Color("2a1a10"), 14, true))
	if g["lenda"]:
		_cab.add_child(TelaLudus._chip("Lenda", Color("c24a3a"), Color("e0705a"), Color.WHITE, 14, true))
	if not g["vivo"]:
		_cab.add_child(TelaLudus._chip("morto", Color("222222"), Color("555555"), Tema.CINZA, 14))
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_cab.add_child(sp)
	for par in [["Vitórias %d" % int(g["vitorias"]), Color("1f2a18"), Color("4a6a38"), Tema.VERDE],
			["Poço %d" % int(g["vitoriasPoco"]), Color("2a2216"), Color("6a5230"), Tema.OURO_ESCURO],
			["Derrotas %d" % int(g["derrotas"]), Color("2a1414"), Color("6a3030"), Color("d88a7a")]]:
		_cab.add_child(TelaLudus._chip(par[0], par[1], par[2], par[3], 14))


## Bandeirola colorida (cor derivada do nome da terra).
class Bandeira extends Control:
	var cor := Color.WHITE
	static func novo(nome: String) -> Bandeira:
		var b := Bandeira.new()
		b.cor = Color.from_hsv(float(nome.hash() % 360) / 360.0, 0.55, 0.7)
		b.custom_minimum_size = Vector2(22, 26)
		b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		b.mouse_filter = Control.MOUSE_FILTER_IGNORE
		return b
	func _draw() -> void:
		draw_line(Vector2(3, 1), Vector2(3, 25), Tema.OURO_ESCURO, 2.0)
		var pts := PackedVector2Array([Vector2(4, 3), Vector2(21, 3), Vector2(16, 9), Vector2(21, 15), Vector2(4, 15)])
		draw_colored_polygon(pts, cor)
		draw_polyline(PackedVector2Array([pts[0], pts[1], pts[2], pts[3], pts[4], pts[0]]), Color(0, 0, 0, 0.55), 1.0)


# ---------- Seletor de item ----------

func _abrir_seletor(slot: String) -> void:
	var g := Game.achar(Jogo.e, glad_id)
	if g.is_empty():
		return
	var lista := Tema.vbox(6)
	var sel: Modal = Modal.abrir(self, "%s de %s" % [Model.NOME_SLOT[slot], g["nome"]], lista, 620.0)
	var atual = g["equipamento"].get(slot)
	if atual != null:
		lista.add_child(_linha(g, slot, Model.item_por_id(atual), 1, "", true, sel))
	# itens do inventário compatíveis (agrupados por id)
	var cont := {}
	for id in Jogo.e["inventario"]:
		cont[id] = int(cont.get(id, 0)) + 1
	var n := 0
	for id in cont:
		var item := Model.item_por_id(id)
		if item.is_empty() or item["slot"] != slot or not (g["classe"] in item["classes"]):
			continue
		if item.get("amuleto", false) and item["terra"] != g["terra"]:
			continue
		# testa em uma cópia do estado (Game.equipar é a única fonte das regras)
		var copia: Dictionary = Jogo.e.duplicate(true)
		var erro := Game.equipar(copia, glad_id, slot, id)
		lista.add_child(_linha(g, slot, item, int(cont[id]), erro, false, sel))
		n += 1
	if n == 0:
		var msg := "Nenhum amuleto de %s no armeiro." % str(Model.terra_por_id(str(g["terra"])).get("nome", "")) if slot == "amuleto" else "Nenhum item compatível no armeiro."
		lista.add_child(Tema.rotulo(msg, 17, Tema.CINZA))


func _linha(g: Dictionary, slot: String, item: Dictionary, qtd: int, erro: String, equipado: bool, sel: Modal) -> Control:
	var p := PanelContainer.new()
	var ok := erro == ""
	var sb := Tema.caixa(Color("2a1c16") if equipado else Color("181010"), IconeItem.cor_qualidade(int(item["qualidade"])) if ok else Color("3a2a1a"), 6, 1, 6)
	p.add_theme_stylebox_override("panel", sb)
	var h := Tema.hbox(10)
	p.add_child(h)
	var ic := IconeItem.criar(item, 52)
	ic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	if not ok:
		ic.modulate = Color(1, 1, 1, 0.5)
	h.add_child(ic)
	var info := Tema.vbox(1)
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(info)
	var q := int(item["qualidade"])
	var nome := Tema.rotulo("%s%s%s" % [item["nome"], " [%s]" % Model.QUALIDADES[q] if q > 0 else "", "  x%d" % qtd if qtd > 1 else ""], 18, IconeItem.cor_qualidade(q) if ok else Tema.CINZA)
	nome.autowrap_mode = TextServer.AUTOWRAP_OFF
	info.add_child(nome)
	var det := "%s  ·  Peso %d" % [IconeItem.fmt_bonus(item["bonus"]), int(item["peso"])]
	if int(item["forcaMin"]) > 0:
		det += "  ·  Força mín. %d" % int(item["forcaMin"])
	var d := Tema.rotulo(det, 15, Tema.CINZA)
	d.autowrap_mode = TextServer.AUTOWRAP_OFF
	info.add_child(d)
	if not ok:
		var er := Tema.rotulo(erro, 15, Color("e0705a"))
		er.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info.add_child(er)
	if equipado:
		var b := Tema.botao("Desequipar", "normal", 17)
		b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		b.pressed.connect(func() -> void:
			sel.fechar()
			Jogo.resultado(Game.equipar(Jogo.e, glad_id, slot, "")))
		h.add_child(b)
		nome.text += "  (equipado)"
	elif ok:
		var b := Tema.botao("Equipar", "ouro", 17)
		b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		var id: String = item["id"]
		b.pressed.connect(func() -> void:
			sel.fechar()
			Jogo.resultado(Game.equipar(Jogo.e, glad_id, slot, id)))
		h.add_child(b)
	return p
