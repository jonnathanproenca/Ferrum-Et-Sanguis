class_name AncorasPoses
extends RefCounted
## Âncora (ponto do chão sob o gladiador, em pixels do quadro) de cada pose e altura de guarda por classe (de src/art/sprites.ts).

const DADOS := {
	"dimachaerus": {"altura": 232.0, "ancoras": {
		"guarda": Vector2(70.5, 231.0),
		"respira": Vector2(66.6, 231.0),
		"prepara": Vector2(82.9, 247.0),
		"impacto": Vector2(76.9, 223.0),
		"recupera": Vector2(79.6, 231.0),
		"alt": Vector2(76.4, 246.0),
		"defende": Vector2(66.1, 231.0),
		"esquiva": Vector2(81.1, 231.0),
		"dano": Vector2(75.0, 202.0),
		"critico": Vector2(94.1, 243.0),
		"cai": Vector2(99.5, 195.0),
		"morto": Vector2(122.0, 97.0),
	}},
	"murmilo": {"altura": 243.0, "ancoras": {
		"guarda": Vector2(65.0, 242.0),
		"respira": Vector2(65.4, 243.0),
		"prepara": Vector2(65.3, 239.0),
		"impacto": Vector2(72.7, 237.0),
		"recupera": Vector2(66.5, 242.0),
		"defende": Vector2(66.3, 231.0),
		"empurrao": Vector2(71.3, 234.0),
		"esquiva": Vector2(61.9, 231.0),
		"dano": Vector2(96.6, 241.0),
		"critico": Vector2(89.8, 177.0),
		"cai": Vector2(109.5, 205.0),
		"morto": Vector2(121.5, 93.0),
	}},
	"tracio": {"altura": 274.0, "ancoras": {
		"guarda": Vector2(78.9, 274.0),
		"respira": Vector2(75.1, 274.0),
		"prepara": Vector2(83.2, 279.0),
		"impacto": Vector2(77.3, 277.0),
		"recupera": Vector2(83.0, 272.0),
		"defende": Vector2(68.4, 272.0),
		"empurrao": Vector2(73.8, 262.0),
		"esquiva": Vector2(76.6, 259.0),
		"dano": Vector2(121.8, 272.0),
		"critico": Vector2(80.8, 211.0),
		"cai": Vector2(134.0, 260.0),
		"morto": Vector2(142.0, 106.0),
	}},
	"samnita": {"altura": 281.0, "ancoras": {
		"respira": Vector2(70.1, 281.0),
		"guarda": Vector2(75.7, 275.0),
		"prepara": Vector2(84.5, 268.0),
		"impacto": Vector2(96.9, 265.0),
		"recupera": Vector2(75.2, 269.0),
		"defende": Vector2(77.5, 262.0),
		"empurrao": Vector2(81.7, 262.0),
		"esquiva": Vector2(104.2, 258.0),
		"dano": Vector2(99.8, 259.0),
		"critico": Vector2(62.6, 244.0),
		"cai": Vector2(86.5, 226.0),
		"morto": Vector2(140.0, 82.0),
	}},
	"retiario": {"altura": 231.0, "ancoras": {
		"respira": Vector2(84.6, 231.0),
		"guarda": Vector2(98.8, 209.0),
		"prepara": Vector2(86.5, 231.0),
		"impacto": Vector2(78.1, 222.0),
		"recupera": Vector2(77.4, 232.0),
		"empurrao": Vector2(78.8, 232.0),
		"esquiva": Vector2(104.3, 219.0),
		"dano": Vector2(71.9, 243.0),
		"critico": Vector2(82.9, 211.0),
		"cai": Vector2(107.0, 198.0),
		"morto": Vector2(131.0, 88.0),
		"defende": Vector2(81.2, 231.0),
	}},
}

## Poses que algumas folhas não têm usam um substituto.
const SUBSTITUTO := {"respira": "guarda", "recupera": "prepara", "esquiva": "recupera", "empurrao": "defende", "dano": "critico", "critico": "dano", "cai": "critico", "morto": "cai", "alt": "impacto"}

## Pose realmente disponível para a classe (segue a cadeia de substitutos).
static func resolver(classe: String, pose: String) -> String:
	var c: Dictionary = DADOS.get(classe, DADOS["murmilo"])
	var usar := pose
	var guarda := 0
	while not c["ancoras"].has(usar) and guarda < 8:
		usar = SUBSTITUTO.get(usar, "guarda")
		guarda += 1
	return usar

static func ancora(classe: String, pose: String) -> Vector2:
	var c: Dictionary = DADOS.get(classe, DADOS["murmilo"])
	return c["ancoras"][pose]

static func altura_guarda(classe: String) -> float:
	return float(DADOS.get(classe, DADOS["murmilo"])["altura"])
