class_name ArenaNova
extends Node2D
## Arena pintada: base vazia + camarote + público feito de pessoas individuais (recortes de assets/arenas/novo/<id>_pessoas.png).
## Cada pessoa tem seu ritmo e reage sozinha aos golpes. Sem os arquivos, montar() devolve false.

const DIR := "assets/arenas/novo/"
const OCUP := {"vazia": 0.35, "meia": 0.7, "cheia": 1.0}
const ALTURA_SENTADO := 86.0
const ALTURA_DE_PE := 100.0

var vel := 1.0
var posicoes: Array = []   ## {x, y} no palco, origem das moedas
var _gente: Array = []
var _t := 0.0
var _excit := 0.0


static func existe(id: String) -> bool:
	return ResourceLoader.exists("res://" + DIR + id + "_vazia.jpg") and FileAccess.file_exists("res://" + DIR + id + "_publico.json")


func montar(id: String, lotacao: String, palco: Vector2) -> bool:
	if not existe(id):
		return false
	var base: Texture2D = Tema.textura(DIR + id + "_vazia.jpg")
	var folha: Texture2D = Tema.textura(DIR + id + "_pessoas.png")
	if base == null or folha == null:
		return false
	var k := palco / base.get_size()
	var bg := Sprite2D.new()
	bg.centered = false
	bg.texture = base
	bg.scale = k
	bg.z_index = -10
	add_child(bg)
	var d: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://" + DIR + id + "_publico.json"))
	var cam: Dictionary = d["camarote"]
	var cs := _sprite(folha, cam)
	cs.position = Vector2(390, 189) * k
	cs.scale = k * (279.0 / float(cam["h"]))
	cs.z_index = -9
	add_child(cs)
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var ocup: float = float(OCUP.get(lotacao, 0.7))
	var assentos: Array = (d["assentos"] as Array).duplicate()
	assentos.shuffle()
	var n := int(round(assentos.size() * ocup))
	var pessoas: Array = d["pessoas"]
	for i in range(n):
		var a: Array = assentos[i]
		var p: Dictionary = pessoas[rng.randi() % pessoas.size()]
		var s := _sprite(folha, p)
		var alvo: float = (ALTURA_SENTADO if p["sentado"] else ALTURA_DE_PE) * rng.randf_range(0.92, 1.08)
		var esc := alvo / float(p["h"]) * k.y
		s.scale = Vector2(esc * (1.0 if rng.randf() < 0.5 else -1.0), esc)
		s.centered = false
		s.offset = Vector2(-float(p["w"]) / 2.0, -float(p["h"]))   # origem nos pés
		var pos := Vector2(float(a[0]) * k.x + rng.randf_range(-5, 5), float(a[1]) * k.y)
		s.position = pos
		s.z_index = -9
		add_child(s)
		_gente.append({"n": s, "y0": pos.y, "x0": pos.x, "fase": rng.randf() * TAU, "ritmo": rng.randf_range(0.8, 1.3),
			"alegre": bool(p["alegre"]), "sens": rng.randf_range(0.6, 1.3), "pulo": 0.0})
		posicoes.append({"x": pos.x, "y": pos.y - alvo * k.y * 0.8})
	# primeira fileira (de trás) desenhada antes
	_gente.sort_custom(func(a, b): return float(a["y0"]) < float(b["y0"]))
	for i in range(_gente.size()):
		(_gente[i]["n"] as Sprite2D).z_index = -9
		move_child(_gente[i]["n"], -1)
	var fr: Texture2D = Tema.textura(DIR + id + "_frente.png")
	if fr != null:
		var f := Sprite2D.new()
		f.centered = false
		f.texture = fr
		var ef := palco.x / fr.get_width()
		f.scale = Vector2(ef, ef)
		f.position = Vector2(0, palco.y - fr.get_height() * ef)
		f.z_index = -8
		add_child(f)
	return true


func _sprite(folha: Texture2D, r: Dictionary) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = folha
	s.region_enabled = true
	s.region_rect = Rect2(float(r["x"]), float(r["y"]), float(r["w"]), float(r["h"]))
	s.centered = false
	return s


## Público reage ao que acontece na luta (1.0 = comoção forte); cada um com sua intensidade.
func reagir(forca: float) -> void:
	_excit = clampf(_excit + forca, 0.0, 1.5)
	for g: Dictionary in _gente:
		if randf() < 0.35 + forca * 0.4:
			g["pulo"] = float(g["sens"]) * forca


func _process(delta: float) -> void:
	_t += delta * vel
	_excit = maxf(0.0, _excit - delta * 0.7)
	for g: Dictionary in _gente:
		var s: Sprite2D = g["n"]
		var pulo: float = maxf(0.0, float(g["pulo"]) - delta * 1.6)
		g["pulo"] = pulo
		var ph: float = _t * 2.0 * float(g["ritmo"]) + float(g["fase"])
		var y := float(g["y0"]) + sin(ph) * 0.8
		if bool(g["alegre"]):
			y += sin(_t * 5.0 * float(g["ritmo"]) + float(g["fase"])) * 1.2
		y -= absf(sin(ph * 3.0)) * pulo * 7.0 + _excit * 1.5 * absf(sin(ph * 2.0))
		s.position = Vector2(float(g["x0"]) + sin(ph * 1.7) * pulo * 1.5, y)
		s.rotation = sin(ph * 0.7) * 0.02 + sin(ph * 2.5) * pulo * 0.05
