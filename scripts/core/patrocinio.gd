class_name Patrocinio
extends RefCounted
## Patrocínio de patrícios romanos. Vitórias nas arenas de honra podem atrair uma oferta; a chance sobe com a Aura.
## Contrato: o patrono paga ouro por rodada enquanto o gladiador cumprir a meta (vitórias dentro do prazo).
## Falhou na meta: só perde o contrato (sem multa). Estado em e["ofertas"] e e["contratos"].

const OFERTAS_MAX := 3
const VALIDADE_OFERTA := 3  # rodadas
const CHANCE_BASE := 0.05
const CHANCE_POR_AURA := 0.005
const CHANCE_MAX := 0.5
## Só depois de derrotar este número de lanistas rivais na campanha (nome famoso) os patrícios reparam no ludus.
const CAMPANHA_MIN := 2

## Do menor para o maior prestígio. campMin: lanistas derrotados na campanha para esse tipo aparecer; peso: frequência base.
const TIPOS: Array = [
	{"id": "eques", "nome": "Eques", "titulo": "Cavaleiro", "ouro": 12, "meta": 1, "prazo": 3, "campMin": 2, "peso": 50.0},
	{"id": "edil", "nome": "Edil", "titulo": "Edil dos jogos", "ouro": 18, "meta": 2, "prazo": 4, "campMin": 2, "peso": 38.0},
	{"id": "legado", "nome": "Legado", "titulo": "Legado de legião", "ouro": 25, "meta": 2, "prazo": 4, "campMin": 2, "peso": 28.0},
	{"id": "pretor", "nome": "Pretor", "titulo": "Pretor da cidade", "ouro": 45, "meta": 2, "prazo": 3, "campMin": 4, "peso": 14.0},
	{"id": "senador", "nome": "Senador", "titulo": "Senador de Roma", "ouro": 70, "meta": 3, "prazo": 4, "campMin": 6, "peso": 6.0},
	{"id": "consul", "nome": "Cônsul", "titulo": "Cônsul de Roma", "ouro": 110, "meta": 4, "prazo": 4, "campMin": 8, "peso": 2.0},
]
const PRENOMES: Array = ["Marcus", "Lucius", "Gaius", "Publius", "Quintus", "Titus", "Aulus", "Gnaeus", "Decimus", "Servius", "Manius", "Sextus"]
const GENTES: Array = ["Cornelius", "Fabius", "Valerius", "Claudius", "Aemilius", "Licinius", "Servilius", "Junius", "Porcius", "Sempronius", "Calpurnius", "Octavius", "Pompeius", "Hortensius"]
const COGNOMES: Array = ["Rufus", "Maximus", "Crassus", "Lepidus", "Nasica", "Flaccus", "Varro", "Scaevola", "Pulcher", "Cato", "Sulla", "Gracchus", "Piso", "Metellus"]


static func tipo_por_id(id: String) -> Dictionary:
	for t in TIPOS:
		if t["id"] == id:
			return t
	return {}


static func _ofertas(e: Dictionary) -> Array:
	if not e.has("ofertas"):
		e["ofertas"] = []
	return e["ofertas"]


static func _contratos(e: Dictionary) -> Array:
	if not e.has("contratos"):
		e["contratos"] = []
	return e["contratos"]


static func ofertas(e: Dictionary) -> Array:
	return _ofertas(e)


static func contratos(e: Dictionary) -> Array:
	return _contratos(e)


static func contrato_do(e: Dictionary, glad_id: String) -> Dictionary:
	for c in _contratos(e):
		if c["gladId"] == glad_id:
			return c
	return {}


static func chance(aura: int) -> float:
	return minf(CHANCE_MAX, CHANCE_BASE + CHANCE_POR_AURA * float(maxi(0, aura)))


static func _nome_patrono(rng: Rng) -> String:
	return "%s %s %s" % [PRENOMES[rng.inteiro(0, PRENOMES.size() - 1)], GENTES[rng.inteiro(0, GENTES.size() - 1)], COGNOMES[rng.inteiro(0, COGNOMES.size() - 1)]]


## Tipos permitidos pelo avanço na campanha, sorteados por peso (Aura favorece os mais altos).
static func _sortear_tipo(rng: Rng, camp: int, aura: int) -> Dictionary:
	var elegiveis: Array = []
	var total := 0.0
	for i in range(TIPOS.size()):
		var t: Dictionary = TIPOS[i]
		if camp < int(t["campMin"]):
			continue
		var p: float = float(t["peso"])
		if i >= 3:
			p *= 1.0 + float(aura) / 50.0 * float(i) / 2.0
		elegiveis.append([t, p])
		total += p
	if elegiveis.is_empty():
		return TIPOS[0]
	var r := rng.proximo() * total
	for par in elegiveis:
		r -= float(par[1])
		if r <= 0.0:
			return par[0]
	return elegiveis[elegiveis.size() - 1][0]


