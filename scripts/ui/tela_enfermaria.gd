class_name TelaEnfermaria
extends Tela
## Aba "enfermaria": cena do médico + lista de gladiadores com efeitos do Poço para tratar.

const ENFERMARIA := {
	"w": 1376.0, "h": 768.0, "fundo": "assets/enfermaria/fundo.jpg",
	"medico": Rect2(598, 316, 245, 333),
	"luz_porta": Rect2(930, 500, 330, 120),
	"tocha": Vector3(250, 322, 70),
}

var _raiz: HBoxContainer
var _aviso: VBoxContainer
var _lista: VBoxContainer

func construir() -> void:
	var margem := MarginContainer.new()
	margem.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for lado in ["left", "right", "top", "bottom"]:
		margem.add_theme_constant_override("margin_" + lado, 12)
	add_child(margem)
	# Aviso quando a enfermaria ainda não existe
	_aviso = Tema.vbox(12)
	_aviso.alignment = BoxContainer.ALIGNMENT_CENTER
	margem.add_child(_aviso)
	var t := Tema.rotulo("Construa a enfermaria no menu Upgrades para tratar os feridos.", 22, Tema.OCRE)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_aviso.add_child(t)
	var b := Tema.botao("Ir aos upgrades", "primario", 18)
	b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	b.pressed.connect(func(): Jogo.abrir_aba.emit("upgrades"))
	_aviso.add_child(b)

	_raiz = Tema.hbox(14)
	margem.add_child(_raiz)
	var arc := AspectRatioContainer.new()
	arc.ratio = ENFERMARIA["w"] / ENFERMARIA["h"]
	arc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	arc.size_flags_stretch_ratio = 3.0
	arc.alignment_vertical = AspectRatioContainer.ALIGNMENT_BEGIN
	_raiz.add_child(arc)
	var quadro := PanelContainer.new()
	quadro.add_theme_stylebox_override("panel", Tema.caixa(Color("1a110a"), Color("3a2616"), 10, 2, 0))
	arc.add_child(quadro)
	var cena := CenaEstatica.new(ENFERMARIA["fundo"], ENFERMARIA["w"], ENFERMARIA["h"])
	quadro.add_child(cena)
	cena.luz(ENFERMARIA["luz_porta"])
	var to: Vector3 = ENFERMARIA["tocha"]
	cena.brilho(to.x, to.y, to.z)
	cena.colocar(Anim.criar("medico"), ENFERMARIA["medico"])

	var dir := Tema.vbox(8)
	dir.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dir.size_flags_stretch_ratio = 2.0
	_raiz.add_child(dir)
	dir.add_child(Tema.titulo("Enfermaria", 24))
	dir.add_child(Tema.rotulo("Tratar um ferido remove os efeitos deixados pelo Poço.", 16, Tema.CINZA))
	var sc := ScrollContainer.new()
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	dir.add_child(sc)
	_lista = Tema.vbox(10)
	_lista.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(_lista)

func ao_mostrar() -> void:
	super.ao_mostrar()
	if Game.tem_melhoria(Jogo.e, "enfermaria"):
		Som.voz("medico")

func atualizar() -> void:
	var tem := Game.tem_melhoria(Jogo.e, "enfermaria")
	_raiz.visible = tem
	_aviso.visible = not tem
	if not tem:
		return
	Tema.limpar(_lista)
	var e := Jogo.e
	var feridos: Array = e["gladiadores"].filter(func(g): return g["vivo"] and g["efeitos"].size() > 0)
	if feridos.is_empty():
		var p := Tema.rotulo("Ninguém ferido agora. O médico aguarda, entediado.", 18, Tema.CINZA)
		_lista.add_child(p)
		return
	for g in feridos:
		var p := Tema.painel()
		_lista.add_child(p)
		var h := Tema.hbox(12)
		p.add_child(h)
		var spr := Sprites.controle_gladiador(g, 96.0)
		h.add_child(spr)
		var v := Tema.vbox(6)
		v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(v)
		v.add_child(Tema.rotulo(g["nome"], 21, Tema.OURO, true))
		var fl := HFlowContainer.new()
		fl.add_theme_constant_override("h_separation", 6)
		fl.add_theme_constant_override("v_separation", 4)
		v.add_child(fl)
		for ef in g["efeitos"]:
			var pc := PanelContainer.new()
			pc.add_theme_stylebox_override("panel", Tema.caixa(Color("3a1010"), Color("aa3333"), 10, 1, 2))
			var lb := Tema.rotulo("%s %d" % [Game.NOME_EFEITO[ef["tipo"]], int(ef["severidade"])], 15, Color("ffb3a0"))
			lb.autowrap_mode = TextServer.AUTOWRAP_OFF
			pc.add_child(lb)
			fl.add_child(pc)
		var custo := Model.custo_tratamento(g)
		var b := Tema.botao("Tratar · %d ouro · 1 energia" % custo, "primario", 16)
		b.disabled = int(e["energia"]) < 1 or int(e["ouro"]) < custo
		b.pressed.connect(func(): Jogo.resultado(Game.tratar(Jogo.e, g["id"])))
		v.add_child(b)
