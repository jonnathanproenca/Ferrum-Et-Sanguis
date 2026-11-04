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

static func criar_lutador(id: String, nome: String, stats: Dictionary, passiva: String = "") -> Dictionary:
	var hp_max: int = 50 + int(stats["vitalidade"]) * 5
	return {"id": id, "nome": nome, "stats": stats.duplicate(), "hpMax": hp_max, "hp": hp_max, "passiva": passiva}

static func bonus(valor: int) -> int:
	return int(floor(float(valor - 5) / 2.0))

## Um golpe. `presos` e `cargas` são Dictionaries mutáveis (conjunto e mapa).
static func resolver_ataque(atq: Dictionary, def: Dictionary, rng: Rng, rodada: int, presos: Dictionary, cargas: Dictionary) -> Dictionary:
	var rol_atq: int = rng.d20()
	var rol_def: int = rng.d20()
	var bonus_atq: int = bonus(int(atq["stats"]["agilidade"])) + bonus(int(atq["stats"]["sorte"]))
	var bonus_def: int = bonus(int(def["stats"]["agilidade"]))
	if def["passiva"] == "guarda":
		bonus_def += 2
	if presos.has(def["id"]):
		bonus_def -= 2
		presos.erase(def["id"])
	var pesado: bool = int(cargas.get(atq["id"], 0)) >= CARGA_PESADO
	if pesado:
		cargas[atq["id"]] = 0
	var critico: bool = rol_atq == 20
	var base := {
		"rodada": rodada, "atacante": atq["id"], "defensor": def["id"],
		"rolagemAtaque": rol_atq, "rolagemDefesa": rol_def,
		"bonusAtaque": bonus_atq, "bonusDefesa": bonus_def,
	}
	if not critico and not pesado and rol_atq + bonus_atq <= rol_def + bonus_def:
		var tipo := "esquiva" if rol_def >= 15 else "defesa"
		var evento := {"tipo": tipo, "ator": atq["id"], "alvo": def["id"]}
		cargas[def["id"]] = mini(CARGA_PESADO, int(cargas.get(def["id"], 0)) + 1)
		var oc := base.duplicate()
		oc["dano"] = 0
		return {"evento": evento, "oculto": oc, "acertou": false}
	var dano: int = maxi(1, bonus(int(atq["stats"]["forca"])) + 6 + (6 if critico else 0) - bonus(int(def["stats"]["vitalidade"])))
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

## Ordena por agilidade decrescente, estável (como o sort do JavaScript).
static func _ordenar_agilidade(lista: Array) -> Array:
	var r: Array = lista.duplicate()
	for i in range(1, r.size()):
		var x = r[i]
		var j := i - 1
		while j >= 0 and int(r[j]["stats"]["agilidade"]) < int(x["stats"]["agilidade"]):
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
		if r["acertou"] and int(def["hp"]) > 0 and efeitos_poco and rng.proximo() < chance:
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
		var ordem: Array = _ordenar_agilidade(todos.filter(func(f): return not fora.has(f["id"])))
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
