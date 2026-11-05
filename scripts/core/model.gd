class_name Model
extends RefCounted
## Modelo de dados: classes, itens, origens e gladiadores (porte fiel de model.ts).

const ATRIBUTOS: Array = ["forca", "destreza", "vitalidade", "resistencia", "inteligencia", "aura"]
const SLOTS: Array = ["arma", "acessorio", "elmo", "peito", "pe", "calca", "amuleto"]
const CLASSES_IDS: Array = ["murmilo", "retiario", "tracio", "samnita"]
const QUALIDADES: Array = ["Normal", "Superior", "Rara", "Épica", "Lendária"]
const COR_QUALIDADE: Array = ["#9aa0a6", "#4caf50", "#3d8bfd", "#a855f7", "#ff9f1a"]
const QUALIDADE_MAX := 4
const BONUS_QUALIDADE: Array = [0, 1, 2, 3, 4]
const PRECO_QUALIDADE: Array = [1.0, 1.5, 2.5, 4.0, 7.0]
const FOCO_SLOT := {"arma": "forca", "acessorio": "inteligencia", "elmo": "aura", "peito": "vitalidade", "pe": "destreza", "calca": "resistencia", "amuleto": "aura"}
const NOME_SLOT := {"arma": "Arma", "acessorio": "Escudo / acessório", "elmo": "Elmo", "peito": "Peitoral", "pe": "Calçado", "calca": "Calça", "amuleto": "Amuleto"}
const NOME_ATRIBUTO := {"forca": "Força", "destreza": "Destreza", "vitalidade": "Vitalidade", "resistencia": "Resistência", "inteligencia": "Inteligência", "aura": "Aura"}
const SIGLA_ATRIBUTO := {"forca": "FOR", "destreza": "DES", "vitalidade": "VIT", "resistencia": "RES", "inteligencia": "INT", "aura": "AUR"}
## Qualidade: peso extra por nível e Fama mínima para comprar.
const PESO_QUALIDADE: Array = [1.0, 1.12, 1.24, 1.36, 1.5]
const FAMA_QUALIDADE: Array = [0, 6, 14, 28, 48]
const FORCA_QUALIDADE: Array = [0, 1, 2, 3, 4]
## Peso do equipamento: carga máxima = 20 + 2 × Força (sem itens); faixas pela fração da carga.
const CARGA_BASE := 20
const CARGA_POR_FORCA := 2
## Glória: títulos por pontuação mínima.
const TITULOS_GLORIA: Array = [[0, "Novato"], [100, "Conhecido"], [400, "Temido"], [1000, "Campeão"], [2500, "Lenda"]]
## Amuletos: cada região (terra) tem um tipo por atributo; só gladiadores daquela região podem usar. Bônus = +1 + qualidade no atributo.
const AMULETO_OBJETO := {"galia": "Torque", "germania": "Runa", "tracia": "Talismã", "dacia": "Dracônio", "numidia": "Colar", "hispania": "Medalhão", "siria": "Selo", "britania": "Pingente"}
const AMULETO_EPITETO := {"forca": "do Urso", "destreza": "do Falcão", "vitalidade": "do Carvalho", "resistencia": "da Rocha", "inteligencia": "da Coruja", "aura": "da Lua"}
const AMULETO_PRECO := 90
const NIVEL_MAXIMO := 15
const TENDENCIA_PONTOS := 2
const PRECO_CONDICAO := {"jovem": 20, "maduro": 0, "cicatrizado": -20}
const AJUSTE_RIVAL := {"treinoPorNivel": 1, "divisorQualidade": 4, "qualidadeArena": [0, 1, 2]}
const PENALIDADE_EFEITO := {"sangramento": "vitalidade", "envenenamento": "resistencia", "contusao": "forca", "queimadura": "destreza"}

