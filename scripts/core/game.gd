class_name Game
extends RefCounted
## Regras da gestão do ludus (porte fiel de game.ts).
## Convenção de erros: as ações devolvem String ("" = sucesso, senão a mensagem); lutar_* devolvem um Dictionary com "erro" se falharem.

const OURO_INICIAL := 300
const ENERGIA_TURNO := 3
const MAX_GLADIADORES := 12
const CUSTO_BASE := 10
const CUSTO_POR_GLADIADOR := 5
const CUSTO_POR_GLADIADOR_REFEITORIO := 3
const CAPACIDADE_BASE := 4
const PRECO_TREINO := 20
const TREINO_MAXIMO := 10
const MAX_LOG := 40
const CHANCE_LIBERTO := 0.03
const PENALIDADE_PULO := 0.1
const PECAS_MESTRE := 5
const MAX_VERDES_SEGUIDOS := 2
const NOME_CAMPEAO_FINAL := "Espártaco"
const CAMPEAO_NIVEL: Array = [1, 2, 3, 5, 6, 8, 10, 11, 13, 15]
const CAMPEAO_QUALIDADE: Array = [0, 0, 0, 1, 1, 2, 2, 3, 3, 4]
const CHANCE_MESTRE: Array = [
	{"qualidade": 1, "chance": 0.6}, {"qualidade": 2, "chance": 0.25},
	{"qualidade": 3, "chance": 0.11}, {"qualidade": 4, "chance": 0.04},
]
const LIMITE_QUALIDADE_MESTRE := {1: 3, 2: 2, 3: 2, 4: 1}
const LOTACOES_ORDEM: Array = ["vazia", "meia", "cheia"]
const LOTACOES_POCO := {"vazia": {"bonus": 10, "moedas": [3, 4]}, "meia": {"bonus": 20, "moedas": [5, 9]}, "cheia": {"bonus": 30, "moedas": [10, 20]}}
const NOME_EFEITO := {"sangramento": "Sangramento", "envenenamento": "Envenenamento", "contusao": "Contusão", "queimadura": "Queimadura"}

const MELHORIAS_LUDUS: Array = [
	{"id": "palus", "nome": "Palus e bonecos de treino", "custo": 200, "efeito": "Permite treinar os atributos dos gladiadores."},
	{"id": "enfermaria", "nome": "Enfermaria", "custo": 300, "efeito": "Permite tratar os efeitos deixados pelo Poço."},
	{"id": "armaria", "nome": "Armaria", "custo": 350, "efeito": "Abre o armeiro: compra e troca de equipamentos."},
	{"id": "alojamentos", "nome": "Alojamentos", "custo": 500, "efeito": "Amplia o ludus de 4 para 12 gladiadores."},
	{"id": "refeitorio", "nome": "Refeitório", "custo": 250, "efeito": "Reduz a manutenção por gladiador de 5 para 3 de ouro."},
]

const DIFICULDADES_ORDEM: Array = ["facil", "medio", "dificil", "extremo"]
const REGRAS := {
	"facil": {"nome": "Fácil", "campeao": 0, "lenda": 3, "liberdade": null, "precos": 0.8, "arenaBase": 0.9, "arenaFator": 0.7, "campReq": 0.7,
		"campMult": [0.55, 0.5, 0.74, 0.83, 0.95, 1.04, 1.08, 1.06, 1.32, 1.01],
		"resumo": "Já começa com campeão. Lenda com 3 vitórias. Nunca é libertado. Preços −20%, rivais mais fracos."},
	"medio": {"nome": "Médio", "campeao": 3, "lenda": 9, "liberdade": null, "precos": 1.0, "arenaBase": 1.0, "arenaFator": 1.0, "campReq": 1.0,
		"campMult": [0.6, 0.89, 1.03, 1.12, 1.12, 1.31, 1.21, 1.27, 1.45, 1.18],
		"resumo": "Campeão com 3 vitórias, lenda com 9. Nunca é libertado. Preços e rivais padrão."},
	"dificil": {"nome": "Difícil", "campeao": 6, "lenda": 15, "liberdade": 30, "precos": 1.25, "arenaBase": 1.05, "arenaFator": 1.15, "campReq": 1.6,
		"campMult": [0.66, 0.95, 1.06, 1.15, 1.18, 1.38, 1.25, 1.31, 1.48, 1.24],
		"resumo": "Campeão com 6 vitórias, lenda com 15. Libertado após 30 lutas como lenda. Preços +25%, rivais mais fortes."},
	"extremo": {"nome": "Extremo", "campeao": 15, "lenda": 45, "liberdade": 5, "precos": 1.6, "arenaBase": 1.1, "arenaFator": 1.3, "campReq": 2.4,
		"campMult": [1.03, 1.21, 1.37, 1.25, 1.39, 1.45, 1.41, 1.38, 1.64, 1.25],
		"resumo": "Campeão com 15 vitórias, lenda com 45. Libertado após só 5 lutas como lenda. Preços +60%, rivais brutais."},
}
const CHEATS_NOMES := {
	"ouro": "Dinheiro infinito", "vida": "Vida infinita (ninguém morre nem fica ferido)", "vencer": "Ganhar toda luta automaticamente",
	"pular": "Pular luta sem perder recompensa", "lendario": "100% itens lendários no armeiro", "energia": "Energia infinita",
	"round": "Pular rodada sem gastar energia", "campanha": "Ignorar as condições da campanha (pular todos os passos)",
}

static var _lanistas: Array = []
static var _arenas: Array = []
static var _passos: Array = []

static func lanistas() -> Array:
	if _lanistas.is_empty():
		_lanistas = Util.ler_json("res://data/lanistas.json")
	return _lanistas

static func arenas() -> Array:
	if _arenas.is_empty():
		_arenas = Util.ler_json("res://data/arenas.json")
	return _arenas

static func passos() -> Array:
	if _passos.is_empty():
		_passos = Util.ler_json("res://data/campanha.json")["passos"]
	return _passos

const FINAIS: Array = [
	{"id": "batiatus", "nome": "Lêntulo Batiatus", "especialidade": "dimachaerus", "titulo": "O lanista de Cápua", "historia": "Dono do ludus mais temido da Campânia. Só aceita enfrentar quem já provou valor."},
]

