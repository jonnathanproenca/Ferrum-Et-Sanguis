class_name Anim
extends Control
## Animação em loop a partir de uma folha de sprites gerada por tools/converter_webp.py (assets/anim/<nome>.png + .json).
## O controle ocupa o tamanho do quadro original (dividido pela escala da conversão); redimensione com `size` / `custom_minimum_size`.

var _folha: Texture2D
var _meta: Dictionary = {}
var _t := 0.0
var _frame := 0
var vel := 1.0

## nome: "medico", "engenheiro", "mercador", "ferreiro", "brasa". `tamanho_original`: tamanho do quadro no jogo em TypeScript.
static func criar(nome: String) -> Anim:
	var a := Anim.new()
	a._carregar(nome)
	return a

func _carregar(nome: String) -> void:
	_folha = load("res://assets/anim/%s.webp" % nome)
	_meta = Util.ler_json("res://assets/anim/%s.json" % nome)
	var esc: float = float(_meta.get("escala", 1.0))
	custom_minimum_size = Vector2(float(_meta["w"]) / esc, float(_meta["h"]) / esc)
	size = custom_minimum_size
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _process(delta: float) -> void:
	if _meta.is_empty() or not is_visible_in_tree():
		return
	_t += delta * vel
	var f := int(_t * float(_meta["fps"])) % int(_meta["n"])
	if f != _frame:
		_frame = f
		queue_redraw()

func _draw() -> void:
	if _folha == null:
		return
	var w: float = float(_meta["w"])
	var h: float = float(_meta["h"])
	var cols: int = int(_meta["cols"])
	var src := Rect2(float(_frame % cols) * w, float(_frame / cols) * h, w, h)
	draw_texture_rect_region(_folha, Rect2(Vector2.ZERO, size), src)