const NOME_BASICO := {
	"arma": {"murmilo": "Gládio simples", "retiario": "Tridente simples", "tracio": "Sica simples", "samnita": "Gládio simples", "dimachaerus": "Gládios simples"},
	"acessorio": {"murmilo": "Escudo simples", "retiario": "Rede simples", "tracio": "Escudo pequeno simples", "samnita": "Escudo simples", "dimachaerus": "Manica simples"},
	"elmo": {"murmilo": "Elmo simples", "retiario": "Galero simples", "tracio": "Capacete simples", "samnita": "Elmo simples", "dimachaerus": "Faixa de cabelo simples"},
	"peito": {"murmilo": "Peitoral simples", "retiario": "Peitoral de couro simples", "tracio": "Peitoral de couro simples", "samnita": "Peitoral simples", "dimachaerus": "Correias simples"},
	"pe": {"murmilo": "Botas simples", "retiario": "Sandálias simples", "tracio": "Sandálias simples", "samnita": "Botas simples", "dimachaerus": "Sandálias simples"},
	"calca": {"murmilo": "Perneira simples", "retiario": "Faixa simples", "tracio": "Faixa simples", "samnita": "Perneira simples", "dimachaerus": "Faixa simples"},
}

const NOMES: Array = [
	"Ático", "Brenno", "Cássio", "Dárdano", "Espúrio", "Flávio", "Gracco", "Hélvio", "Ícaro", "Juba",
	"Lúcio", "Márcio", "Nério", "Otávio", "Pacato", "Rúfio", "Sabino", "Túlio", "Vário", "Xantipo",
	"Aulo", "Balbo", "Cneu", "Décimo", "Eumeno", "Fábio", "Galba", "Hirto", "Ibero", "Jano",
	"Lêntulo", "Mânio", "Numério", "Ósio", "Pláucio", "Quinto", "Rômulo", "Sérvio", "Tibério", "Úlpio",
	"Valente", "Zenão", "Amílcar", "Bóio", "Crixo", "Doro", "Enômao", "Fúrio", "Górgias", "Heitor",
	"Ixíon", "Jugurta", "Lisandro", "Mário", "Nicandro", "Orgétorix", "Perseu", "Rufo", "Sertório", "Tárcio",
]

## Nomes únicos: tabela grande (assets/dados/nomes.txt) sem repetição por partida. `nomes_legado` mantém a lista curta (testes de paridade).
static var nomes_legado := false
static var nomes_usados := {}
static var _tabela_nomes: PackedStringArray = PackedStringArray()
static var _rng_nomes := RandomNumberGenerator.new()

static func sortear_nome(base: String) -> String:
	if nomes_legado:
		return base
	if _tabela_nomes.is_empty():
		var f := FileAccess.open("res://assets/dados/nomes.txt", FileAccess.READ)
		if f:
			_tabela_nomes = f.get_as_text().split("\n", false)
		_rng_nomes.randomize()
	if _tabela_nomes.is_empty():
		return base
	if nomes_usados.size() >= _tabela_nomes.size() - 50:
		nomes_usados.clear()
	var n: String = _tabela_nomes[_rng_nomes.randi() % _tabela_nomes.size()]
	while nomes_usados.has(n):
		n = _tabela_nomes[_rng_nomes.randi() % _tabela_nomes.size()]
	nomes_usados[n] = true
	return n

static func registrar_nomes(v) -> void:
	if v is Dictionary:
		if v.has("nome") and v.has("classe"):
			nomes_usados[str(v["nome"])] = true
		for k in v:
			registrar_nomes(v[k])
	elif v is Array:
		for x in v:
			registrar_nomes(x)

static var _classes: Dictionary = {}
static var _itens: Array = []
static var _terras: Array = []

static func classes() -> Dictionary:
	if _classes.is_empty():
		_classes = Util.ler_json("res://data/classes.json")
	return _classes

static func itens() -> Array:
	if _itens.is_empty():
		_itens = Util.ler_json("res://data/itens.json")
	return _itens

static func terras() -> Array:
	if _terras.is_empty():
		_terras = Util.ler_json("res://data/origens.json")
	return _terras