# ---------- Utilitários internos ----------

static func jsround(x: float) -> int:
	return Model.jsround(x)

static func regras_de(e: Dictionary) -> Dictionary:
	var d: String = str(e.get("config", {}).get("dificuldade", "medio"))
	return REGRAS.get(d, REGRAS["medio"])

static func estatisticas(e: Dictionary) -> Dictionary:
	if not e.has("estat"):
		e["estat"] = {"ouroGanho": 0, "mortes": 0, "recrutados": 0, "tempoMs": 0}
	return e["estat"]

static func proximo_rng(e: Dictionary) -> Rng:
	var mestre := Rng.new(int(e["semente"]))
	e["semente"] = mestre.inteiro(1, 2147483646)
	return Rng.new(mestre.inteiro(1, 2147483646))

static func novo_id(e: Dictionary) -> String:
	var id := "g%d" % int(e["proximoId"])
	e["proximoId"] = int(e["proximoId"]) + 1
	return id

static func registrar(e: Dictionary, mensagem: String) -> void:
	e["log"].insert(0, mensagem)
	if e["log"].size() > MAX_LOG:
		e["log"].resize(MAX_LOG)

static func achar(e: Dictionary, id: String) -> Dictionary:
	for g in e["gladiadores"]:
		if g["id"] == id:
			return g
	return {}

static func _exigir_vivo(g: Dictionary) -> String:
	return "" if g["vivo"] else "%s está morto." % g["nome"]

static func _exigir_com_estilo(g: Dictionary) -> String:
	if g.get("semEstilo", false):
		return "%s ainda não tem estilo: escolha-o no ludus antes de lutar ou trocar de equipamento." % g["nome"]
	return ""

static func _cheat(e: Dictionary, nome: String) -> bool:
	return bool(e.get("cheats", {}).get(nome, false))

static func pagar(e: Dictionary, energia: int, ouro: int) -> String:
	if not _cheat(e, "energia") and int(e["energia"]) < energia:
		return "Energia insuficiente neste turno."
	if not _cheat(e, "ouro") and int(e["ouro"]) < ouro:
		return "Ouro insuficiente."
	if not _cheat(e, "energia"):
		e["energia"] = int(e["energia"]) - energia
	if not _cheat(e, "ouro"):
		e["ouro"] = int(e["ouro"]) - ouro
	return ""

static func lanista_por_id(id: String) -> Dictionary:
	for l in lanistas():
		if l["id"] == id:
			return l
	return {}

## Bônus da casa se for do tipo pedido; {} caso contrário.
static func bonus_da_casa(e: Dictionary, tipo: String) -> Dictionary:
	var l := lanista_por_id(str(e["casaId"]))
	if l.has("bonus") and l["bonus"]["tipo"] == tipo:
		return l["bonus"]
	return {}

static func extra_da_casa(e: Dictionary) -> Dictionary:
	var b := bonus_da_casa(e, "statsTodos")
	if not b.is_empty() and b.has("atributo"):
		return {b["atributo"]: b["valor"]}
	return {}

static func preco_recruta(e: Dictionary, g: Dictionary) -> int:
	var b := bonus_da_casa(e, "precoEscravo")
	var preco := jsround(float(Model.preco_gladiador(g)) * float(regras_de(e)["precos"]))
	if not b.is_empty() and g["origem"] == "escravo":
		return jsround(float(preco) * float(b["valor"]))
	return preco

static func preco_item(e: Dictionary, item: Dictionary) -> int:
	return jsround(float(item["preco"]) * float(regras_de(e)["precos"]))

static func preco_troca_estilo(e: Dictionary, g: Dictionary) -> int:
	return jsround(float(Model.preco_troca(g)) * float(regras_de(e)["precos"]))

static func melhoria_por_id(id: String) -> Dictionary:
	for m in MELHORIAS_LUDUS:
		if m["id"] == id:
			return m
	return {}

static func custo_melhoria(e: Dictionary, id: String) -> int:
	var b := bonus_da_casa(e, "precoUpgrade")
	var custo := jsround(float(melhoria_por_id(id)["custo"]) * float(regras_de(e)["precos"]))
	if not b.is_empty():
		return jsround(float(custo) * float(b["valor"]))
	return custo

static func tem_melhoria(e: Dictionary, id: String) -> bool:
	return e.get("melhorias", {}).get(id, false) == true

static func _exigir_melhoria(e: Dictionary, id: String) -> String:
	if not tem_melhoria(e, id):
		return "É preciso construir: %s." % melhoria_por_id(id)["nome"]
	return ""

static func capacidade_ludus(e: Dictionary) -> int:
	return MAX_GLADIADORES if tem_melhoria(e, "alojamentos") else CAPACIDADE_BASE

static func lanista_da_casa(e: Dictionary) -> Dictionary:
	return lanista_por_id(str(e["casaId"]))

static func arena_por_id(id: String) -> Dictionary:
	for a in arenas():
		if a["id"] == id:
			return a
	return {}

static func multiplicador_arena(arena: Dictionary, dif: String = "medio") -> float:
	var r: Dictionary = REGRAS[dif]
	if not arena["honra"]:
		return float(r["arenaBase"]) * (1.0 + float(arena["dificuldade"]) * float(r["arenaFator"]))
	var m: float = float(r["arenaBase"])
	for a in arenas():
		if not a["honra"]:
			continue
		m *= 1.0 + float(a["dificuldade"]) * float(r["arenaFator"])
		if a["id"] == arena["id"]:
			break
	return m

static func batalhas_do_ludus(e: Dictionary) -> int:
	return int(e["batalhasTotais"]) if e.has("batalhasTotais") else int(e["vitoriasTotais"])

static func arena_liberada(e: Dictionary, arena: Dictionary) -> Dictionary:
	var faltam: int = maxi(0, int(arena["batalhasMin"]) - batalhas_do_ludus(e))
	return {"liberada": faltam == 0, "faltam": faltam}

static func hash_texto(t: String) -> int:
	var h: int = 2166136261
	for i in range(t.length()):
		h = ((h ^ t.unicode_at(i)) * 16777619) & 0xFFFFFFFF
	return h

