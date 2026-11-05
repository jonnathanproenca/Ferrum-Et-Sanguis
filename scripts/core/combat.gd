class_name Combat
extends RefCounted
## Combate automático (porte fiel de combat.ts). Lutadores e eventos são Dictionaries.

const TIPOS_EFEITO: Array = ["sangramento", "envenenamento", "contusao", "queimadura"]
const MAX_RODADAS := 50
const CARGA_PESADO := 4
const BONUS_PESADO := 1.1
const CHANCE_SEQUENCIA := 0.15
const CHANCE_EFEITO_PADRAO := 0.5
const RENDICAO_PADRAO := 0.25

## Constantes de balanceamento (todas as fórmulas de atributos ficam aqui).
const HP_BASE := 50
const HP_POR_VIT := 6
const EST_BASE := 30
const EST_POR_RES := 3
const EST_REGEN := 4
const EST_GOLPE := 8
const EST_PESADO := 16
const ACERTO_BASE := 55.0
const ACERTO_POR_DES := 1.5
const ACERTO_MIN := 20.0
const ACERTO_MAX := 95.0
const DEFESA_POR_INT := 1.5
const DEFESA_MAX := 60.0
const DANO_BASE := 6.0
const DANO_POR_FOR := 0.7
const CHANCE_CRITICO := 0.05
const EXAUSTO_ACERTO := 20.0
const EXAUSTO_DANO := 0.6
const FAIXA_DEFESA := {"leve": 8.0, "normal": 0.0, "pesado": -8.0, "sobrecarga": -8.0}
const FAIXA_REGEN := {"leve": 2, "normal": 0, "pesado": -2, "sobrecarga": -2}
const RESISTENCIA_EFEITO := 0.02

static func criar_lutador(id: String, nome: String, stats: Dictionary, passiva: String = "") -> Dictionary:
	var hp_max: int = HP_BASE + int(stats["vitalidade"]) * HP_POR_VIT
	var est_max: int = EST_BASE + int(stats["resistencia"]) * EST_POR_RES
	return {"id": id, "nome": nome, "stats": stats.duplicate(), "hpMax": hp_max, "hp": hp_max, "passiva": passiva,
		"estMax": est_max, "est": est_max, "faixa": "normal", "cargaPct": 0.5}

static func chance_acerto(atq: Dictionary, exausto: bool = false) -> float:
	var c: float = ACERTO_BASE + ACERTO_POR_DES * float(atq["stats"]["destreza"]) - (EXAUSTO_ACERTO if exausto else 0.0)
	return clampf(c, ACERTO_MIN, ACERTO_MAX)

## Multiplicador da esquiva/defesa pelo peso: leve ajuda; passando de 70% da carga cai forte (até ×0.4 com a carga cheia),
## mesmo com Inteligência alta (com peso demais não dá para rolar direito).
static func fator_peso(pct: float) -> float:
	if pct <= 0.3:
		return 1.1
	if pct <= 0.7:
		return 1.0
	return lerpf(1.0, 0.4, clampf((pct - 0.7) / 0.3, 0.0, 1.0))

static func chance_defesa(def: Dictionary, preso: bool = false) -> float:
	var c: float = DEFESA_POR_INT * float(def["stats"]["inteligencia"])
	if def["passiva"] == "guarda":
		c += 8.0
	c *= fator_peso(float(def.get("cargaPct", 0.5)))
	if preso:
		c -= 10.0
	return clampf(c, 0.0, DEFESA_MAX)

static func dano_base(atq: Dictionary) -> float:
	return DANO_BASE + DANO_POR_FOR * float(atq["stats"]["forca"])