## Arredondamento do JavaScript (meio vai para cima), diferente do roundf do Godot em negativos.
static func jsround(x: float) -> int:
	return int(floor(x + 0.5))

static func separar_id(id: String) -> Dictionary:
	var i := id.find("@")
	if i < 0:
		return {"base": id, "qualidade": 0}
	var n := id.substr(i + 1)
	var q: int = int(n) if n.is_valid_int() else 0
	return {"base": id.substr(0, i), "qualidade": mini(QUALIDADE_MAX, maxi(0, q))}

static func com_qualidade(base: String, q: int) -> String:
	return "%s@%d" % [base, q] if q > 0 else base

static func qualidade_de(id) -> int:
	return int(separar_id(id)["qualidade"]) if id != null else 0

static func id_amuleto(terra: String, atributo: String, qualidade: int = 0) -> String:
	return com_qualidade("amu_%s_%s" % [terra, atributo], qualidade)

static func _item_amuleto(base: String) -> Dictionary:
	var partes := base.split("_")
	if partes.size() != 3 or not AMULETO_OBJETO.has(partes[1]) or not (partes[2] in ATRIBUTOS):
		return {}
	var terra: String = partes[1]
	var atributo: String = partes[2]
	return {"id": base, "nome": "%s %s" % [AMULETO_OBJETO[terra], AMULETO_EPITETO[atributo]], "slot": "amuleto", "bonus": {atributo: 1},
		"classes": CLASSES_IDS + ["dimachaerus"], "preco": AMULETO_PRECO, "peso": 0, "forcaMin": 0, "famaMin": 0, "terra": terra, "foco": atributo, "amuleto": true}

static func _item_basico(slot: String, classe: String) -> Dictionary:
	var pesos := {"arma": 2, "acessorio": 3, "elmo": 2, "peito": 3, "pe": 1, "calca": 1}
	return {"id": "basico_%s_%s" % [slot, classe], "nome": NOME_BASICO[slot][classe], "slot": slot, "bonus": {}, "classes": [classe], "preco": 25, "basico": true, "peso": pesos[slot], "forcaMin": 0, "famaMin": 0}

## Item completo (com qualidade aplicada). Devolve {} se não existir.
static func item_por_id(id: String) -> Dictionary:
	var s := separar_id(id)
	var base: String = s["base"]
	var qualidade: int = s["qualidade"]
	var item: Dictionary = {}
	for i in itens():
		if i["id"] == base:
			item = i
			break
	if item.is_empty() and base.begins_with("amu_"):
		item = _item_amuleto(base)
	if item.is_empty() and base.begins_with("basico_"):
		var resto := base.substr(7)
		for slot in SLOTS:
			if resto.begins_with(slot + "_"):
				var classe := resto.substr(slot.length() + 1)
				if classe in ["murmilo", "retiario", "tracio", "samnita", "dimachaerus"]:
					item = _item_basico(slot, classe)
				break
	if item.is_empty():
		return {}
	var r: Dictionary = item.duplicate(true)
	var foco: String = str(r.get("foco", FOCO_SLOT[r["slot"]]))
	var bonus: Dictionary = r["bonus"]
	bonus[foco] = int(bonus.get(foco, 0)) + int(BONUS_QUALIDADE[qualidade])
	if bonus[foco] == 0:
		bonus.erase(foco)
	r["id"] = id
	r["qualidade"] = qualidade
	r["peso"] = 0 if int(item["peso"]) == 0 else maxi(1, jsround(float(item["peso"]) * float(PESO_QUALIDADE[qualidade])))
	r["forcaMin"] = (int(item["forcaMin"]) + int(FORCA_QUALIDADE[qualidade])) if int(item["forcaMin"]) > 0 else 0
	r["famaMin"] = int(item.get("famaMin", 0)) + int(FAMA_QUALIDADE[qualidade])
	r["preco"] = jsround(float(item["preco"]) * float(PRECO_QUALIDADE[qualidade]))
	return r