static func sequencia_campanha(casa_id: String) -> Array:
	var outros: Array = lanistas().filter(func(l): return l["id"] != casa_id)
	var rng := Rng.new(hash_texto(casa_id))
	var i := outros.size() - 1
	while i > 0:
		var j := rng.inteiro(0, i)
		var tmp = outros[i]
		outros[i] = outros[j]
		outros[j] = tmp
		i -= 1
	return outros + FINAIS

static func fila_lanistas(e: Dictionary) -> Array:
	return sequencia_campanha(str(e["casaId"]))

static func criar_campeao_rival(rng: Rng, l: Dictionary, indice: int) -> Dictionary:
	var i := maxi(0, mini(CAMPEAO_NIVEL.size() - 1, indice))
	var g := Model.gerar_gladiador(rng, "campeao-%s" % l["id"], l["especialidade"], CAMPEAO_NIVEL[i], "livre", true, CAMPEAO_QUALIDADE[i])
	if l["id"] == "batiatus":
		g["nome"] = NOME_CAMPEAO_FINAL
	return g

# ---------- Partida ----------

static func novo_jogo(semente: int, casa_id: String = "", dificuldade: String = "") -> Dictionary:
	var e := {
		"versao": 4, "semente": semente if semente != 0 else 1, "casaId": "", "ouro": OURO_INICIAL, "energia": ENERGIA_TURNO,
		"turno": 1, "proximoId": 1, "vitoriasTotais": 0, "campanha": 0, "libertados": [], "config": {"dificuldade": "medio"},
		"gladiadores": [], "mercado": [], "inventario": [], "campeoesRivais": {}, "melhorias": {}, "log": [],
	}
	if dificuldade != "":
		e["config"] = {"dificuldade": dificuldade}
	var rng := proximo_rng(e)
	var sorteado: String = lanistas()[rng.inteiro(0, lanistas().size() - 1)]["id"]
	e["casaId"] = casa_id if casa_id != "" and not lanista_por_id(casa_id).is_empty() else sorteado
	var casa := lanista_da_casa(e)
	var b_ouro := bonus_da_casa(e, "ouroInicial")
	if not b_ouro.is_empty():
		e["ouro"] = int(e["ouro"]) + int(b_ouro["valor"])
	estatisticas(e)
	var b_nivel := bonus_da_casa(e, "campeaoNivel")
	var nivel_campeao: int = 4 + (int(b_nivel["valor"]) if not b_nivel.is_empty() else 0)
	e["gladiadores"].append(Model.gerar_gladiador(rng, novo_id(e), casa["especialidade"], nivel_campeao, "livre", int(regras_de(e)["campeao"]) == 0))
	var fila := fila_lanistas(e)
	for i in range(fila.size()):
		e["campeoesRivais"][fila[i]["id"]] = criar_campeao_rival(rng, fila[i], i)
	gerar_mercado(e)
	gerar_armeiro_mestre(e)
	var r := regras_de(e)
	var campeao_txt: String = "seu primeiro gladiador já é o campeão" if int(r["campeao"]) == 0 else "com %d vitórias, um deles será o campeão" % int(r["campeao"])
	registrar(e, "Você comanda %s, casa de %s. Dificuldade %s: %s." % [casa["nome"], Model.classes()[casa["especialidade"]]["nome"], r["nome"], campeao_txt])
	return e

static func gerar_mercado(e: Dictionary) -> void:
	var rng := proximo_rng(e)
	e["mercado"] = []
	for i in range(5):
		e["mercado"].append(Model.gerar_escravo(rng, novo_id(e)))

static func sortear_qualidades_mestre(proximo: Callable, n: int = PECAS_MESTRE) -> Array:
	var res: Array = []
	var cont := {1: 0, 2: 0, 3: 0, 4: 0}
	for i in range(n):
		var verdes_seguidos := false
		if res.size() >= MAX_VERDES_SEGUIDOS:
			verdes_seguidos = true
			for q in res.slice(res.size() - MAX_VERDES_SEGUIDOS):
				if q != 1:
					verdes_seguidos = false
		var permitidas: Array = CHANCE_MESTRE.filter(func(c): return cont[c["qualidade"]] < LIMITE_QUALIDADE_MESTRE[c["qualidade"]] and not (c["qualidade"] == 1 and verdes_seguidos))
		var total := 0.0
		for c in permitidas:
			total += float(c["chance"])
		var r: float = float(proximo.call()) * total
		var escolhida: int = permitidas[permitidas.size() - 1]["qualidade"]
		for c in permitidas:
			if r < float(c["chance"]):
				escolhida = c["qualidade"]
				break
			r -= float(c["chance"])
		cont[escolhida] += 1
		res.append(escolhida)
	return res

static func gerar_armeiro_mestre(e: Dictionary) -> void:
	var rng := proximo_rng(e)
	var pool: Array = []
	for i in Model.itens():
		if not i.get("basico", false):
			pool.append(i["id"])
	var qualidades: Array = []
	if _cheat(e, "lendario"):
		for i in range(PECAS_MESTRE):
			qualidades.append(Model.QUALIDADE_MAX)
	else:
		qualidades = sortear_qualidades_mestre(func(): return rng.proximo())
	var oferta: Array = []
	for q in qualidades:
		var base: String = pool[rng.inteiro(0, pool.size() - 1)]
		while oferta.any(func(o): return Model.separar_id(o)["base"] == base):
			base = pool[rng.inteiro(0, pool.size() - 1)]
		oferta.append(Model.com_qualidade(base, q))
	e["armeiroMestre"] = oferta

static func comprar_mestre(e: Dictionary, item_id: String) -> String:
	var err := _exigir_melhoria(e, "armaria")
	if err != "": return err
	var idx: int = e.get("armeiroMestre", []).find(item_id)
	if idx < 0:
		return "Esta peça não está mais à venda."
	err = comprar_item(e, item_id)
	if err != "": return err
	e["armeiroMestre"].remove_at(idx)
	return ""

static func _pode_recrutar(e: Dictionary) -> bool:
	if e["gladiadores"].size() >= capacidade_ludus(e):
		return false
	return e["mercado"].any(func(m): return int(e["ouro"]) >= preco_recruta(e, m))