## Chamado após vitória em arena de honra, para o vencedor mais célebre (maior Glória). Devolve a oferta criada ({} se não houve).
static func tentar_oferta(e: Dictionary, g: Dictionary, aura: int, rng: Rng) -> Dictionary:
	if int(e.get("campanha", 0)) < CAMPANHA_MIN:
		return {}
	if not g["vivo"] or not contrato_do(e, g["id"]).is_empty():
		return {}
	if _ofertas(e).size() >= OFERTAS_MAX:
		return {}
	for o in _ofertas(e):
		if o["gladId"] == g["id"]:
			return {}
	if rng.proximo() >= chance(aura):
		return {}
	var t := _sortear_tipo(rng, int(e.get("campanha", 0)), aura)
	var o := {
		"id": Game.novo_id(e).replace("g", "p"), "gladId": g["id"], "gladNome": g["nome"],
		"tipo": t["id"], "patrono": _nome_patrono(rng), "ouro": int(t["ouro"]), "meta": int(t["meta"]), "prazo": int(t["prazo"]),
		"validoAte": int(e["turno"]) + VALIDADE_OFERTA, "vista": false,
	}
	_ofertas(e).append(o)
	Game.registrar(e, "%s %s oferece patrocínio a %s: %d de ouro por rodada." % [t["nome"], o["patrono"], g["nome"], o["ouro"]])
	return o


static func aceitar(e: Dictionary, oferta_id: String) -> String:
	var lista := _ofertas(e)
	for i in range(lista.size()):
		var o: Dictionary = lista[i]
		if o["id"] != oferta_id:
			continue
		var g := Game.achar(e, o["gladId"])
		if g.is_empty() or not g["vivo"]:
			lista.remove_at(i)
			return "O gladiador não está mais disponível."
		if not contrato_do(e, g["id"]).is_empty():
			lista.remove_at(i)
			return "%s já tem um patrocinador." % g["nome"]
		lista.remove_at(i)
		_contratos(e).append({
			"id": o["id"], "gladId": g["id"], "gladNome": g["nome"], "tipo": o["tipo"], "patrono": o["patrono"],
			"ouro": o["ouro"], "meta": o["meta"], "prazo": o["prazo"], "desde": int(e["turno"]), "vitorias": 0,
		})
		Game.registrar(e, "%s aceitou o patrocínio de %s %s (%d de ouro por rodada; meta de %d vitórias a cada %d rodadas)." % [g["nome"], tipo_por_id(o["tipo"])["nome"], o["patrono"], o["ouro"], o["meta"], o["prazo"]])
		return ""
	return "Oferta inexistente."


static func recusar(e: Dictionary, oferta_id: String) -> String:
	var lista := _ofertas(e)
	for i in range(lista.size()):
		if lista[i]["id"] == oferta_id:
			lista.remove_at(i)
			return ""
	return "Oferta inexistente."


## Vitória do gladiador (arena de honra) conta para a meta.
static func registrar_vitoria(e: Dictionary, glad_id: String) -> void:
	var c := contrato_do(e, glad_id)
	if not c.is_empty():
		c["vitorias"] = int(c["vitorias"]) + 1


## Gladiador saiu do ludus (morte, venda, liberdade): contrato e ofertas somem.
static func remover_gladiador(e: Dictionary, glad_id: String) -> void:
	e["contratos"] = _contratos(e).filter(func(c): return c["gladId"] != glad_id)
	e["ofertas"] = _ofertas(e).filter(func(o): return o["gladId"] != glad_id)


## Fim de rodada (turno já incrementado): paga os contratos, confere metas e vence ofertas. Devolve o ouro pago.
static func fechar_rodada(e: Dictionary) -> int:
	var turno: int = int(e["turno"])
	var pago := 0
	var mantidos: Array = []
	for c in _contratos(e):
		var g := Game.achar(e, c["gladId"])
		if g.is_empty() or not g["vivo"]:
			continue
		pago += int(c["ouro"])
		if turno - int(c["desde"]) >= int(c["prazo"]):
			if int(c["vitorias"]) >= int(c["meta"]):
				c["desde"] = turno
				c["vitorias"] = 0
				Game.registrar(e, "%s cumpriu a meta e o patrocínio de %s segue." % [g["nome"], c["patrono"]])
			else:
				Game.registrar(e, "%s não cumpriu a meta: %s rompeu o patrocínio." % [g["nome"], c["patrono"]])
				continue
		mantidos.append(c)
	e["contratos"] = mantidos
	e["ofertas"] = _ofertas(e).filter(func(o): return int(o["validoAte"]) > turno)
	return pago


static func texto_meta(c: Dictionary) -> String:
	return "%d vitória%s a cada %d rodadas" % [int(c["meta"]), "" if int(c["meta"]) == 1 else "s", int(c["prazo"])]