static func terra_por_id(id: String) -> Dictionary:
	for t in terras():
		if t["id"] == id:
			return t
	return {}

static func equipamento_vazio() -> Dictionary:
	return {"arma": null, "acessorio": null, "elmo": null, "peito": null, "pe": null, "calca": null, "amuleto": null}

static func sortear_equipamento(rng: Rng, classe: String, qual_max: int = 0) -> Dictionary:
	var eq := equipamento_vazio()
	for slot in SLOTS:
		if slot == "amuleto":
			continue
		var q: int = rng.inteiro(0, qual_max) if qual_max > 0 else 0
		eq[slot] = com_qualidade("basico_%s_%s" % [slot, classe], q)
	return eq

static func gerar_gladiador(rng: Rng, id: String, classe: String, nivel: int, origem: String, campeao: bool = false, qual_max: int = 0) -> Dictionary:
	var treino := {"forca": 0, "destreza": 0, "vitalidade": 0, "resistencia": 0, "inteligencia": 0, "aura": 0}
	var pontos: int
	if origem == "livre":
		pontos = jsround(float((nivel - 1) * int(AJUSTE_RIVAL["treinoPorNivel"]))) + rng.inteiro(0, 2)
	else:
		pontos = rng.inteiro(0, 2)
	for i in range(pontos):
		treino[ATRIBUTOS[rng.inteiro(0, ATRIBUTOS.size() - 1)]] += 1
	var terra: Dictionary = terras()[rng.inteiro(0, terras().size() - 1)]
	var nome: String = sortear_nome(NOMES[rng.inteiro(0, NOMES.size() - 1)])
	var look: int = rng.inteiro(0, 3)
	var equipamento := sortear_equipamento(rng, classe, qual_max)
	return {
		"id": id, "nome": nome, "classe": classe, "origem": origem, "terra": terra["id"], "look": look,
		"campeao": campeao, "lenda": false, "nivel": nivel, "xp": 0, "treino": treino, "equipamento": equipamento,
		"vivo": true, "gloria": 0, "pocoOnly": false, "vitorias": 0, "vitoriasPoco": 0, "derrotas": 0, "efeitos": [],
	}

static func gerar_escravo(rng: Rng, id: String) -> Dictionary:
	var g := gerar_gladiador(rng, id, "murmilo", 1, "escravo")
	g["semEstilo"] = true
	g["equipamento"] = equipamento_vazio()
	var tendencia: String = ATRIBUTOS[rng.inteiro(0, ATRIBUTOS.size() - 1)]
	g["tendencia"] = tendencia
	g["treino"][tendencia] += TENDENCIA_PONTOS
	var condicoes := ["jovem", "maduro", "cicatrizado"]
	var condicao: String = condicoes[rng.inteiro(0, condicoes.size() - 1)]
	g["condicao"] = condicao
	if condicao == "jovem":
		g["treino"][ATRIBUTOS[rng.inteiro(0, ATRIBUTOS.size() - 1)]] += 1
	if condicao == "cicatrizado":
		g["treino"]["vitalidade"] += 1
	return g

static func atualizar_nivel(g: Dictionary) -> void:
	g["nivel"] = mini(NIVEL_MAXIMO, maxi(int(g["nivel"]), 1 + int(floor(float(g["xp"]) / 50.0))))

static func soma_treino(g: Dictionary) -> int:
	var t := 0
	for a in ATRIBUTOS:
		t += int(g["treino"][a])
	return t

static func aparencia_de(g: Dictionary) -> Dictionary:
	return {"terra": g["terra"], "look": g["look"], "classe": g["classe"], "campeao": g["campeao"], "equipamento": g["equipamento"]}