static func pode_gastar_energia(e: Dictionary) -> bool:
	if int(e["energia"]) <= 0:
		return false
	if e["gladiadores"].any(func(g): return g["vivo"] and (not g["pocoOnly"] or not g["campeao"])):
		return true
	return _pode_recrutar(e)

static func game_over(e: Dictionary) -> bool:
	return not e["gladiadores"].any(func(g): return g["vivo"]) and not _pode_recrutar(e)

static func avancar_turno(e: Dictionary) -> String:
	if not _cheat(e, "round") and pode_gastar_energia(e):
		return "Gaste toda a energia antes de encerrar a rodada (restam %d): lute nas arenas, treine ou troque de estilo." % int(e["energia"])
	e["turno"] = int(e["turno"]) + 1
	e["energia"] = ENERGIA_TURNO
	var ouro_antes: int = int(e["ouro"])
	var patrocinio := 0
	var campeao: Dictionary = {}
	for g in e["gladiadores"]:
		if g["campeao"]:
			campeao = g
			break
	if not campeao.is_empty() and campeao["vivo"]:
		var bp := bonus_da_casa(e, "patrocinio")
		patrocinio = jsround(float(20 + 5 * int(campeao["vitorias"])) * (float(bp["valor"]) if not bp.is_empty() else 1.0))
		e["ouro"] = int(e["ouro"]) + patrocinio
		estatisticas(e)["ouroGanho"] += patrocinio
	var vivos := 0
	for g in e["gladiadores"]:
		if g["vivo"]:
			vivos += 1
	var por_gladiador: int = CUSTO_POR_GLADIADOR_REFEITORIO if tem_melhoria(e, "refeitorio") else CUSTO_POR_GLADIADOR
	var bm := bonus_da_casa(e, "manutencao")
	var custo := jsround(float(CUSTO_BASE + por_gladiador * vivos) * (float(bm["valor"]) if not bm.is_empty() else 1.0))
	if int(e["ouro"]) < custo:
		registrar(e, "Ouro insuficiente para a manutenção do ludus: pagou-se tudo o que havia.")
	var pago: int = mini(custo, int(e["ouro"]))
	e["ouro"] = int(e["ouro"]) - pago
	var saldo: int = int(e["ouro"]) - ouro_antes
	var p1: String = "patrocínio do campeão %s +%d" % [campeao["nome"], patrocinio] if patrocinio > 0 else "sem patrocínio"
	registrar(e, "Turno %d: %s, manutenção −%d (saldo %s%d de ouro)." % [int(e["turno"]), p1, custo, "+" if saldo >= 0 else "", saldo])
	gerar_mercado(e)
	gerar_armeiro_mestre(e)
	return ""

# ---------- Ludus ----------

static func construir_melhoria(e: Dictionary, id: String) -> String:
	var m := melhoria_por_id(id)
	if tem_melhoria(e, id):
		return "%s já foi construído." % m["nome"]
	var custo := custo_melhoria(e, id)
	var err := pagar(e, 0, custo)
	if err != "": return err
	e["melhorias"][id] = true
	registrar(e, "Construído: %s (−%d de ouro)." % [m["nome"], custo])
	return ""

static func recrutar(e: Dictionary, id: String) -> String:
	var idx := -1
	for i in range(e["mercado"].size()):
		if e["mercado"][i]["id"] == id:
			idx = i
			break
	if idx < 0:
		return "Gladiador não está no mercado."
	var capacidade := capacidade_ludus(e)
	if e["gladiadores"].size() >= capacidade:
		return "O ludus comporta no máximo %d gladiadores.%s" % [capacidade, " Construa os alojamentos para ampliar." if capacidade < MAX_GLADIADORES else ""]
	var g: Dictionary = e["mercado"][idx]
	var err := pagar(e, 0, preco_recruta(e, g))
	if err != "": return err
	e["mercado"].remove_at(idx)
	e["gladiadores"].append(g)
	estatisticas(e)["recrutados"] += 1
	if g.get("semEstilo", false):
		registrar(e, "%s foi comprado. Escolha o estilo em que ele vai lutar." % g["nome"])
	else:
		registrar(e, "%s (%s) foi recrutado." % [g["nome"], Model.classes()[g["classe"]]["nome"]])
	return ""

static func comprar_item(e: Dictionary, item_id: String) -> String:
	var err := _exigir_melhoria(e, "armaria")
	if err != "": return err
	var item := Model.item_por_id(item_id)
	if item.is_empty():
		return "Item inexistente."
	err = pagar(e, 0, preco_item(e, item))
	if err != "": return err
	e["inventario"].append(item_id)
	registrar(e, "Comprado: %s." % item["nome"])
	return ""

## Coloca um item no slot, ou tira o que estiver nele (item_id vazio).
static func equipar(e: Dictionary, glad_id: String, slot: String, item_id: String) -> String:
	var err := _exigir_melhoria(e, "armaria")
	if err != "": return err
	var g := achar(e, glad_id)
	if g.is_empty():
		return "Gladiador inexistente."
	err = _exigir_com_estilo(g)
	if err != "": return err
	var antigo = g["equipamento"][slot]
	if item_id == "":
		if antigo != null:
			e["inventario"].append(antigo)
		g["equipamento"][slot] = null
		return ""
	var item := Model.item_por_id(item_id)
	if item.is_empty():
		return "Item inexistente."
	if item["slot"] != slot:
		return "Este item não serve a este slot."
	if not (g["classe"] in item["classes"]):
		return "Este item não serve a esta classe."
	var idx: int = e["inventario"].find(item_id)
	if idx < 0:
		return "Item não está no armeiro."
	e["inventario"].remove_at(idx)
	if antigo != null:
		e["inventario"].append(antigo)
	g["equipamento"][slot] = item_id
	return ""

static func escolher_estilo(e: Dictionary, glad_id: String, classe: String) -> String:
	var g := achar(e, glad_id)
	if g.is_empty():
		return "Gladiador inexistente."
	var err := _exigir_vivo(g)
	if err != "": return err
	if not g.get("semEstilo", false):
		return "Este gladiador já tem um estilo. Para mudar, use \"Trocar estilo\"."
	g["classe"] = classe
	g["semEstilo"] = false
	g["equipamento"] = Model.sortear_equipamento(proximo_rng(e), classe)
	registrar(e, "%s vai lutar como %s, com o kit básico." % [g["nome"], Model.classes()[classe]["nome"]])
	return ""

