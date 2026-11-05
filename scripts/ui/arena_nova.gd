class_name ArenaNova
extends Node2D
## Arena pintada em camadas: base vazia + figuras do público (recortes com balanço) + faixa de primeiro plano.
## Só vale se existirem os arquivos assets/arenas/novo/<id>_vazia.jpg e <id>_publico.png/.json; senão montar() devolve false.

const DIR := "assets/arenas/novo/"
const OCUP := {"vazia": 0.5, "meia": 0.8, "cheia": 1.0}

var vel := 1.0
var posicoes: Array = []   ## {x, y} no palco 1280x720, para a origem das moedas
var _fig: Array = []
var _t := 0.0
var _excit := 0.0
var _mat: ShaderMaterial

const SHADER := """
shader_type canvas_item;
uniform float amp = 1.5;
uniform float freq = 2.2;
uniform float sway = 0.0;
uniform vec2 tam = vec2(1376.0, 768.0);
uniform float fase = 0.0;
void fragment() {
	vec2 px = UV * tam;
	float w = 0.045 * px.x + 0.025 * px.y + fase;
	float oy = sin(TIME * freq + w) * amp + sin(TIME * freq * 2.3 + w * 1.7) * amp * 0.4 * sway;
	float ox = sin(TIME * freq * 1.4 + w * 1.3) * sway * 1.0;
	COLOR = texture(TEXTURE, UV + vec2(ox, oy) / tam);
}
"""


static func existe(id: String) -> bool:
	return ResourceLoader.exists("res://" + DIR + id + "_vazia.jpg") and FileAccess.file_exists("res://" + DIR + id + "_publico.json")


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
	var sh := Shader.new()
	sh.code = SHADER
	_mat = ShaderMaterial.new()
	_mat.shader = sh
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var ocup: float = float(OCUP.get(lotacao, 0.8))
	for b: Dictionary in d["blobs"]:
		if not b.has("fixo") and rng.randf() > ocup:
			continue
		var s := Sprite2D.new()
		s.texture = pub
		s.region_enabled = true
		s.region_rect = Rect2(float(b["esq"]), float(b["topo"]), float(b["w"]), float(b["h"]))
		s.centered = false
		s.scale = k
		s.position = Vector2(float(b["esq"]), float(b["topo"])) * k
		s.z_index = -9
		if not b.has("fixo"):
			s.material = _mat
		add_child(s)
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


## Público reage ao que acontece na luta (1.0 = comoção forte).
func reagir(forca: float) -> void:
	_excit = clampf(_excit + forca, 0.0, 1.5)


func _process(delta: float) -> void:
	if _mat == null:
		return
	_excit = maxf(0.0, _excit - delta * 0.7)
	_mat.set_shader_parameter("amp", 0.45 + _excit * 1.6)
	_mat.set_shader_parameter("freq", (1.3 + _excit * 1.2) * vel)
	_mat.set_shader_parameter("sway", _excit)