## Atributos sem itens: classe + nível + treino + especialidade/campeão/lenda + extra (usado nos requisitos de Força).
static func stats_sem_itens(g: Dictionary, especialidade: String = "", extra: Dictionary = {}) -> Dictionary:
	var base: Dictionary = classes()[g["classe"]]["stats"]
	var s := {}
	for a in ATRIBUTOS:
		s[a] = int(base[a])
	s["forca"] += int(g["nivel"]) - 1
	s["vitalidade"] += int(g["nivel"]) - 1
	for a in ATRIBUTOS:
		s[a] += int(g["treino"].get(a, 0)) + (2 if especialidade == g["classe"] else 0) + (2 if g["campeao"] else 0) + (1 if g["lenda"] else 0) + int(extra.get(a, 0))
	return s

## Atributos finais: sem itens + itens − efeitos.
static func stats_do_gladiador(g: Dictionary, especialidade: String = "", extra: Dictionary = {}) -> Dictionary:
	var s := stats_sem_itens(g, especialidade, extra)
	for slot in SLOTS:
		var id = g["equipamento"][slot]
		if id == null:
			continue
		var item := item_por_id(id)
		for a in ATRIBUTOS:
			s[a] += int(item["bonus"].get(a, 0))
	for ef in g["efeitos"]:
		s[PENALIDADE_EFEITO[ef["tipo"]]] -= int(ef["severidade"])
	for a in ATRIBUTOS:
		s[a] = maxi(1, s[a])
	return s

## Peso total do equipamento vestido.
static func carga_atual(g: Dictionary) -> int:
	var t := 0
	for slot in SLOTS:
		var id = g["equipamento"][slot]
		if id != null:
			t += int(item_por_id(id).get("peso", 0))
	return t

static func carga_maxima(g: Dictionary, especialidade: String = "", extra: Dictionary = {}) -> int:
	return CARGA_BASE + CARGA_POR_FORCA * int(stats_sem_itens(g, especialidade, extra)["forca"])

## "leve" (até 30%), "normal" (até 70%), "pesado" (até 100%), "sobrecarga" (acima).
static func faixa_carga(atual: int, maxima: int) -> String:
	var f: float = float(atual) / float(maxi(1, maxima))
	if f <= 0.3:
		return "leve"
	if f <= 0.7:
		return "normal"
	if f <= 1.0:
		return "pesado"
	return "sobrecarga"

static func titulo_gloria(gloria: int) -> String:
	var t: String = TITULOS_GLORIA[0][1]
	for x in TITULOS_GLORIA:
		if gloria >= int(x[0]):
			t = x[1]
	return t

## {"atual", "minimo", "proximo"} do título de Glória.
static func progresso_gloria(gloria: int) -> Dictionary:
	var minimo := 0
	var prox := -1
	for x in TITULOS_GLORIA:
		if gloria >= int(x[0]):
			minimo = int(x[0])
		elif prox < 0:
			prox = int(x[0])
	return {"titulo": titulo_gloria(gloria), "minimo": minimo, "proximo": prox}

static func para_lutador(g: Dictionary, especialidade: String = "", extra: Dictionary = {}) -> Dictionary:
	var f := Combat.criar_lutador(g["id"], g["nome"], stats_do_gladiador(g, especialidade, extra), classes()[g["classe"]]["passiva"])
	var atual := carga_atual(g)
	var maxima := carga_maxima(g, especialidade, extra)
	f["faixa"] = faixa_carga(atual, maxima)
	f["cargaPct"] = float(atual) / float(maxi(1, maxima))
	return f

static func preco_gladiador(g: Dictionary) -> int:
	if g["origem"] == "livre":
		return 220 + int(g["nivel"]) * 40 + soma_treino(g) * 15
	return maxi(30, 60 + soma_treino(g) * 15 + (int(PRECO_CONDICAO[g["condicao"]]) if g.has("condicao") else 0))

static func preco_troca(g: Dictionary) -> int:
	return (300 if g["origem"] == "livre" else 100) + int(g["nivel"]) * 20

static func custo_tratamento(g: Dictionary) -> int:
	var t := 0
	for ef in g["efeitos"]:
		t += int(ef["severidade"]) * 30
	return t
