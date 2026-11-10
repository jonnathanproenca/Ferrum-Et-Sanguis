class_name Estilos3D
extends RefCounted
## Estilos do gladiador 2 (3D): cada estilo combina arma da mão direita, mão esquerda, capacete e peças extras.
## Os acessórios vêm de modelos soltos (Quaternius / Kickin It) e de peças procedurais (capacetes, manica, galerus).

const ORDEM: Array = ["g1", "tracio", "samnita", "murmilo", "hoplomaco", "dimachaerus", "retiario", "scissor", "nu"]

const ESTILOS := {
	"g1": {"nome": "Gladiador 1 (Murmilo)"},
	"tracio": {"nome": "Trácio", "dir": "sica", "esq": "escudo_pequeno", "capacete": "tracio", "extras": ["manica_dir"]},
	"samnita": {"nome": "Samnita", "dir": "gladio", "esq": "escudo_scutum", "capacete": "samnita", "extras": ["manica_dir"]},
	"murmilo": {"nome": "Murmilo (2)", "dir": "gladio", "esq": "escudo_scutum", "capacete": "murmilo", "extras": ["manica_dir"]},
	"hoplomaco": {"nome": "Hoplomaco", "dir": "lanca", "esq": "escudo_redondo", "capacete": "corinto", "extras": []},
	"dimachaerus": {"nome": "Dimachaerus", "dir": "gladio", "esq": "espada_esq", "capacete": "aberto", "extras": ["manica_dir", "manica_esq"]},
	"retiario": {"nome": "Retiário", "dir": "tridente", "esq": "", "capacete": "", "extras": ["galerus", "manica_esq"]},
	"scissor": {"nome": "Scissor", "dir": "gladio", "esq": "lamina_punho", "capacete": "aberto", "extras": ["manica_esq"]},
	"nu": {"nome": "Sem equipamento", "dir": "", "esq": "", "capacete": "", "extras": []},
}

## Armas na mão: caminho, comprimento do modelo (medido), comprimento desejado em metros, rotação para a lâmina ficar em +Y.
## fbx = true: os FBX trazem escala embutida (x100 em relação ao tamanho medido).
const ARMAS := {
	"gladio": {"p": "res://assets/3d/gladio.glb", "len": 0.6, "m": 0.57, "fbx": false},
	"espada": {"p": "res://assets/3d/acc/q_Sword_2.fbx", "len": 0.0536, "m": 0.62, "fbx": true},
	"sica": {"p": "res://assets/3d/acc/k_Kopesh.fbx", "len": 0.01372, "m": 0.52, "fbx": true, "rx": 90.0, "tex": true},
	"lanca": {"p": "res://assets/3d/acc/q_Spear.fbx", "len": 0.0972, "m": 1.9, "fbx": true},
	"tridente": {"p": "res://assets/3d/acc/k_Pitchfork.fbx", "len": 0.02257, "m": 1.7, "fbx": true, "rx": 90.0, "tex": true},
	"lamina": {"p": "res://assets/3d/acc/q_Sword.fbx", "len": 0.0545, "m": 0.85, "fbx": true},
}

## Escudos: modelo, fator de tamanho (1 = escudo redondo padrão de 0,5 m) e giro para a ponta ficar para baixo.
const ESCUDOS := {
	"escudo_redondo": {"p": "res://assets/3d/acc/q_Shield_Round_2.fbx", "f": 1.0, "z": 0.0},
	"escudo_pequeno": {"p": "res://assets/3d/acc/q_Shield_Round.fbx", "f": 0.62, "z": 0.0},
	"escudo_scutum": {"p": "res://assets/3d/acc/q_Shield_Heater.fbx", "f": 1.12, "z": -90.0, "giro_mao": 180.0},
}


static func nome(id: String) -> String:
	return str(ESTILOS.get(id, {}).get("nome", id))


# ---------- Peças procedurais (em metros; o chamador escala para o esqueleto) ----------

static func _mat(c: Color, metal := 0.0, rug := 0.7) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.metallic = metal
	m.roughness = rug
	return m