static func trocar_classe(e: Dictionary, glad_id: String, classe: String) -> String:
	var g := achar(e, glad_id)
	if g.is_empty():
		return "Gladiador inexistente."
	var err := _exigir_vivo(g)
	if err != "": return err
	err = _exigir_com_estilo(g)
	if err != "": return err
	if g["campeao"]:
		return "O campeão do ludus não muda de estilo."
	if classe == g["classe"]:
		return "O gladiador já luta neste estilo."
	var energia := 2 if g["origem"] == "livre" else 1
	err = pagar(e, energia, preco_troca_estilo(e, g))
	if err != "": return err
	g["classe"] = classe
	for slot in Model.SLOTS:
		var id = g["equipamento"][slot]
		if id == null:
			continue
		var item := Model.item_por_id(id)
		if item.get("basico", false):
			g["equipamento"][slot] = Model.com_qualidade("basico_%s_%s" % [slot, classe], int(item["qualidade"]))
		elif not (classe in item["classes"]):
			e["inventario"].append(id)
			g["equipamento"][slot] = Model.com_qualidade("basico_%s_%s" % [slot, classe], 0)
	registrar(e, "%s passou a lutar como %s." % [g["nome"], Model.classes()[classe]["nome"]])
	return ""

static func treinar(e: Dictionary, glad_id: String, atributo: String) -> String:
	var err := _exigir_melhoria(e, "palus")
	if err != "": return err
	var g := achar(e, glad_id)
	if g.is_empty():
		return "Gladiador inexistente."
	err = _exigir_vivo(g)
	if err != "": return err
	if int(g["treino"][atributo]) >= TREINO_MAXIMO:
		return "Treino máximo atingido neste atributo."
	err = pagar(e, 1, PRECO_TREINO)
	if err != "": return err
	g["treino"][atributo] = int(g["treino"][atributo]) + 1
	g["xp"] = int(g["xp"]) + 10
	Model.atualizar_nivel(g)
	return ""

static func tratar(e: Dictionary, glad_id: String) -> String:
	var err := _exigir_melhoria(e, "enfermaria")
	if err != "": return err
	var g := achar(e, glad_id)
	if g.is_empty():
		return "Gladiador inexistente."
	err = _exigir_vivo(g)
	if err != "": return err
	if g["efeitos"].size() == 0:
		return "Este gladiador não tem efeitos a tratar."
	err = pagar(e, 1, Model.custo_tratamento(g))
	if err != "": return err
	g["efeitos"] = []
	registrar(e, "%s foi tratado na enfermaria." % g["nome"])
	return ""

# ---------- Combate ----------

static func _aplicar_efeitos(g: Dictionary, aplicados: Array) -> Array:
	var novos: Array = []
	for ap in aplicados:
		if ap["alvo"] != g["id"]:
			continue
		var existente: Dictionary = {}
		for x in g["efeitos"]:
			if x["tipo"] == ap["tipo"]:
				existente = x
				break
		if not existente.is_empty():
			existente["severidade"] = mini(3, int(existente["severidade"]) + 1)
			novos.append("%s (gravidade %d)" % [NOME_EFEITO[ap["tipo"]], int(existente["severidade"])])
		else:
			g["efeitos"].append({"tipo": ap["tipo"], "severidade": 1})
			novos.append("%s (gravidade 1)" % NOME_EFEITO[ap["tipo"]])
	return novos

static func _visual(g: Dictionary, f: Dictionary) -> Dictionary:
	return {"id": g["id"], "nome": g["nome"], "classe": g["classe"], "hpMax": f["hpMax"], "aparencia": Model.aparencia_de(g)}

static func _nomes(lista: Array) -> String:
	return " e ".join(lista.map(func(g): return g["nome"]))

