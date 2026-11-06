extends Node
## Estado global da partida: salvar/carregar, preferências e avisos. Registrado como autoload "Jogo".

signal mudou          ## o estado da partida mudou (as telas se redesenham)
signal aviso(texto: String)
signal tutorial_pedido(topico: String)
signal navegar(destino: String)    ## "menu", "selecao" ou "jogo"
signal abrir_aba(aba: String)      ## muda a aba do HUD: ludus, upgrades, mercado, armeiro, enfermaria, arenas, campanha, config
signal iniciar_luta(payload: Dictionary, ao_fim: Callable, ao_desistir: Callable, ao_pular: Callable)  ## mostra a cena de luta

const ARQ_SAVE := "user://save_v4.json"
const ARQ_PREFS := "user://prefs.json"

signal construiu(id: String)   ## uma melhoria do ludus foi comprada (a cena do ludus anima a obra)

var equipe: Array = []                 ## ids dos gladiadores escalados para a próxima luta (compartilhado por Arenas e Campanha)
var e: Dictionary = {}                 ## Estado da partida (mesma estrutura do jogo em TypeScript)
var prefs: Dictionary = {"audio": {"ativo": true, "musica": 0.5, "efeitos": 0.7}, "cheatLiberado": false, "cheats": {}}
var _tempo_acc := 0.0

func _ready() -> void:
	get_tree().node_added.connect(_ao_entrar_no)
	_ler_prefs()
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

# ---------- Partida ----------

func tem_save() -> bool:
	return FileAccess.file_exists(ARQ_SAVE)

func novo(casa_id: String, dificuldade: String) -> void:
	Model.nomes_usados.clear()
	e = Game.novo_jogo(int(Time.get_unix_time_from_system() * 1000.0) % 2147483646, casa_id, dificuldade)
	if prefs["cheatLiberado"] and not prefs["cheats"].is_empty():
		e["cheats"] = prefs["cheats"].duplicate()
		if bool(e["cheats"].get("ouro", false)):
			e["ouro"] = 9999999
	salvar()
	mudou.emit()

func continuar() -> bool:
	var f := FileAccess.open(ARQ_SAVE, FileAccess.READ)
	if f == null:
		return false
	var r = JSON.parse_string(f.get_as_text())
	if not (r is Dictionary):
		return false
	r = Util.normalizar(r)
	if int(r.get("versao", 0)) != 4:
		return false
	if not r.has("melhorias"):
		r["melhorias"] = {}
		for m in Game.MELHORIAS_LUDUS:
			r["melhorias"][m["id"]] = true
	e = r
	Game.estatisticas(e)
	if prefs["cheatLiberado"] and not e.has("cheats") and not prefs["cheats"].is_empty():
		e["cheats"] = prefs["cheats"].duplicate()
	if bool(e.get("cheats", {}).get("ouro", false)):
		e["ouro"] = maxi(int(e["ouro"]), 9999999)
	Model.nomes_usados.clear()
	Model.registrar_nomes(e)
	mudou.emit()
	return true

func salvar() -> void:
	if e.is_empty():
		return
	var f := FileAccess.open(ARQ_SAVE, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(e))

func apagar_save() -> void:
	if FileAccess.file_exists(ARQ_SAVE):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(ARQ_SAVE))

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