static func _mi(mesh: Mesh, mat: Material, pos: Vector3, rot := Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	mi.rotation_degrees = rot
	return mi


static func _caixa(tam: Vector3) -> BoxMesh:
	var b := BoxMesh.new()
	b.size = tam
	return b


static func _cil(r_cima: float, r_baixo: float, h: float) -> CylinderMesh:
	var c := CylinderMesh.new()
	c.top_radius = r_cima
	c.bottom_radius = r_baixo
	c.height = h
	c.radial_segments = 20
	return c


static func _domo(r: float) -> SphereMesh:
	var s := SphereMesh.new()
	s.radius = r
	s.height = r
	s.is_hemisphere = true
	s.radial_segments = 24
	s.rings = 10
	return s


## Capacete: a origem fica no centro da cabeça; +Y cima, +Z frente.
static func capacete(tipo: String) -> Node3D:
	var raiz := Node3D.new()
	var bronze := _mat(Color("b08a3c"), 0.7, 0.4)
	var ferro := _mat(Color("7d8088"), 0.8, 0.45)
	var pluma := _mat(Color("a32a1f"), 0.0, 0.9)
	if tipo == "tracio":
		raiz.add_child(_mi(_domo(0.125), ferro, Vector3(0, 0.03, 0)))
		raiz.add_child(_mi(_cil(0.19, 0.19, 0.012), ferro, Vector3(0, 0.03, 0)))   # aba larga
		raiz.add_child(_mi(_caixa(Vector3(0.03, 0.17, 0.19)), ferro, Vector3(0, 0.2, 0.0)))  # crista
		raiz.add_child(_mi(_domo(0.045), bronze, Vector3(0, 0.25, 0.1), Vector3(90, 0, 0)))  # cabeça do grifo
		raiz.add_child(_mi(_caixa(Vector3(0.015, 0.14, 0.09)), ferro, Vector3(0.115, -0.04, 0.03)))
		raiz.add_child(_mi(_caixa(Vector3(0.015, 0.14, 0.09)), ferro, Vector3(-0.115, -0.04, 0.03)))
	elif tipo == "samnita":
		raiz.add_child(_mi(_domo(0.13), bronze, Vector3(0, 0.03, 0)))
		raiz.add_child(_mi(_caixa(Vector3(0.22, 0.06, 0.02)), bronze, Vector3(0, 0.035, 0.125)))  # viseira alta
		raiz.add_child(_mi(_caixa(Vector3(0.016, 0.13, 0.1)), bronze, Vector3(0.12, -0.04, 0.02)))
		raiz.add_child(_mi(_caixa(Vector3(0.016, 0.13, 0.1)), bronze, Vector3(-0.12, -0.04, 0.02)))
		raiz.add_child(_mi(_caixa(Vector3(0.025, 0.2, 0.05)), pluma, Vector3(0, 0.22, -0.02)))  # pluma
	elif tipo == "murmilo":
		raiz.add_child(_mi(_domo(0.13), bronze, Vector3(0, 0.03, 0)))
		raiz.add_child(_mi(_caixa(Vector3(0.24, 0.17, 0.02)), bronze, Vector3(0, -0.02, 0.125)))  # grade do rosto
		raiz.add_child(_mi(_caixa(Vector3(0.016, 0.16, 0.12)), bronze, Vector3(0.125, -0.03, 0.0)))
		raiz.add_child(_mi(_caixa(Vector3(0.016, 0.16, 0.12)), bronze, Vector3(-0.125, -0.03, 0.0)))
		raiz.add_child(_mi(_caixa(Vector3(0.03, 0.15, 0.3)), bronze, Vector3(0, 0.2, -0.02)))  # crista de peixe
		raiz.add_child(_mi(_caixa(Vector3(0.012, 0.08, 0.22)), pluma, Vector3(0, 0.28, -0.04)))
	elif tipo == "corinto":
		raiz.add_child(_mi(_domo(0.135), bronze, Vector3(0, 0.04, 0)))
		raiz.add_child(_mi(_caixa(Vector3(0.03, 0.12, 0.02)), bronze, Vector3(0, -0.01, 0.125)))   # nasal
		raiz.add_child(_mi(_caixa(Vector3(0.016, 0.15, 0.1)), bronze, Vector3(0.125, -0.04, 0.02)))
		raiz.add_child(_mi(_caixa(Vector3(0.016, 0.15, 0.1)), bronze, Vector3(-0.125, -0.04, 0.02)))
		raiz.add_child(_mi(_caixa(Vector3(0.05, 0.08, 0.32)), pluma, Vector3(0, 0.2, -0.02)))  # penacho longitudinal
	elif tipo == "aberto":
		raiz.add_child(_mi(_domo(0.128), ferro, Vector3(0, 0.035, 0)))
		raiz.add_child(_mi(_caixa(Vector3(0.016, 0.1, 0.09)), ferro, Vector3(0.12, -0.03, 0.02)))
		raiz.add_child(_mi(_caixa(Vector3(0.016, 0.1, 0.09)), ferro, Vector3(-0.12, -0.03, 0.02)))
	return raiz


## Manica (proteção de braço): cilindro com o eixo em +Y; o chamador gira para o eixo do braço.
static func manica() -> Node3D:
	var raiz := Node3D.new()
	var couro := _mat(Color("5a3a22"), 0.0, 0.85)
	var ferro := _mat(Color("7d8088"), 0.8, 0.45)
	raiz.add_child(_mi(_cil(0.058, 0.064, 0.3), couro, Vector3.ZERO))
	for y in [-0.1, 0.0, 0.1]:
		raiz.add_child(_mi(_cil(0.066, 0.066, 0.018), ferro, Vector3(0, y, 0)))
	return raiz


## Galerus: ombreira alta do retiário.
static func galerus() -> Node3D:
	var raiz := Node3D.new()
	var bronze := _mat(Color("b08a3c"), 0.7, 0.4)
	var d := _domo(0.15)
	raiz.add_child(_mi(d, bronze, Vector3.ZERO))
	raiz.add_child(_mi(_caixa(Vector3(0.012, 0.2, 0.2)), bronze, Vector3(0.0, 0.1, -0.03), Vector3(0, 0, -12)))
	return raiz
