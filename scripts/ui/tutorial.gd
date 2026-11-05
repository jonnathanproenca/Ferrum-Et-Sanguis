class_name Tutorial
extends Control
## Overlay de tutorial por tópicos e páginas (porte de tutorial.ts + verificarTutorial de ui.ts).
## Estado em Jogo.e["tutorial"]["vistos"]. Uso pelo Hud (veja o relatório de integração):
##   Tutorial.verificar(self)          # cria o overlay se preciso e abre o próximo tópico pendente
##   tut.mostrar("campanha")           # abre um tópico à força (também via Jogo.tutorial_pedido(topico))
## As páginas com aba pedem a troca de aba com Jogo.abrir_aba.

signal terminou(topico: String)

## Tópicos na ordem de prioridade. "requer": melhoria construída; "aba": aba em que abre na primeira visita.
const TOPICOS: Array = [
	{"id": "tour", "titulo": "Tutorial"},
	{"id": "campanha", "titulo": "Campanha", "aba": "campanha"},
	{"id": "treino", "titulo": "Palus: treinamento", "requer": "palus"},
	{"id": "armeiro", "titulo": "Armaria e armeiro", "requer": "armaria"},
	{"id": "enfermaria", "titulo": "Enfermaria", "requer": "enfermaria"},
	{"id": "alojamentos", "titulo": "Alojamentos", "requer": "alojamentos"},
	{"id": "refeitorio", "titulo": "Refeitório", "requer": "refeitorio"},
]

var _topico := ""
var _pag := 0
var _paginas: Array = []
var _fundo: ColorRect
var _painel: PanelContainer
var _l_cab: Label
var _l_tit: Label
var _l_txt: Label
var _pontos: HBoxContainer
var _b_pular: Button
var _b_prox: Button
var _tw: Tween

# ---------- API estática ----------

static func topico_por_id(id: String) -> Dictionary:
	for t in TOPICOS:
		if t["id"] == id:
			return t
	return {}

static func todos_ids() -> Array:
	return TOPICOS.map(func(t): return t["id"])

## Garante um nó Tutorial filho de `pai` (nome "Tutorial") e pede a ele que abra o próximo tópico pendente.
## A aba atual é lida de `pai.aba_atual()` (o Hud tem esse método).
static func verificar(pai: Node) -> Tutorial:
	var t: Tutorial = pai.get_node_or_null("Tutorial") as Tutorial
	if t == null:
		t = Tutorial.new()
		t.name = "Tutorial"
		pai.add_child(t)
	var aba := ""
	if pai.has_method("aba_atual"):
		aba = str(pai.call("aba_atual"))
	t.checar(aba)
	return t

## Páginas de um tópico para o estado `e` (cada uma: titulo, texto e, opcionalmente, aba).
static func paginas_de(id: String, e: Dictionary) -> Array:
	match id:
		"tour":
			return _tour(e)
		"campanha":
			return [
				{"titulo": "Os lanistas rivais", "texto": "A campanha enfrenta, numa sequência fixa e própria da sua casa, todos os outros lanistas. As silhuetas ainda não foram reveladas e os vencidos ficam riscados. Depois deles surge um desafio bônus: o lanista Batiatus e seu campeão, Espártaco. Cada passo tem uma regra própria e requisitos, como vitórias na arena ou um gladiador equipado."},
				{"titulo": "Até a morte", "texto": "Nas lutas da campanha ninguém se rende: vai até a morte. Alguns passos são 2×2. Prepare seu time antes de entrar na arena."},
			]
		"treino":
			return _com_aba("ludus", [{"titulo": "Treinar gladiadores", "texto": "Com o palus pronto, cada card de gladiador ganha botões de treino. Treinar custa 1 de energia e 20 de ouro, soma +1 no atributo escolhido (máximo 10 por atributo) e dá experiência. Escravos recém-comprados treinam mesmo sem estilo."}])
		"armeiro":
			return _com_aba("armeiro", [
				{"titulo": "Peças especiais", "texto": "O armeiro mestre oferece 5 peças por rodada, todas melhores que as básicas. As chances de qualidade: Superior 60%, Rara 25%, Épica 11% e Lendária 4%. Cada rodada tem no máximo 3 verdes, 2 azuis, 2 roxas e 1 laranja."},
				{"titulo": "Equipar", "texto": "Comprada a peça, ela vai para o armeiro. Abra o card do gladiador e escolha a peça em cada espaço: arma, elmo, peito, acessório, perna e pé. Cada peça serve a certos estilos. As básicas já vêm com o estilo."},
			])
		"enfermaria":
			return _com_aba("enfermaria", [{"titulo": "Tratar os feridos", "texto": "O médico trata os efeitos persistentes que o Poço deixa. Tratar custa 1 de energia e 30 de ouro por ponto de severidade, e remove todos os efeitos do gladiador. Sem tratamento, os efeitos continuam reduzindo os atributos."}])
		"alojamentos":
			return [{"titulo": "Mais espaço", "texto": "O ludus passa a comportar %d gladiadores, em vez de %d. Lembre que cada gladiador vivo aumenta a manutenção por turno." % [Game.MAX_GLADIADORES, Game.CAPACIDADE_BASE]}]
		"refeitorio":
			return [{"titulo": "Manutenção menor", "texto": "A manutenção por gladiador cai de 5 para 3 de ouro por turno. Quanto mais gladiadores, mais o refeitório economiza."}]
	return []