## Um golpe. `presos` e `cargas` são Dictionaries mutáveis (conjunto e mapa).
static func resolver_ataque(atq: Dictionary, def: Dictionary, rng: Rng, rodada: int, presos: Dictionary, cargas: Dictionary) -> Dictionary:
	var pesado: bool = int(cargas.get(atq["id"], 0)) >= CARGA_PESADO
	if pesado:
		cargas[atq["id"]] = 0
	var custo: int = EST_PESADO if pesado else EST_GOLPE
	var exausto: bool = int(atq["est"]) < custo
	atq["est"] = maxi(0, int(atq["est"]) - custo)
	var preso: bool = presos.has(def["id"])
	if preso:
		presos.erase(def["id"])
	var p_acerto := chance_acerto(atq, exausto)
	var p_defesa := chance_defesa(def, preso)
	var r1: float = rng.proximo()
	var r2: float = rng.proximo()
	var critico: bool = r1 < CHANCE_CRITICO
	var base := {
		"rodada": rodada, "atacante": atq["id"], "defensor": def["id"],
		"chanceAcerto": p_acerto, "chanceDefesa": p_defesa, "exausto": exausto,
		"rolagemAtaque": int(r1 * 100.0), "rolagemDefesa": int(r2 * 100.0),
	}
	var errou: bool = not critico and not pesado and r1 * 100.0 >= p_acerto
	var defendeu: bool = not critico and not pesado and not errou and r2 * 100.0 < p_defesa
	if errou or defendeu:
		var evento := {"tipo": "esquiva" if errou else "defesa", "ator": atq["id"], "alvo": def["id"]}
		cargas[def["id"]] = mini(CARGA_PESADO, int(cargas.get(def["id"], 0)) + 1)
		var oc := base.duplicate()
		oc["dano"] = 0
		return {"evento": evento, "oculto": oc, "acertou": false}
	var dano_f: float = dano_base(atq) * (EXAUSTO_DANO if exausto else 1.0)
	var dano: int = maxi(1, int(floor(dano_f + 0.5)) + (6 if critico else 0))
	if def["passiva"] == "resistencia":
		dano = maxi(1, dano - 2)
	if pesado:
		dano = int(ceil(float(dano) * BONUS_PESADO))
	def["hp"] = maxi(0, int(def["hp"]) - dano)
	if atq["passiva"] == "rede":
		presos[def["id"]] = true
	var oc2 := base.duplicate()
	oc2["dano"] = dano
	oc2["pesado"] = pesado
	return {
		"evento": {"tipo": "acerto", "ator": atq["id"], "alvo": def["id"], "dano": dano, "critico": critico, "hpRestante": def["hp"], "pesado": pesado},
		"oculto": oc2,
		"acertou": true,
	}

## Ordena por destreza decrescente, estável (iniciativa).
static func _ordenar_destreza(lista: Array) -> Array:
	var r: Array = lista.duplicate()
	for i in range(1, r.size()):
		var x = r[i]
		var j := i - 1
		while j >= 0 and int(r[j]["stats"]["destreza"]) < int(x["stats"]["destreza"]):
			r[j + 1] = r[j]
			j -= 1
		r[j + 1] = x
	return r