## d: ladoA, ladoB, especialidadeB, bonusB, arena, titulo, trilha, poco, mortal, recompensa, rng
static func _disputar(e: Dictionary, d: Dictionary) -> Dictionary:
	var casa := lanista_da_casa(e)
	var forte: Dictionary = {}
	if _cheat(e, "vencer"):
		forte = {"forca": 80, "agilidade": 80, "vitalidade": 300, "sorte": 80}
	elif _cheat(e, "vida"):
		forte = {"vitalidade": 300}
	var extra_a: Dictionary = extra_da_casa(e).duplicate()
	for a in Model.ATRIBUTOS:
		if forte.get(a, 0) != 0:
			extra_a[a] = int(extra_a.get(a, 0)) + int(forte[a])
	var fa: Array = d["ladoA"].map(func(g): return Model.para_lutador(g, casa["especialidade"], extra_a))
	var fb: Array = d["ladoB"].map(func(g): return Model.para_lutador(g, d["especialidadeB"], d["bonusB"]))
	var opcoes := {"efeitosPoco": d["poco"]}
	if not d["mortal"]:
		opcoes["rendicao"] = Combat.RENDICAO_PADRAO
	var rng: Rng = d["rng"]
	var r := Combat.simular_equipes(fa, fb, rng.inteiro(1, 2147483646), opcoes)
	var vitoria: bool = true if _cheat(e, "vencer") else r["vencedorLado"] == "A"

	var efeitos_novos: Array = []
	if d["poco"] and not _cheat(e, "vida"):
		for g in d["ladoA"]:
			efeitos_novos.append_array(_aplicar_efeitos(g, r["efeitosAplicados"]))

	var caidos: Dictionary = {}
	if not (_cheat(e, "vida") or _cheat(e, "vencer")):
		for ev in r["eventos"]:
			if ev["tipo"] == "morte":
				caidos[ev["alvo"]] = true
	for g in d["ladoA"]:
		if caidos.has(g["id"]):
			g["vivo"] = false

	var detalhes: Array = []
	for g in d["ladoA"].duplicate():
		if not g["vivo"]:
			estatisticas(e)["mortes"] += 1
			_remover_gladiador(e, g)
			detalhes.append("%s, lenda, caiu e deixou o ludus." % g["nome"] if g["lenda"] else "%s morreu e foi enterrado." % g["nome"])
		if vitoria:
			g["vitorias"] = int(g["vitorias"]) + 1
		else:
			g["derrotas"] = int(g["derrotas"]) + 1
		if vitoria and d["poco"]:
			g["vitoriasPoco"] = int(g["vitoriasPoco"]) + 1
		if d["poco"]:
			g["pocoOnly"] = true
		if g["lenda"]:
			g["lutasComoLenda"] = int(g.get("lutasComoLenda", 0)) + 1
		g["xp"] = int(g["xp"]) + (20 if vitoria else 8)
		Model.atualizar_nivel(g)
	if efeitos_novos.size() > 0:
		detalhes.append("Efeitos: %s." % ", ".join(efeitos_novos))

	var marcos: Array = []
	var ouro := 0
	var bonus_pct := 0
	var moedas := 0
	var plateia: String = d["arena"]["plateia"]
	if d["poco"]:
		var lot: String = LOTACOES_ORDEM[rng.inteiro(0, 2)]
		plateia = lot
		bonus_pct = LOTACOES_POCO[lot]["bonus"]
		if vitoria:
			moedas = rng.inteiro(LOTACOES_POCO[lot]["moedas"][0], LOTACOES_POCO[lot]["moedas"][1])
	if vitoria:
		e["vitoriasTotais"] = int(e["vitoriasTotais"]) + 1
		var base := rng.inteiro(d["recompensa"][0], d["recompensa"][1])
		ouro = base + jsround(float(base * bonus_pct) / 100.0) if d["poco"] else base
		var mult: Dictionary = {}
		if d["poco"]:
			mult = bonus_da_casa(e, "ouroPoco")
		elif not d["mortal"]:
			mult = bonus_da_casa(e, "ouroArena")
		if not mult.is_empty():
			ouro = jsround(float(ouro) * float(mult["valor"]))
		e["ouro"] = int(e["ouro"]) + ouro
		estatisticas(e)["ouroGanho"] += ouro
		for g in d["ladoA"].duplicate():
			if g["vivo"]:
				marcos.append_array(aplicar_marcos(e, g))
	for g in d["ladoA"].duplicate():
		if g["vivo"]:
			marcos.append_array(aplicar_liberdade(e, g))

	var resumo := "%s de %s contra %s." % ["Vitória" if vitoria else "Derrota", _nomes(d["ladoA"]), _nomes(d["ladoB"])]
	var partes: Array = [resumo]
	partes.append_array(detalhes)
	partes.append_array(marcos)
	registrar(e, " ".join(partes))

	var va: Array = []
	for i in range(d["ladoA"].size()):
		va.append(_visual(d["ladoA"][i], fa[i]))
	var vb: Array = []
	for i in range(d["ladoB"].size()):
		vb.append(_visual(d["ladoB"][i], fb[i]))
	return {
		"titulo": d["titulo"], "arenaNome": d["arena"]["nome"], "arte": d["arena"]["arte"], "plateia": plateia,
		"lutadoresA": va, "lutadoresB": vb, "eventos": r["eventos"], "vitoriaA": vitoria, "efeitosNovos": efeitos_novos,
		"resumo": resumo, "trilha": d["trilha"], "marcos": marcos, "ouro": ouro,
		"bonusPct": bonus_pct if vitoria else 0, "moedas": moedas,
	}

static func qualidade_rival(nivel: int, arena: Dictionary = {}) -> int:
	var do_nivel: int = int(floor(float(nivel) / float(Model.AJUSTE_RIVAL["divisorQualidade"])))
	var da_arena := 0
	if not arena.is_empty():
		var honras: Array = arenas().filter(func(a): return a["honra"])
		var idx := -1
		for i in range(honras.size()):
			if honras[i]["id"] == arena["id"]:
				idx = i
				break
		da_arena = mini(Model.AJUSTE_RIVAL["qualidadeArena"].size() - 1, idx + (0 if arena["honra"] else 2))
	return mini(Model.QUALIDADE_MAX, do_nivel + int(Model.AJUSTE_RIVAL["qualidadeArena"][maxi(0, da_arena)]))

static func gerar_rival(e: Dictionary, rng: Rng, nivel: int, origem: String, arena: Dictionary = {}) -> Dictionary:
	var classe: String = Model.CLASSES_IDS[rng.inteiro(0, Model.CLASSES_IDS.size() - 1)]
	return Model.gerar_gladiador(rng, novo_id(e), classe, nivel, origem, false, qualidade_rival(nivel, arena))

