class_name PlateiaLuta
extends Node2D
## Plateia em pixel art desenhada por cima do fundo da arena (porte de espectadores.ts). Coordenadas da imagem 1024x576 do
## original, convertidas para o palco de 1280x720 (fator 1,25).

const K := 1.25
const FILEIRAS := {
	"pompeia": [
		[[[24, 138], [120, 176], [250, 214], [380, 236], [450, 242]], 34, 26],
		[[[574, 242], [644, 236], [774, 214], [904, 176], [1000, 138]], 34, 26],
	],
	"capua": [
		[[[10, 238], [110, 232], [220, 228], [330, 232], [440, 237]], 27, 20],
		[[[590, 237], [700, 232], [810, 228], [920, 232], [1014, 238]], 27, 20],
		[[[10, 388], [110, 352], [250, 322], [350, 311], [450, 303]], 30, 24],
		[[[580, 303], [680, 311], [790, 322], [900, 352], [1014, 388]], 30, 24],
	],
	"poco": [
		[[[10, 168], [120, 178], [260, 186], [390, 194]], 36, 38],
		[[[462, 178], [595, 178]], 36, 38],
		[[[640, 194], [720, 182], [800, 168]], 36, 38],
		[[[850, 200], [920, 178], [1010, 158]], 36, 38],
	],
}
const OCUPACAO := {"vazia": 0.2, "meia": 0.55, "cheia": 0.97}
const PELES := ["f0c9a0", "d9a577", "b87a4b", "8a5634"]
const CABELOS := ["2a1a10", "5a3418", "8a6a3a", "c9c9c0", "111111", "a04a22"]
const TUNICAS := ["e8dcc0", "b33a2c", "3b6ea5", "4f8a4a", "d6a92e", "7a4a8a", "8a5a34", "2d2d38", "d8d0b4", "c46a2a"]

var espectadores: Array = []    ## {x, y, h, pele, cabelo, tunica, anima}
var _fase := 0
var _acc := 0.0
var vel := 1.0
var animar := true

static func _fileiras(arena_id: String) -> Array:
	if FILEIRAS.has(arena_id):
		return FILEIRAS[arena_id]
	# Coliseu: 3 níveis altos + 7 baixos, de cada lado
	var r: Array = []
	for k in range(3):
		r.append([[[8, 176 - 9 * k], [130, 190 - 9 * k], [250, 202 - 9 * k], [380, 208 - 9 * k], [470, 210 - 9 * k]], 12, 13])
	for k in range(3):
		r.append([[[560, 210 - 9 * k], [640, 207 - 9 * k], [740, 198 - 9 * k], [840, 182 - 9 * k], [920, 164 - 9 * k]], 12, 13])
	for k in range(7):
		r.append([[[10, 376 - 9 * k], [100, 362 - 9 * k], [200, 348 - 9 * k], [300, 338 - 9 * k], [420, 330 - 9 * k], [470, 328 - 9 * k]], 13, 16])
	for k in range(7):
		r.append([[[560, 332 - 9 * k], [680, 338 - 9 * k], [800, 347 - 9 * k], [900, 366 - 9 * k], [975, 388 - 9 * k]], 13, 16])
	return r

static func _y_em(pontos: Array, x: float) -> float:
	if x <= float(pontos[0][0]):
		return float(pontos[0][1])
	for i in range(1, pontos.size()):
		var a: Array = pontos[i - 1]
		var b: Array = pontos[i]
		if x <= float(b[0]):
			var t := (x - float(a[0])) / maxf(1.0, float(b[0]) - float(a[0]))
			return lerpf(float(a[1]), float(b[1]), t)
	return float(pontos[pontos.size() - 1][1])

func montar(arena_id: String, lotacao: String, semente: int = 0) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = semente if semente != 0 else randi()
	var ocup: float = float(OCUPACAO.get(lotacao, 0.5))
	espectadores.clear()
	for fila in _fileiras(arena_id):
		var pontos: Array = fila[0]
		var passo: float = float(fila[1])
		var alt: float = float(fila[2])
		var x0: float = float(pontos[0][0])
		var x1: float = float(pontos[pontos.size() - 1][0])
		var x := x0
		while x <= x1:
			if rng.randf() <= ocup:
				var px := x + (rng.randf() - 0.5) * passo * 0.6
				espectadores.append({
					"x": px * K, "y": (_y_em(pontos, px) + (rng.randf() - 0.5) * 2.0) * K,
					"h": alt * (0.92 + rng.randf() * 0.16) * K,
					"pele": Color(PELES[rng.randi() % PELES.size()]), "cabelo": Color(CABELOS[rng.randi() % CABELOS.size()]),
					"tunica": Color(TUNICAS[rng.randi() % TUNICAS.size()]), "anima": rng.randf() < 0.3,
				})
			x += passo
	espectadores.sort_custom(func(a, b): return a["y"] < b["y"])
	queue_redraw()

func animar_festa(ligar: bool) -> void:
	animar = ligar

func _process(delta: float) -> void:
	_acc += delta * vel
	var f := int(_acc / 0.5) % 2
	if f != _fase:
		_fase = f
		queue_redraw()

func _draw() -> void:
	for s in espectadores:
		var h: float = s["h"]
		var u: float = maxf(1.0, roundf(h / 10.0))
		var x: float = roundf(float(s["x"]))
		var y: float = roundf(float(s["y"]))
		var erg: bool = s["anima"] and _fase == 1 and animar
		var dy := -u if erg else 0.0
		var tun: Color = s["tunica"]
		# pernas e corpo
		draw_rect(Rect2(x - 2 * u, y - 2 * u, 4 * u, 2 * u), tun.darkened(0.45))
		draw_rect(Rect2(x - 3 * u, y - 7 * u + dy * 0.0, 6 * u, 5 * u), tun)
		draw_rect(Rect2(x - 3 * u, y - 7 * u, 6 * u, u), tun.lightened(0.18))
		# braços
		if erg:
			draw_rect(Rect2(x - 4 * u, y - 10 * u, u, 4 * u), s["pele"])
			draw_rect(Rect2(x + 3 * u, y - 10 * u, u, 4 * u), s["pele"])
		else:
			draw_rect(Rect2(x - 4 * u, y - 6 * u, u, 3 * u), s["pele"])
			draw_rect(Rect2(x + 3 * u, y - 6 * u, u, 3 * u), s["pele"])
		# cabeça e cabelo
		draw_rect(Rect2(x - 2 * u, y - 11 * u + dy, 4 * u, 4 * u), s["pele"])
		draw_rect(Rect2(x - 2 * u, y - 11 * u + dy, 4 * u, 1.5 * u), s["cabelo"])
