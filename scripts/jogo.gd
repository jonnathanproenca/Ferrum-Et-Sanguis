extends Node
## Estado global da partida: salvar/carregar, preferências e avisos. Registrado como autoload "Jogo".

signal mudou          ## o estado da partida mudou (as telas se redesenham)
signal aviso(texto: String)
signal tutorial_pedido(topico: String)
signal navegar(destino: String)    ## "menu", "selecao" ou "jogo"
signal abrir_aba(aba: String)      ## muda a aba do HUD: ludus, upgrades, mercado, armeiro, enfermaria, arenas, campanha, config
signal iniciar_luta(payload: Dictionary, ao_fim: Callable, ao_desistir: Callable, ao_pular: Callable)  ## mostra a cena de luta

const ARQ_PREFS := "user://prefs.json"

signal construiu(id: String)   ## uma melhoria do ludus foi comprada (a cena do ludus anima a obra)

var equipe: Array = []                 ## ids dos gladiadores escalados para a próxima luta (compartilhado por Arenas e Campanha)
var e: Dictionary = {}                 ## Estado da partida (mesma estrutura do jogo em TypeScript)
var prefs: Dictionary = {"audio": {"ativo": true, "musica": 0.5, "efeitos": 0.7}, "cheatLiberado": false, "cheats": {}}
var _tempo_acc := 0.0

func _ready() -> void:
	get_tree().node_added.connect(_ao_entrar_no)
	_ler_prefs()
	_migrar_save_antigo()
	aplicar_escala()

## Fator de zoom da interface. 0 = automático (celular/tablet ganha 1.4x, já que a janela física é grande, mas o dedo e o texto pedem mais).
func aplicar_escala() -> void:
	var f := float(prefs.get("escalaUi", 0.0))
	if f <= 0.0:
		f = 1.4 if DisplayServer.is_touchscreen_available() else 1.0
	var w := get_window()
	if w:
		w.content_scale_factor = f

func _process(delta: float) -> void:
	if e.is_empty():
		return
	_tempo_acc += delta
	if _tempo_acc >= 1.0:
		var s := int(_tempo_acc)
		_tempo_acc -= s
		Game.estatisticas(e)["tempoMs"] += s * 1000
		if int(e["estat"]["tempoMs"]) % 15000 == 0:
			salvar()

# ---------- Perfis e partida ----------

const MAX_PERFIS := 3
const ARQ_ANTIGO := "user://save_v4.json"

var slot := 0               ## perfil em jogo (1 a MAX_PERFIS); 0 = nenhum
var slot_novo := 0          ## perfil onde o próximo ludus será criado
var modo_novo := "imperial" ## modo escolhido para o próximo ludus
var nome_novo := ""         ## nome a manter ao reiniciar um perfil

static func caminho(s: int) -> String:
	return "user://perfil_%d.json" % s

## Traz o save antigo (um só) para o perfil 1, uma única vez.
func _migrar_save_antigo() -> void:
	if not FileAccess.file_exists(ARQ_ANTIGO) or FileAccess.file_exists(caminho(1)):
		return
	var f := FileAccess.open(ARQ_ANTIGO, FileAccess.READ)
	if f == null:
		return
	var txt := f.get_as_text()
	f.close()
	var w := FileAccess.open(caminho(1), FileAccess.WRITE)
	if w:
		w.store_string(txt)
		w.close()
		DirAccess.remove_absolute(ProjectSettings.globalize_path(ARQ_ANTIGO))

func perfil_existe(s: int) -> bool:
	return FileAccess.file_exists(caminho(s))

func tem_save() -> bool:
	for s in range(1, MAX_PERFIS + 1):
		if perfil_existe(s):
			return true
	return false

func primeiro_slot_livre() -> int:
	for s in range(1, MAX_PERFIS + 1):
		if not perfil_existe(s):
			return s
	return 1

func novo(casa_id: String, dificuldade: String, modo: String = "") -> void:
	Model.nomes_usados.clear()
	if slot_novo < 1:
		slot_novo = primeiro_slot_livre()
	slot = slot_novo
	var m := modo if modo != "" else modo_novo
	e = Game.novo_jogo(int(Time.get_unix_time_from_system() * 1000.0) % 2147483646, casa_id, dificuldade, m)
	e["perfilNome"] = nome_novo if nome_novo != "" else "Ludus de %s" % Game.lanista_da_casa(e)["nome"]
	e["criadoEm"] = int(Time.get_unix_time_from_system())
	nome_novo = ""
	if prefs["cheatLiberado"] and not prefs["cheats"].is_empty():
		e["cheats"] = prefs["cheats"].duplicate()
	for c in Game.modo_de(e).get("cheats", []):
		if not e.has("cheats"):
			e["cheats"] = {}
		e["cheats"][c] = true
	if bool(e.get("cheats", {}).get("ouro", false)):
		e["ouro"] = 9999999
	salvar()
	mudou.emit()

## Motivo da última falha ao carregar o save (aparece no menu).
var erro_save := ""

func _ler_json_save(caminho_arq: String) -> Variant:
	var f := FileAccess.open(caminho_arq, FileAccess.READ)
	if f == null:
		erro_save = "arquivo ausente"
		return null
	var txt := f.get_as_text()
	if txt.strip_edges() == "":
		erro_save = "arquivo vazio"
		return null
	var r = JSON.parse_string(txt)
	if r == null:
		# tolera NaN/Infinity gravados como texto
		var rx := RegEx.new()
		rx.compile("(?<![A-Za-z0-9_\"])-?(nan|inf|infinity)(?![A-Za-z0-9_\"])")
		r = JSON.parse_string(rx.sub(txt, "0", true))
	if not (r is Dictionary):
		erro_save = "conteúdo inválido"
		return null
	return r