static func lutar_arena(e: Dictionary, glad_ids: Array, arena_id: String) -> Dictionary:
	var arena := arena_por_id(arena_id)
	if arena.is_empty():
		return {"erro": "Arena inexistente."}
	if glad_ids.size() < 1 or glad_ids.size() > 2:
		return {"erro": "Escolha 1 ou 2 gladiadores."}
	var unicos: Dictionary = {}
	for id in glad_ids:
		unicos[id] = true
	if unicos.size() != glad_ids.size():
		return {"erro": "Escolha gladiadores diferentes."}
	var lado_a: Array = []
	for id in glad_ids:
		var g := achar(e, id)
		if g.is_empty():
			return {"erro": "Gladiador inexistente."}
		lado_a.append(g)
	var fama := arena_liberada(e, arena)
	if not fama["liberada"]:
		return {"erro": "%s só abre depois de %d batalhas (faltam %d)." % [arena["nome"], int(arena["batalhasMin"]), int(fama["faltam"])]}
	for g in lado_a:
		var err := _exigir_vivo(g)
		if err == "": err = _exigir_com_estilo(g)
		if err != "": return {"erro": err}
		if not arena["honra"] and g["campeao"]:
			return {"erro": "O campeão do ludus não entra no Poço."}
		if arena["honra"] and g["pocoOnly"]:
			return {"erro": "%s já lutou no Poço e não pode lutar nas arenas de honra." % g["nome"]}
	var err2 := pagar(e, glad_ids.size(), 0)
	if err2 != "": return {"erro": err2}
	e["batalhasTotais"] = batalhas_do_ludus(e) + 1

	var rng := proximo_rng(e)
	var origem: String = "livre" if arena["honra"] else "escravo"
	var nivel_rival: int = mini(int(arena["nivelRival"][1]), maxi(int(arena["nivelRival"][0]), int(lado_a[0]["nivel"])))
	var lado_b: Array = []
	for i in range(lado_a.size()):
		lado_b.append(gerar_rival(e, rng, nivel_rival, origem, arena))
	if e["libertados"].size() > 0 and rng.proximo() < CHANCE_LIBERTO:
		var base: Dictionary = e["libertados"][rng.inteiro(0, e["libertados"].size() - 1)]
		var copia: Dictionary = base.duplicate(true)
		copia["id"] = novo_id(e)
		copia["vivo"] = true
		copia["efeitos"] = []
		copia["campeao"] = false
		copia["lenda"] = false
		lado_b[0] = copia
		registrar(e, "%s retorna à arena numa recriação de luta." % base["nome"])

	var mult := multiplicador_arena(arena, str(e.get("config", {}).get("dificuldade", "medio")))
	var bonus_b: Dictionary = {}
	var media := Model.stats_do_gladiador(lado_b[0])
	for a in Model.ATRIBUTOS:
		bonus_b[a] = jsround(float(media[a]) * (mult - 1.0))
	return _disputar(e, {
		"ladoA": lado_a, "ladoB": lado_b, "especialidadeB": "", "bonusB": bonus_b, "arena": arena, "titulo": arena["nome"],
		"trilha": arena["id"], "poco": not arena["honra"], "mortal": false,
		"recompensa": [int(arena["recompensaOuro"][0]) * glad_ids.size(), int(arena["recompensaOuro"][1]) * glad_ids.size()], "rng": rng,
	})

static func pular_luta(e: Dictionary, payload: Dictionary) -> int:
	var perda := 0
	if payload["vitoriaA"] and not _cheat(e, "pular"):
		perda = jsround(float(payload["ouro"]) * PENALIDADE_PULO)
	e["ouro"] = maxi(0, int(e["ouro"]) - perda)
	registrar(e, "Luta pulada: −%d de ouro na recompensa (10%%)." % perda if perda > 0 else "Luta pulada.")
	return perda

static func desistir_da_luta(antes: Dictionary, depois: Dictionary, glad_ids: Array) -> Dictionary:
	var novo: Dictionary = antes.duplicate(true)
	novo["energia"] = mini(int(antes["energia"]), int(depois["energia"]))
	novo["semente"] = depois["semente"]
	var nomes_d: Array = []
	for id in glad_ids:
		var g := achar(novo, id)
		if g.is_empty():
			continue
		g["derrotas"] = int(g["derrotas"]) + 1
		g["xp"] = int(g["xp"]) + 8
		Model.atualizar_nivel(g)
		nomes_d.append(g["nome"])
	registrar(novo, "%s desistiu da luta e não ganhou nada." % " e ".join(nomes_d))
	return novo

static func texto_requisito(r: Dictionary) -> String:
	match r["tipo"]:
		"vitoriasTotais":
			return "%d vitórias na arena" % int(r["valor"])
		"gladiadorVitorias":
			var cl: String = " " + Model.classes()[r["classe"]]["nome"] if r.has("classe") else ""
			return "Um gladiador%s com %d vitórias" % [cl, int(r["valor"])]
		"gladiadorPoco":
			return "Um gladiador com %d vitórias no Poço" % int(r["valor"])
		"gladiadorEquipado":
			return "Um gladiador equipado com %s" % Model.item_por_id(str(r.get("item", "")))["nome"]
	return ""

static func valor_requisito(e: Dictionary, r: Dictionary) -> int:
	return maxi(1, int(ceil(float(r.get("valor", 0)) * float(regras_de(e)["campReq"]))))

static func _cumpre(e: Dictionary, r: Dictionary) -> bool:
	var vivos: Array = e["gladiadores"].filter(func(g): return g["vivo"])
	var v := valor_requisito(e, r)
	match r["tipo"]:
		"vitoriasTotais":
			return int(e["vitoriasTotais"]) >= v
		"gladiadorVitorias":
			return vivos.any(func(g): return int(g["vitorias"]) >= v and (not r.has("classe") or g["classe"] == r["classe"]))
		"gladiadorPoco":
			return vivos.any(func(g): return int(g["vitoriasPoco"]) >= v)
		"gladiadorEquipado":
			return vivos.any(func(g): return g["equipamento"].values().has(r.get("item", "")))
	return false

## Próximo desafio da campanha; {} se a campanha acabou.
static func proximo_desafio(e: Dictionary) -> Dictionary:
	if int(e["campanha"]) >= passos().size():
		return {}
	var passo: Dictionary = passos()[int(e["campanha"])]
	var sequencia := sequencia_campanha(str(e["casaId"]))
	var lanista: Dictionary = sequencia[int(e["campanha"])]
	if not e["campeoesRivais"].has(lanista["id"]):
		e["campeoesRivais"][lanista["id"]] = criar_campeao_rival(proximo_rng(e), lanista, int(e["campanha"]))
	var ignora := _cheat(e, "campanha")
	var requisitos: Array = []
	var pronto := true
	for r in passo["requisitos"]:
		var r2: Dictionary = r.duplicate()
		r2["valor"] = valor_requisito(e, r)
		var ok: bool = ignora or _cumpre(e, r)
		requisitos.append({"texto": texto_requisito(r2), "ok": ok})
		if not ok:
			pronto = false
	return {"lanista": lanista, "sequencia": sequencia, "passo": passo, "indice": int(e["campanha"]), "requisitos": requisitos, "pronto": pronto}

static func _bonus_campanha(e: Dictionary, rival: Dictionary, indice: int, regra: Dictionary) -> Dictionary:
	var r := regras_de(e)
	var mult: float = float(r["campMult"][mini(indice, r["campMult"].size() - 1)])
	var base := Model.stats_do_gladiador(rival)
	var out: Dictionary = {}
	for a in Model.ATRIBUTOS:
		out[a] = jsround(float(base[a]) * (mult - 1.0)) + int(regra.get(a, 0))
	return out