## Luta de equipes. `opcoes`: efeitosPoco(bool), chanceEfeito(float), rendicao(float; ausente = até a morte).
static func simular_equipes(lado_a: Array, lado_b: Array, semente: int, opcoes: Dictionary = {}) -> Dictionary:
	var rng := Rng.new(semente)
	var eventos: Array = []
	var ocultos: Array = []
	var efeitos_aplicados: Array = []
	var statuses: Dictionary = {}
	var atordoados: Dictionary = {}
	var presos: Dictionary = {}
	var cargas: Dictionary = {}
	var fora: Dictionary = {}
	var chance: float = float(opcoes.get("chanceEfeito", CHANCE_EFEITO_PADRAO))
	var tem_rendicao: bool = opcoes.has("rendicao")
	var rendicao: float = float(opcoes.get("rendicao", 0.0))
	var efeitos_poco: bool = bool(opcoes.get("efeitosPoco", false))
	var lados: Dictionary = {}
	for f in lado_a:
		lados[f["id"]] = "A"
	for f in lado_b:
		lados[f["id"]] = "B"
	var todos: Array = lado_a + lado_b
	var ultima: Dictionary = {}

	var vivos := func(lado: String) -> Array:
		var src: Array = lado_a if lado == "A" else lado_b
		return src.filter(func(f): return not fora.has(f["id"]))

	var aplicar_efeito := func(alvo: Dictionary, tipo: String) -> void:
		eventos.append({"tipo": "aplicado", "alvo": alvo["id"], "nome": tipo})
		efeitos_aplicados.append({"alvo": alvo["id"], "tipo": tipo})
		var lista: Array = statuses.get(alvo["id"], [])
		if tipo == "sangramento": lista.append({"tipo": tipo, "rodadas": 2, "dano": 2})
		if tipo == "envenenamento": lista.append({"tipo": tipo, "rodadas": 4, "dano": 1})
		if tipo == "queimadura": lista.append({"tipo": tipo, "rodadas": 1, "dano": 3})
		if tipo == "contusao": atordoados[alvo["id"]] = true
		statuses[alvo["id"]] = lista

	var apurar := func(f: Dictionary) -> void:
		if fora.has(f["id"]):
			return
		if not tem_rendicao:
			if int(f["hp"]) <= 0:
				eventos.append({"tipo": "morte", "alvo": f["id"]})
				fora[f["id"]] = true
			return
		if int(f["hp"]) <= 0:
			f["hp"] = 1
		if float(f["hp"]) <= float(f["hpMax"]) * rendicao:
			eventos.append({"tipo": "rendicao", "alvo": f["id"]})
			fora[f["id"]] = true

	var anunciar_carga := func(a: Dictionary, b: Dictionary) -> void:
		for f in [a, b]:
			var v: int = int(cargas.get(f["id"], 0))
			var ult = ultima.get(f["id"], null)
			if ult == v or (ult == null and v == 0):
				continue
			ultima[f["id"]] = v
			eventos.append({"tipo": "carga", "alvo": f["id"], "valor": v, "max": CARGA_PESADO})

	var golpear := func(rodada: int, atq: Dictionary, def: Dictionary) -> void:
		var r: Dictionary = resolver_ataque(atq, def, rng, rodada, presos, cargas)
		eventos.append(r["evento"])
		ocultos.append(r["oculto"])
		anunciar_carga.call(atq, def)
		if r["acertou"] and int(def["hp"]) > 0 and efeitos_poco and rng.proximo() < chance * maxf(0.2, 1.0 - RESISTENCIA_EFEITO * float(def["stats"]["resistencia"])):
			aplicar_efeito.call(def, TIPOS_EFEITO[rng.inteiro(0, TIPOS_EFEITO.size() - 1)])
		apurar.call(def)
		if r["acertou"] and atq["passiva"] == "sequencia" and not fora.has(def["id"]) and rng.proximo() < CHANCE_SEQUENCIA:
			var extra: Dictionary = resolver_ataque(atq, def, rng, rodada, presos, cargas)
			eventos.append(extra["evento"])
			ocultos.append(extra["oculto"])
			anunciar_carga.call(atq, def)
			apurar.call(def)

	var rodada := 1
	while rodada <= MAX_RODADAS and vivos.call("A").size() > 0 and vivos.call("B").size() > 0:
		var ordem: Array = _ordenar_destreza(todos.filter(func(f): return not fora.has(f["id"])))
		for atq in ordem:
			if fora.has(atq["id"]):
				continue
			var inimigos: Array = vivos.call("B" if lados[atq["id"]] == "A" else "A")
			if inimigos.size() == 0:
				break
			if atordoados.has(atq["id"]):
				atordoados.erase(atq["id"])
				eventos.append({"tipo": "atordoado", "alvo": atq["id"]})
				continue
			golpear.call(rodada, atq, inimigos[rng.inteiro(0, inimigos.size() - 1)])
		for f in todos:
			if fora.has(f["id"]):
				continue
			var lista: Array = statuses.get(f["id"], [])
			for s in lista:
				if int(s["rodadas"]) <= 0 or fora.has(f["id"]):
					continue
				f["hp"] = maxi(0, int(f["hp"]) - int(s["dano"]))
				s["rodadas"] = int(s["rodadas"]) - 1
				eventos.append({"tipo": "efeito", "alvo": f["id"], "nome": s["tipo"], "dano": s["dano"], "hpRestante": f["hp"]})
				apurar.call(f)
			statuses[f["id"]] = lista.filter(func(s): return int(s["rodadas"]) > 0)
		for f in todos:
			if not fora.has(f["id"]):
				f["est"] = clampi(int(f["est"]) + EST_REGEN + int(FAIXA_REGEN.get(f.get("faixa", "normal"), 0)), 0, int(f["estMax"]))
		rodada += 1

	var a_vivo: bool = vivos.call("A").size() > 0
	var b_vivo: bool = vivos.call("B").size() > 0
	var vencedor: String
	if a_vivo != b_vivo:
		vencedor = "A" if a_vivo else "B"
	else:
		var soma_a := 0
		var soma_b := 0
		var vit_a := 0
		var vit_b := 0
		for f in lado_a:
			soma_a += int(f["hp"]); vit_a += int(f["stats"]["vitalidade"])
		for f in lado_b:
			soma_b += int(f["hp"]); vit_b += int(f["stats"]["vitalidade"])
		if soma_a != soma_b:
			vencedor = "A" if soma_a > soma_b else "B"
		else:
			vencedor = "A" if vit_a >= vit_b else "B"
	return {"vencedorLado": vencedor, "eventos": eventos, "ocultos": ocultos, "efeitosAplicados": efeitos_aplicados}