## Lê o save de um perfil (ou o .bak) sem mexer na partida em curso. Devolve {} se não der.
func ler_perfil(s: int) -> Dictionary:
	erro_save = ""
	var r = _ler_json_save(caminho(s))
	if r == null:
		var motivo := erro_save
		r = _ler_json_save(caminho(s) + ".bak")
		if r == null:
			erro_save = motivo
			return {}
	r = Util.normalizar(r)
	var v := int(r.get("versao", 0))
	if v < 4 or v > 5:
		erro_save = "versão do save %d (esperado 4 ou 5)" % v
		return {}
	if not r.has("melhorias"):
		r["melhorias"] = {}
		for m in Game.MELHORIAS_LUDUS:
			r["melhorias"][m["id"]] = true
	if not r.has("modo"):
		r["modo"] = "imperial"
	if not r.has("perfilNome"):
		r["perfilNome"] = "Ludus de %s" % Game.lanista_da_casa(r).get("nome", "")
	Game.estatisticas(r)
	return r

func continuar(s: int = 0) -> bool:
	var alvo := s if s > 0 else (slot if slot > 0 else 1)
	var r := ler_perfil(alvo)
	if r.is_empty():
		return false
	slot = alvo
	e = r
	if prefs["cheatLiberado"] and not e.has("cheats") and not prefs["cheats"].is_empty():
		e["cheats"] = prefs["cheats"].duplicate()
	if bool(e.get("cheats", {}).get("ouro", false)):
		e["ouro"] = maxi(int(e["ouro"]), 9999999)
	Model.nomes_usados.clear()
	Model.registrar_nomes(e)
	Game.atualizar_fim(e)
	mudou.emit()
	return true

func salvar() -> void:
	if e.is_empty():
		return
	if slot < 1:
		slot = primeiro_slot_livre()
	Game.atualizar_fim(e)
	gravar(slot, e)

## Grava um save com validação; o anterior vira .bak.
func gravar(s: int, dados: Dictionary) -> void:
	var arq := caminho(s)
	var txt := JSON.stringify(dados)
	# só grava se o JSON volta a ser lido
	if not (JSON.parse_string(txt) is Dictionary):
		return
	if FileAccess.file_exists(arq):
		var ant := FileAccess.open(arq, FileAccess.READ)
		if ant != null:
			var t0 := ant.get_as_text()
			ant.close()
			if JSON.parse_string(t0) is Dictionary:
				var b := FileAccess.open(arq + ".bak", FileAccess.WRITE)
				if b:
					b.store_string(t0)
	var f := FileAccess.open(arq, FileAccess.WRITE)
	if f:
		f.store_string(txt)

func renomear_perfil(s: int, nome: String) -> void:
	var n := nome.strip_edges().substr(0, 24)
	if n == "":
		return
	if s == slot and not e.is_empty():
		e["perfilNome"] = n
		salvar()
		return
	var r := ler_perfil(s)
	if r.is_empty():
		return
	r["perfilNome"] = n
	gravar(s, r)

func apagar_save(s: int = 0) -> void:
	var alvo := s if s > 0 else (slot if slot > 0 else 1)
	for suf in ["", ".bak"]:
		if FileAccess.file_exists(caminho(alvo) + suf):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(caminho(alvo) + suf))
	if alvo == slot:
		e = {}
		slot = 0

## Recomeça o perfil em curso: apaga o save e guarda slot, nome e modo para o novo ludus.
func preparar_reinicio() -> void:
	slot_novo = slot if slot > 0 else 1
	modo_novo = str(e.get("modo", "imperial"))
	nome_novo = str(e.get("perfilNome", ""))
	apagar_save()
	e = {}
	equipe = []

## Aplica o resultado de uma ação do jogo (String de erro vazia = sucesso): avisa o erro, ou salva e notifica as telas.
func resultado(erro: String) -> bool:
	if erro != "":
		aviso.emit(erro)
		return false
	salvar()
	mudou.emit()
	return true

## Gladiadores escalados que continuam vivos e com estilo (descarta os demais da lista).
func equipe_valida() -> Array:
	var vivos: Array = e["gladiadores"].filter(func(g): return g["vivo"] and not g.get("semEstilo", false))
	equipe = equipe.filter(func(id): return vivos.any(func(g): return g["id"] == id))
	return equipe.map(func(id): return vivos.filter(func(g): return g["id"] == id)[0])

func notificar() -> void:
	salvar()
	mudou.emit()

# ---------- Preferências ----------

func _ler_prefs() -> void:
	var f := FileAccess.open(ARQ_PREFS, FileAccess.READ)
	if f == null:
		return
	var r = JSON.parse_string(f.get_as_text())
	if r is Dictionary:
		r = Util.normalizar(r)
		for k in r:
			prefs[k] = r[k]

func salvar_prefs() -> void:
	var f := FileAccess.open(ARQ_PREFS, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(prefs))


## Toque no celular: arrastar em qualquer ponto de uma lista rola. Painéis e cartões não podem engolir o toque
## (ficam em PASS), e rolagens aceitam começar o arrasto em cima de botões (zona morta).
func _ao_entrar_no(n: Node) -> void:
	if n is ScrollContainer:
		n.set("scroll_deadzone", 12)
		return
	if not (n is Control):
		return
	var c := n as Control
	if c.mouse_filter != Control.MOUSE_FILTER_STOP:
		return
	if c is BaseButton or c is Range or c is LineEdit or c is TextEdit or c is ItemList or c is Tree or c is TabBar:
		return
	var p := c.get_parent()
	while p != null:
		if p is ScrollContainer:
			c.mouse_filter = Control.MOUSE_FILTER_PASS
			return
		p = p.get_parent()