static func _com_aba(aba: String, paginas: Array) -> Array:
	for p in paginas:
		p["aba"] = aba
	return paginas

static func _progressao(e: Dictionary) -> String:
	var r: Dictionary = Game.regras_de(e)
	var campeao: String = "Seu primeiro gladiador já começa como campeão." if int(r["campeao"]) == 0 \
		else "O primeiro gladiador a chegar a %d vitórias vira o campeão." % int(r["campeao"])
	var liberdade: String = "Nesta dificuldade a lenda nunca é libertada." if r["liberdade"] == null \
		else "Depois de %d lutas como lenda, ele conquista a liberdade e deixa o ludus." % int(r["liberdade"])
	return "%s O campeão ganha +2 em todos os atributos e rende patrocínio por turno, mas não entra no Poço nem é vendido. Com %d vitórias um gladiador vira lenda (+1 em tudo; só uma lenda viva por vez). %s" % [campeao, int(r["lenda"]), liberdade]

## Tour inicial: ludus, upgrades, mercado, arenas e volta ao ludus.
static func _tour(e: Dictionary) -> Array:
	var p: Array = []
	p.append_array(_com_aba("ludus", [
		{"titulo": "Bem-vindo, lanista de %s" % Game.lanista_da_casa(e)["nome"], "texto": "Esta é a tela do ludus: aqui ficam os seus gladiadores. Toque num card para ver atributos, equipamento e ações. Na barra de cima estão ouro, energia, turno e vitórias. As abas levam às outras partes do ludus."},
		{"titulo": "Energia e turnos", "texto": "Cada rodada dá 3 de energia. Lutar, treinar, tratar feridos e trocar de estilo gastam energia. Quando ela acabar, toque em Próximo turno: o ludus paga a manutenção (10 de ouro + 5 por gladiador vivo) e o campeão rende patrocínio (20 + 5 por vitória dele). O mercado se renova a cada turno."},
		{"titulo": "Campeão, lenda e liberdade", "texto": _progressao(e)},
	]))
	p.append_array(_com_aba("upgrades", [
		{"titulo": "Upgrades: construa seu ludus", "texto": "Cada upgrade constrói uma seção nova e libera uma mecânica: palus (treino), armaria (equipamentos), enfermaria (tratar feridos), alojamentos (mais gladiadores) e refeitório (manutenção menor). Compre com ouro; quando a obra termina, o tutorial da seção aparece."},
		{"titulo": "Por onde começar", "texto": "Palus e armaria deixam seus gladiadores mais fortes, e os alojamentos abrem espaço para mais lutadores. Compre o que a sua estratégia pede primeiro."},
	]))
	p.append_array(_com_aba("mercado", [
		{"titulo": "Mercado: só escravos", "texto": "O mercado vende 5 escravos novos a cada turno. Eles chegam sem estilo e sem equipamento. Cada um tem uma terra de origem, uma tendência de atributo e uma condição física que muda o preço: jovem é mais caro, cicatrizado mais barato."},
		{"titulo": "Escolha o estilo", "texto": "Depois de comprar, escolha o estilo dele: Murmilo, Retiário, Trácio ou Samnita. É grátis, não gasta energia e já entrega o kit básico do estilo. Escravo sem estilo não luta, só treina. Trocar de estilo mais tarde custa ouro e energia."},
		{"titulo": "Espaço no ludus", "texto": "O ludus comporta %d gladiadores. Com os alojamentos, o limite sobe para %d. Escravos que não servem podem ser vendidos pela metade do preço." % [Game.CAPACIDADE_BASE, Game.MAX_GLADIADORES]},
	]))
	p.append_array(_com_aba("arenas", [
		{"titulo": "Arenas: escalar e lutar", "texto": "Toque nos gladiadores para escalar 1 ou 2 e escolha a arena. Cada gladiador gasta 1 de energia; no 2×2 a recompensa em ouro dobra. Quem cai abaixo de 25% de vida se rende, então a luta termina antes da morte."},
		{"titulo": "Fama e dificuldade", "texto": "Você começa em Pompeia. Cápua abre com 8 batalhas disputadas e o Coliseu com 24, vencendo ou não. Quanto melhor a arena, mais forte o rival e maior a recompensa."},
		{"titulo": "O Poço", "texto": "No Poço os golpes deixam efeitos persistentes (sangramento, veneno, contusão, queimadura), que enfraquecem o gladiador até serem tratados. Quem luta no Poço não volta às arenas de honra, e o campeão não entra."},
		{"titulo": "Durante a luta", "texto": "Pular luta mostra o resultado na hora, com 10% a menos de ouro. Desistir conta como derrota, sem recompensa, e a energia gasta não volta."},
	]))
	p.append_array(_com_aba("ludus", [
		{"titulo": "Primeiro passo", "texto": "De volta ao ludus. Vá ao Mercado, compre escravos, escolha o estilo deles e mande-os para Pompeia. Ouro e fama abrem o resto. Boa sorte, lanista!"},
	]))
	return p

