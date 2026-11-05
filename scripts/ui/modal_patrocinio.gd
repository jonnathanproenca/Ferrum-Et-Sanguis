class_name ModalPatrocinio
extends VBoxContainer
## Oferta de patrocínio: retrato do patrício à esquerda (assets/patronos/<tipo>.png; sem arquivo, silhueta provisória)
## e a proposta à direita. Também lista os contratos ativos. Uso: ModalPatrocinio.abrir(no, oferta_id).

const COR_TIPO := {"eques": "8a6a3a", "edil": "3a7a6a", "matrona": "9a2a22", "pretor": "5a3a7a", "senador": "6a2a8a", "consul": "b8902a"}

var _modal: Modal


## Abre a oferta indicada; sem id, abre a lista (ofertas pendentes + contratos).
static func abrir(pai: Node, oferta_id: String = "") -> Modal:
	var c := ModalPatrocinio.new()
	var titulo := "Patrocínios"
	var oferta := {}
	if oferta_id != "":
		for o in Patrocinio.ofertas(Jogo.e):
			if o["id"] == oferta_id:
				oferta = o
		if oferta.is_empty():
			return null
		titulo = "Oferta de patrocínio"
	var m := Modal.abrir(pai, titulo, c, 840.0)
	c._modal = m
	c._montar(oferta)
	return m


func _init() -> void:
	add_theme_constant_override("separation", 12)


func _montar(oferta: Dictionary) -> void:
	if not oferta.is_empty():
		oferta["vista"] = true
		Jogo.salvar()
		add_child(_cartao_oferta(oferta))
		return
	var e: Dictionary = Jogo.e
	var ofs := Patrocinio.ofertas(e)
	var cts := Patrocinio.contratos(e)
	if ofs.is_empty() and cts.is_empty():
		add_child(Tema.rotulo("Nenhum patrício reparou no seu ludus ainda. Derrote lanistas famosos na campanha e vença nas arenas de honra: quanto maior a Aura, mais chance de uma oferta.", 18, Tema.CINZA))
		return
	for o in ofs:
		add_child(_cartao_oferta(o))
	if cts.size() > 0:
		add_child(Tema.rotulo("Contratos ativos", 20, Tema.OURO, true))
		for c in cts:
			var t := Patrocinio.tipo_por_id(c["tipo"])
			var restante: int = int(c["prazo"]) - (int(e["turno"]) - int(c["desde"]))
			add_child(Tema.rotulo("%s %s paga %d de ouro por rodada a %s. Meta: %s (feitas %d; %d rodada%s para o prazo)." % [
				t["nome"], c["patrono"], int(c["ouro"]), c["gladNome"], Patrocinio.texto_meta(c), int(c["vitorias"]), restante, "" if restante == 1 else "s"], 17, Tema.AREIA))


func _retrato(tipo: String) -> Control:
	var caixa := PanelContainer.new()
	caixa.custom_minimum_size = Vector2(300, 400)
	caixa.add_theme_stylebox_override("panel", Tema.caixa(Color("120c0a"), Tema.OURO_ESCURO, 8, 2, 4))
	var tex := Tema.textura("assets/patronos/%s.png" % tipo)
	if tex != null:
		var tr := TextureRect.new()
		tr.texture = tex
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		caixa.add_child(tr)
	else:
		var s := Silhueta.new()
		s.cor = Color(COR_TIPO.get(tipo, "8a6a3a"))
		s.custom_minimum_size = Vector2(290, 390)
		caixa.add_child(s)
	return caixa


func _cartao_oferta(o: Dictionary) -> Control:
	var t := Patrocinio.tipo_por_id(o["tipo"])
	var linha := Tema.hbox(18)
	linha.add_child(_retrato(o["tipo"]))
	var v := Tema.vbox(8)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	linha.add_child(v)
	v.add_child(Tema.rotulo(str(o["patrono"]), 26, Tema.OURO, true))
	v.add_child(Tema.rotulo(str(t["titulo"]), 18, Tema.CINZA))
	v.add_child(Tema.rotulo(str(t["historia"]), 15, Color("9a8a78")))
	v.add_child(Tema.espaco(4))
	v.add_child(Tema.rotulo("\"Vi %s lutar e o povo gritar o nome dele. Quero meu nome ligado à sua glória.\"" % o["gladNome"], 19, Tema.AREIA))
	v.add_child(Tema.espaco(4))
	v.add_child(Tema.rotulo("Paga %d de ouro por rodada." % int(o["ouro"]), 20, Color("9be05a"), true))
	v.add_child(Tema.rotulo("Meta: %s." % Patrocinio.texto_meta(o), 18, Tema.AREIA))
	v.add_child(Tema.rotulo("Se falhar, só perde o contrato. A proposta vale até a rodada %d." % int(o["validoAte"]), 16, Tema.CINZA))
	v.add_child(Tema.espaco(6))
	var bs := Tema.hbox(10)
	bs.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(bs)
	var ba := Tema.botao("Aceitar", "primario", 20)
	ba.custom_minimum_size = Vector2(150, 48)
	ba.pressed.connect(func(): _responder(Game.aceitar_patrocinio(Jogo.e, str(o["id"]))))
	bs.add_child(ba)
	var br := Tema.botao("Recusar", "normal", 20)
	br.custom_minimum_size = Vector2(150, 48)
	br.pressed.connect(func(): _responder(Game.recusar_patrocinio(Jogo.e, str(o["id"]))))
	bs.add_child(br)
	var bd := Tema.botao("Decidir depois", "normal", 16)
	bd.pressed.connect(func(): _modal.fechar())
	bd.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	bd.custom_minimum_size = Vector2(200, 36)
	v.add_child(bd)
	return linha


func _responder(erro: String) -> void:
	Jogo.resultado(erro)
	if is_instance_valid(_modal):
		_modal.fechar()


## Silhueta provisória (toga) enquanto não há arte do patrício.
class Silhueta extends Control:
	var cor := Color("8a6a3a")

	func _draw() -> void:
		var w := size.x
		var h := size.y
		draw_circle(Vector2(w * 0.5, h * 0.2), h * 0.1, Color(0.3, 0.24, 0.2))
		var corpo := PackedVector2Array([Vector2(w * 0.3, h * 0.32), Vector2(w * 0.7, h * 0.32), Vector2(w * 0.86, h * 0.98), Vector2(w * 0.14, h * 0.98)])
		draw_colored_polygon(corpo, Color(0.22, 0.17, 0.15))
		var faixa := PackedVector2Array([Vector2(w * 0.34, h * 0.32), Vector2(w * 0.46, h * 0.32), Vector2(w * 0.62, h * 0.98), Vector2(w * 0.5, h * 0.98)])
		draw_colored_polygon(faixa, cor)
		draw_string(ThemeDB.fallback_font, Vector2(w * 0.5 - 12, h * 0.21 + 14), "?", HORIZONTAL_ALIGNMENT_LEFT, -1, 38, Color(0.1, 0.08, 0.06))
