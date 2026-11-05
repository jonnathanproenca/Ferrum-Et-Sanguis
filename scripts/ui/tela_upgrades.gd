class_name TelaUpgrades
extends Tela
## Aba "upgrades": escritório do engenheiro (cena animada) + lista de melhorias do ludus.

const ORDEM := ["palus", "armaria", "alojamentos", "refeitorio", "enfermaria"]
const ESCRITORIO := {
	"w": 1376.0, "h": 768.0, "fundo": "assets/upgrades/fundo.jpg",
	"engenheiro": Rect2(500, 266, 254, 428),
	"lamparina": Vector3(178, 182, 90),
}

var _lista: VBoxContainer
var _ouro_info: Label

func construir() -> void:
	var margem := MarginContainer.new()
	margem.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for lado in ["left", "right", "top", "bottom"]:
		margem.add_theme_constant_override("margin_" + lado, 12)
	add_child(margem)
	var h := Tema.hbox(14)
	margem.add_child(h)

	var arc := AspectRatioContainer.new()
	arc.ratio = ESCRITORIO["w"] / ESCRITORIO["h"]
	arc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	arc.size_flags_stretch_ratio = 3.0
	arc.alignment_vertical = AspectRatioContainer.ALIGNMENT_BEGIN
	h.add_child(arc)
	var quadro := PanelContainer.new()
	quadro.add_theme_stylebox_override("panel", Tema.caixa(Color("1a110a"), Color("3a2616"), 10, 2, 0))
	arc.add_child(quadro)
	var cena := CenaEstatica.new(ESCRITORIO["fundo"], ESCRITORIO["w"], ESCRITORIO["h"])
	quadro.add_child(cena)
	var l: Vector3 = ESCRITORIO["lamparina"]
	cena.brilho(l.x, l.y, l.z)
	var eng := Anim.criar("engenheiro")
	cena.colocar(eng, ESCRITORIO["engenheiro"])

	var dir := Tema.vbox(8)
	dir.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dir.size_flags_stretch_ratio = 2.0
	h.add_child(dir)
	dir.add_child(Tema.titulo("Escritório do engenheiro", 24))
	dir.add_child(Tema.rotulo("Cada upgrade transforma o ludus. Ao comprar, você volta à cena para ver a obra.", 16, Tema.CINZA))
	var sc := ScrollContainer.new()
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	dir.add_child(sc)
	_lista = Tema.vbox(10)
	_lista.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(_lista)

func ao_mostrar() -> void:
	super.ao_mostrar()
	Som.voz("engenheiro")

func atualizar() -> void:
	Tema.limpar(_lista)
	var e := Jogo.e
	for id in ORDEM:
		var m := Game.melhoria_por_id(id)
		var feita := Game.tem_melhoria(e, id)
		var custo := Game.custo_melhoria(e, id)
		var falta := custo - int(e["ouro"])
		var p := Tema.painel(Color("1d1411") if not feita else Color("1a1f14"), Tema.BORDA if not feita else Color("4a6a3a"))
		_lista.add_child(p)
		var v := Tema.vbox(6)
		p.add_child(v)
		v.add_child(Tema.rotulo(m["nome"], 21, Tema.OURO if not feita else Tema.VERDE, true))
		v.add_child(Tema.rotulo(m["efeito"], 16, Tema.AREIA))
		if feita:
			var selo := Tema.rotulo("Construído", 15, Tema.VERDE)
			selo.autowrap_mode = TextServer.AUTOWRAP_OFF
			var sp := PanelContainer.new()
			sp.add_theme_stylebox_override("panel", Tema.caixa(Color(0, 0, 0, 0), Tema.VERDE, 12, 1, 2))
			sp.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
			sp.add_child(selo)
			v.add_child(sp)
		else:
			var b := Tema.botao("Construir · %d ouro" % custo, "primario", 17)
			b.disabled = falta > 0
			b.pressed.connect(_construir.bind(id))
			v.add_child(b)
			if falta > 0:
				v.add_child(Tema.rotulo("Faltam %d de ouro." % falta, 14, Tema.CINZA))

func _construir(id: String) -> void:
	if Jogo.resultado(Game.construir_melhoria(Jogo.e, id)):
		Jogo.construiu.emit(id)
		if id == "alojamentos":
			Som.sfx("sfx/bocejo")
		Jogo.abrir_aba.emit("ludus")
