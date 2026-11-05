class_name ArenaNova
extends Node2D
## Arena pintada em camadas: base vazia + figuras do público (recortes com balanço) + faixa de primeiro plano.
## Só vale se existirem os arquivos assets/arenas/novo/<id>_vazia.jpg e <id>_publico.png/.json; senão montar() devolve false.

const DIR := "assets/arenas/novo/"
const OCUP := {"vazia": 0.55, "meia": 0.8, "cheia": 1.0}

var vel := 1.0
var posicoes: Array = []   ## {x, y} no palco 1280x720, para a origem das moedas
var _fig: Array = []
var _t := 0.0


static func existe(id: String) -> bool:
	return ResourceLoader.exists(DIR + id + "_vazia.jpg") and FileAccess.file_exists("res://" + DIR + id + "_publico.json")


func montar(id: String, lotacao: String, palco: Vector2) -> bool:
	if not existe(id):
		return false
	var base: Texture2D = Tema.textura(DIR + id + "_vazia.jpg")
	var pub: Texture2D = Tema.textura(DIR + id + "_publico.png")
	if base == null or pub == null:
		return false
	var k := palco / base.get_size()
	var bg := Sprite2D.new()
	bg.centered = false
	bg.texture = base
	bg.scale = k
	bg.z_index = -10
	add_child(bg)
	var d: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://" + DIR + id + "_publico.json"))
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var ocup: float = float(OCUP.get(lotacao, 0.8))
	for b: Dictionary in d["blobs"]:
		if rng.randf() > ocup:
			continue
		var s := Sprite2D.new()
		s.texture = pub
		s.region_enabled = true
		s.region_rect = Rect2(float(b["esq"]), float(b["topo"]), float(b["w"]), float(b["h"]))
		s.centered = false
		s.scale = k
		s.position = Vector2(float(b["esq"]), float(b["topo"])) * k
		s.z_index = -9
		add_child(s)
		_fig.append({"n": s, "y0": s.position.y, "fase": rng.randf() * TAU, "amp": 1.0 + rng.randf() * 2.0})
		posicoes.append({"x": (float(b["esq"]) + float(b["w"]) * 0.5) * k.x, "y": (float(b["topo"]) + float(b["h"]) * 0.3) * k.y})
	var fr: Texture2D = Tema.textura(DIR + id + "_frente.png")
	if fr != null:
		var f := Sprite2D.new()
		f.centered = false
		f.texture = fr
		var esc := palco.x / fr.get_width()
		f.scale = Vector2(esc, esc)
		f.position = Vector2(0, palco.y - fr.get_height() * esc)
		f.z_index = -8
		add_child(f)
	return true


func _process(delta: float) -> void:
	_t += delta * vel
	for f: Dictionary in _fig:
		(f["n"] as Sprite2D).position.y = float(f["y0"]) + sin(_t * 2.2 + float(f["fase"])) * float(f["amp"])