static func lutar_campanha(e: Dictionary, glad_ids: Array) -> Dictionary:
	var desafio := proximo_desafio(e)
	if desafio.is_empty():
		return {"erro": "A campanha já foi concluída."}
	var lanista: Dictionary = desafio["lanista"]
	if not desafio["pronto"]:
		return {"erro": "Os requisitos deste passo ainda não foram cumpridos."}
	var formato: int = int(desafio["passo"].get("formato", 1))
	if glad_ids.size() != formato:
		return {"erro": "Este passo é %d contra %d: escolha %d gladiador%s." % [formato, formato, formato, "es" if formato > 1 else ""]}
	var unicos: Dictionary = {}
	for id in glad_ids:
		unicos[id] = true
	if unicos.size() != glad_ids.size():
		return {"erro": "Escolha gladiadores diferentes."}
	var lado_a: Array = []
	for id in glad_ids:
		var g := achar(e, id)
		if g.is_empty():
			return {"erro": "Gladiador inexistente."}
		lado_a.append(g)
	for g in lado_a:
		var err := _exigir_vivo(g)
		if err == "": err = _exigir_com_estilo(g)
		if err != "": return {"erro": err}
	var err2 := pagar(e, formato, 0)
	if err2 != "": return {"erro": err2}

	var rng := proximo_rng(e)
	var regra: Dictionary = desafio["passo"]["regra"]
	var lado_b: Array = [e["campeoesRivais"][lanista["id"]]]
	for i in range(1, formato):
		lado_b.append(Model.gerar_gladiador(rng, novo_id(e), lanista["especialidade"], 3, "livre"))
	var payload := _disputar(e, {
		"ladoA": lado_a, "ladoB": lado_b, "especialidadeB": lanista["especialidade"],
		"bonusB": _bonus_campanha(e, lado_b[0], int(desafio["indice"]), regra["bonus"]),
		"arena": arena_por_id("poco" if regra["efeitosPoco"] else "coliseu"),
		"titulo": "%s: %s" % [desafio["passo"]["titulo"], regra["nome"]],
		"trilha": "poco" if regra["efeitosPoco"] else "campanha:%s" % lanista["id"],
		"poco": regra["efeitosPoco"], "mortal": true, "recompensa": [100 * formato, 140 * formato], "rng": rng,
	})
	if payload["vitoriaA"]:
		e["campanha"] = int(e["campanha"]) + 1
		var der: Array = e.get("derrotados", [])
		der.append(lanista["id"])
		e["derrotados"] = der
	return payload

# ---------- Lenda, liberdade, venda e dispensa ----------

static func aplicar_marcos(e: Dictionary, g: Dictionary) -> Array:
	var marcos: Array = []
	var r := regras_de(e)
	var ja_ha_campeao: bool = e["gladiadores"].any(func(x): return x["campeao"] and x["vivo"])
	if not g["campeao"] and not ja_ha_campeao and not g["pocoOnly"] and int(g["vitorias"]) >= int(r["campeao"]):
		g["campeao"] = true
		var msg: String = "%s tornou-se o campeão do ludus após %d vitórias." % [g["nome"], int(g["vitorias"])]
		registrar(e, msg)
		marcos.append(msg)
	var ja_ha_lenda: bool = e["gladiadores"].any(func(x): return x["lenda"] and x["vivo"] and x["id"] != g["id"])
	if not g["lenda"] and not ja_ha_lenda and int(g["vitorias"]) >= int(r["lenda"]):
		g["lenda"] = true
		var msg2: String = "%s tornou-se lenda após %d vitórias." % [g["nome"], int(g["vitorias"])]
		registrar(e, msg2)
		marcos.append(msg2)
	return marcos

static func aplicar_liberdade(e: Dictionary, g: Dictionary) -> Array:
	var lim = regras_de(e)["liberdade"]
	if lim == null or not g["lenda"] or not g["vivo"] or int(g.get("lutasComoLenda", 0)) < int(lim):
		return []
	var copia: Dictionary = g.duplicate(true)
	copia["efeitos"] = []
	copia["lenda"] = false
	copia["campeao"] = false
	copia["vivo"] = true
	_remover_gladiador(e, g)
	e["libertados"].append(copia)
	var msg: String = "%s ganhou a liberdade após %d lutas como lenda." % [g["nome"], int(g.get("lutasComoLenda", 0))]
	registrar(e, msg)
	return [msg]

static func _remover_gladiador(e: Dictionary, g: Dictionary) -> void:
	e["gladiadores"] = e["gladiadores"].filter(func(x): return x["id"] != g["id"])
	for slot in Model.SLOTS:
		var id = g["equipamento"][slot]
		if id != null:
			var item := Model.item_por_id(id)
			if not (item.get("basico", false) and int(Model.separar_id(id)["qualidade"]) == 0):
				e["inventario"].append(id)
		g["equipamento"][slot] = null

static func vender_gladiador(e: Dictionary, id: String) -> String:
	var g := achar(e, id)
	if g.is_empty():
		return "Gladiador inexistente."
	if g["campeao"]:
		return "O campeão do ludus não pode ser vendido."
	if g["lenda"]:
		return "A lenda não é vendida: só deixa o ludus pela liberdade."
	if g["origem"] != "escravo":
		return "Só escravos são vendidos."
	if not g["vivo"]:
		return "Gladiador morto não pode ser vendido."
	var valor := maxi(20, jsround(float(Model.preco_gladiador(g)) * float(regras_de(e)["precos"]) / 2.0))
	_remover_gladiador(e, g)
	e["ouro"] = int(e["ouro"]) + valor
	estatisticas(e)["ouroGanho"] += valor
	registrar(e, "%s foi vendido por %d de ouro." % [g["nome"], valor])
	return ""

static func dispensar_gladiador(e: Dictionary, id: String) -> String:
	var g := achar(e, id)
	if g.is_empty():
		return "Gladiador inexistente."
	if g["campeao"]:
		return "O campeão do ludus não pode ser dispensado."
	if g["lenda"]:
		return "A lenda não é dispensada: só deixa o ludus pela liberdade."
	_remover_gladiador(e, g)
	registrar(e, "%s foi dispensado." % g["nome"])
	return ""