# ---------- Estado ----------

## Há um tópico aberto?
func ativo() -> bool:
	return _topico != ""

static func _vistos(e: Dictionary) -> Array:
	if not e.has("tutorial") or not (e["tutorial"] is Dictionary):
		e["tutorial"] = {"vistos": todos_ids() if int(e["turno"]) > 1 else []}
	return e["tutorial"]["vistos"]

static func _visto(vistos: Array, id: String) -> bool:
	return vistos.has(id) or (id == "tour" and vistos.has("ludus"))

## Abre sozinho o próximo tópico ainda não visto que já esteja liberado (tour sempre; os demais pela melhoria ou pela aba).
func checar(aba: String) -> void:
	if ativo() or Jogo.e.is_empty():
		return
	var e: Dictionary = Jogo.e
	var vistos: Array = _vistos(e)
	for t in TOPICOS:
		var id: String = t["id"]
		if _visto(vistos, id):
			continue
		var liberado: bool
		if id == "tour":
			liberado = true
		elif t.has("requer"):
			liberado = Game.tem_melhoria(e, str(t["requer"]))
		else:
			liberado = str(t.get("aba", "")) == aba
		if liberado:
			mostrar(id)
			return

# ---------- Interface ----------

func _ready() -> void:
	name = "Tutorial"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_as_relative = false
	z_index = 4000
	visible = false
	_montar()
	Jogo.tutorial_pedido.connect(mostrar)

