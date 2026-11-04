class_name Sprites
extends RefCounted
## Texturas dos gladiadores e variantes de cor (mesmas regras de sprites.ts / variantes.ts / mercado.ts).

const VARIANTES: Array = [
	{"rot": 0.0, "pele": 1.0}, {"rot": 120.0, "pele": 0.86}, {"rot": 200.0, "pele": 0.72},
	{"rot": 270.0, "pele": 1.1}, {"rot": 335.0, "pele": 0.8}, {"rot": 60.0, "pele": 0.94},
]
const SPRITES_ESCRAVO := ["galia", "germania", "tracia", "dacia", "numidia", "hispania", "siria", "britania"]
const APARENCIA_POR_CONDICAO := {"maduro": 0, "cicatrizado": 1, "jovem": 2}

static var _shader: Shader

static func variante_de(id: String) -> int:
	if id == "campeao-batiatus":
		return 0
	var h: int = 2166136261
	for i in range(id.length()):
		h = ((h ^ id.unicode_at(i)) * 16777619) & 0xFFFFFFFF
	return h % VARIANTES.size()

## Material que aplica a variante de cor do gladiador `id` (null para a variante original).
static func material_variante(id: String) -> ShaderMaterial:
	var v: int = variante_de(id)
	if v == 0:
		return null
	if _shader == null:
		_shader = load("res://shaders/recolor.gdshader")
	var m := ShaderMaterial.new()
	m.shader = _shader
	m.set_shader_parameter("rot", float(VARIANTES[v]["rot"]))
	m.set_shader_parameter("pele", float(VARIANTES[v]["pele"]))
	return m

## Pose do gladiador de uma classe: guarda, respira, prepara, impacto, recupera, alt, defende, esquiva, dano, critico, cai, morto.
static func pose(classe: String, nome: String = "guarda") -> Texture2D:
	return Tema.textura("assets/gladiadores/%s/%s.png" % [classe, nome])

static func escravo(terra: String, look: int, condicao: String = "") -> Texture2D:
	var t: String = terra if terra in SPRITES_ESCRAVO else "galia"
	var idx: int = int(APARENCIA_POR_CONDICAO[condicao]) if APARENCIA_POR_CONDICAO.has(condicao) else look
	var sufixo := "" if idx % 3 == 0 else "-v%d" % (idx % 3 + 1)
	return Tema.textura("assets/gladiadores/escravo/%s%s.png" % [t, sufixo])

## TextureRect já pronto com o sprite do gladiador `g` (escravo sem estilo ou pose de guarda com a cor do id).
static func controle_gladiador(g: Dictionary, altura: float = 160.0) -> TextureRect:
	var tr := TextureRect.new()
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if g.get("semEstilo", false):
		tr.texture = escravo(g["terra"], int(g["look"]), str(g.get("condicao", "")))
	else:
		tr.texture = pose(g["classe"], "guarda")
		tr.material = material_variante(g["id"])
	var tam: Vector2 = tr.texture.get_size() if tr.texture else Vector2(100, 100)
	tr.custom_minimum_size = Vector2(altura * tam.x / tam.y, altura)
	return tr