func _montar() -> void:
	_fundo = ColorRect.new()
	_fundo.color = Color(0.02, 0.01, 0.01, 0.62)
	_fundo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fundo.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_fundo)
	var centro := CenterContainer.new()
	centro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	centro.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(centro)
	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_bottom", 0)
	centro.add_child(m)
	_painel = PanelContainer.new()
	var sb := Tema.caixa(Color("22140f"), Tema.OURO_ESCURO, 4, 2, 14)
	sb.content_margin_left = 26
	sb.content_margin_right = 26
	sb.content_margin_top = 18
	sb.content_margin_bottom = 18
	sb.shadow_color = Color(0, 0, 0, 0.75)
	sb.shadow_size = 28
	sb.shadow_offset = Vector2(0, 10)
	sb.set_expand_margin_all(3)
	_painel.add_theme_stylebox_override("panel", sb)
	_painel.custom_minimum_size = Vector2(540, 0)
	m.add_child(_painel)
	var v := Tema.vbox(8)
	_painel.add_child(v)
	_l_cab = Tema.rotulo("", 14, Tema.OURO_ESCURO, true)
	_l_cab.autowrap_mode = TextServer.AUTOWRAP_OFF
	v.add_child(_l_cab)
	_l_tit = Tema.rotulo("", 28, Color("f2e6c8"), true)
	v.add_child(_l_tit)
	var linha := ColorRect.new()
	linha.color = Tema.BORDA
	linha.custom_minimum_size = Vector2(0, 2)
	v.add_child(linha)
	_l_txt = Tema.rotulo("", 20, Tema.AREIA)
	_l_txt.custom_minimum_size = Vector2(0, 110)
	v.add_child(_l_txt)
	var h := Tema.hbox(12)
	v.add_child(h)
	_pontos = Tema.hbox(6)
	_pontos.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_pontos.alignment = BoxContainer.ALIGNMENT_BEGIN
	h.add_child(_pontos)
	_b_pular = Tema.botao("Pular tutorial", "normal", 18)
	_b_pular.pressed.connect(fechar)
	h.add_child(_b_pular)
	_b_prox = Tema.botao("Próximo", "primario", 18)
	_b_prox.custom_minimum_size = Vector2(120, 40)
	_b_prox.pressed.connect(_proxima)
	h.add_child(_b_prox)

## Abre o tópico `id` na primeira página (volta à aba da página, se houver).
func mostrar(id: String) -> void:
	if Jogo.e.is_empty():
		return
	var pgs: Array = paginas_de(id, Jogo.e)
	if pgs.is_empty():
		return
	_topico = id
	_pag = 0
	_paginas = pgs
	visible = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	_painel.modulate.a = 0.0
	_fundo.modulate.a = 0.0
	if _tw:
		_tw.kill()
	_tw = create_tween().set_parallel(true)
	_tw.tween_property(_fundo, "modulate:a", 1.0, 0.25)
	_tw.tween_property(_painel, "modulate:a", 1.0, 0.25)
	_desenhar()
	_ir_aba()

func _ir_aba() -> void:
	var aba: String = str(_paginas[_pag].get("aba", ""))
	if aba != "":
		Jogo.abrir_aba.emit(aba)

func _desenhar() -> void:
	var t: Dictionary = topico_por_id(_topico)
	var p: Dictionary = _paginas[_pag]
	var ultima: bool = _pag == _paginas.size() - 1
	_l_cab.text = ("%s · %d/%d" % [t.get("titulo", ""), _pag + 1, _paginas.size()]).to_upper()
	_l_tit.text = str(p["titulo"])
	_l_txt.text = str(p["texto"])
	_b_pular.text = "Fechar" if ultima else "Pular tutorial"
	_b_prox.visible = not ultima
	Tema.limpar(_pontos)
	for i in range(_paginas.size()):
		var d := ColorRect.new()
		d.custom_minimum_size = Vector2(22 if i == _pag else 10, 6)
		d.color = Tema.OURO if i == _pag else Tema.BORDA
		d.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		_pontos.add_child(d)

func _proxima() -> void:
	if _pag < _paginas.size() - 1:
		_pag += 1
		_desenhar()
		_ir_aba()
	else:
		fechar()

## Fecha o tópico atual marcando-o como visto (tour: volta ao ludus) e procura o próximo pendente.
func fechar() -> void:
	if not ativo():
		return
	var id := _topico
	if not Jogo.e.is_empty():
		var vistos: Array = _vistos(Jogo.e)
		if not vistos.has(id):
			vistos.append(id)
		Jogo.salvar()
	_topico = ""
	_paginas = []
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if id == "tour":
		Jogo.abrir_aba.emit("ludus")
	terminou.emit(id)
	# o Hud chama verificar() ao trocar de aba; se houver outro tópico liberado (ex.: melhoria já construída), abre agora
	var pai := get_parent()
	if pai:
		Tutorial.verificar.call_deferred(pai)

func _unhandled_key_input(ev: InputEvent) -> void:
	if not ativo():
		return
	if ev.is_action_pressed("ui_accept") and _b_prox.visible:
		_proxima()
		get_viewport().set_input_as_handled()
	elif ev.is_action_pressed("ui_cancel"):
		fechar()
		get_viewport().set_input_as_handled()
