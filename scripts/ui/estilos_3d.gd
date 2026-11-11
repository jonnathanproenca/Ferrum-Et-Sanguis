class_name Estilos3D
extends RefCounted
## Estilos do gladiador 2 (3D): cada estilo combina arma da mão direita, mão esquerda, capacete e peças extras.
## Os acessórios vêm de modelos soltos (Quaternius / Kickin It / capacetes avulsos) e de peças procedurais.
## Tudo é medido em tempo de execução (caixa dos meshes na cadeia de nós) e normalizado para metros reais.

const ESC_M := 1.0 / 105.0            ## unidades do esqueleto por metro (instância do gladiador 2 com escala 105)
const GLAD2_ESCALA := 105.0

const ORDEM: Array = ["murmilo", "tracio", "samnita", "hoplomaco", "secutor", "provocator", "dimachaerus", "retiario", "velite", "scissor", "nu"]

## dir/esq: arma ou escudo; cap: capacete; ext: peças extras.
const ESTILOS := {
	"murmilo": {"nome": "Murmilo", "dir": "gladio", "esq": "scutum", "cap": "g_gladiador", "ext": ["manica_dir", "greva_esq"]},
	"tracio": {"nome": "Trácio", "dir": "sica", "esq": "parma", "cap": "p_tracio", "ext": ["manica_dir", "greva_dir", "greva_esq"]},
	"samnita": {"nome": "Samnita", "dir": "gladio", "esq": "scutum", "cap": "g_grego", "ext": ["manica_dir", "greva_esq"]},
	"hoplomaco": {"nome": "Hoplomaco", "dir": "lanca", "esq": "redondo", "cap": "g_espartano", "ext": ["greva_dir", "greva_esq"]},
	"secutor": {"nome": "Secutor", "dir": "gladio", "esq": "scutum", "cap": "g_metal", "ext": ["manica_dir"]},
	"provocator": {"nome": "Provocator", "dir": "gladio", "esq": "scutum", "cap": "g_gladiador", "ext": ["manica_dir", "greva_esq", "greva_dir"]},
	"dimachaerus": {"nome": "Dimachaerus", "dir": "gladio", "esq": "gladio", "cap": "p_aberto", "ext": ["manica_dir", "manica_esq"]},
	"retiario": {"nome": "Retiário", "dir": "tridente", "esq": "", "cap": "", "ext": ["galerus", "manica_esq"]},
	"velite": {"nome": "Velite", "dir": "pilum", "esq": "parma", "cap": "p_aberto", "ext": []},
	"scissor": {"nome": "Scissor", "dir": "gladio", "esq": "lamina_braco", "cap": "p_aberto", "ext": ["manica_esq"]},
	"nu": {"nome": "Sem equipamento", "dir": "", "esq": "", "cap": "", "ext": []},
}

## Armas: p = modelo, rx = giro de correção do modelo, eixo = direção cabo→ponta no modelo (depois de rx),
## m = comprimento em metros, grip = onde a mão segura (0 cabo … 1 ponta), roll = giro em torno da lâmina (graus),
## dir = direção da lâmina em T-pose (padrão: +Z, para a frente: o punho fecha nesse eixo), tex = textura Kickin It, inv = inverte a ponta.
const ARMAS := {
	"gladio": {"p": "res://assets/3d/gladio.glb", "eixo": Vector3(0, 1, 0), "m": 0.58, "grip": 0.12},
	"sica": {"p": "res://assets/3d/acc/k_Kopesh.fbx", "eixo": Vector3(0, 0, 1), "m": 0.55, "grip": 0.12, "tex": true},
	"lanca": {"p": "res://assets/3d/acc/q_Spear.fbx", "eixo": Vector3(0, 1, 0), "m": 2.0, "grip": 0.35, "axis0": true},
	"pilum": {"p": "res://assets/3d/cap/a_pilum.fbx", "eixo": Vector3(0, 1, 0), "m": 1.9, "grip": 0.4, "pilum": true, "axis0": true},
	"tridente": {"p": "res://assets/3d/acc/k_Pitchfork.fbx", "eixo": Vector3(0, 0, 1), "m": 1.7, "grip": 0.3, "tex": true, "inv": true, "axis0": true},
	"lamina_braco": {"p": "res://assets/3d/acc/q_Sword.fbx", "eixo": Vector3(0, 1, 0), "m": 0.9, "grip": 0.08, "dir": Vector3(1, 0, 0)},
}

## Escudos: f = tamanho relativo ao escudo redondo padrão, z = giro em torno do eixo da face (graus), inv = vira a face.
const ESCUDOS := {
	"redondo": {"p": "res://assets/3d/acc/q_Shield_Round_2.fbx", "f": 1.0},
	"parma": {"p": "res://assets/3d/acc/q_Shield_Round.fbx", "f": 0.62},
	"scutum": {"p": "res://assets/3d/acc/q_Shield_Heater.fbx", "f": 1.0, "z": 90.0},
}

## Capacetes: g_* = modelo 3D, p_* = procedural. w = largura em metros, rot = giro em Y para a frente apontar para +Z,
## dy/dz = deslocamento (metros) a partir da origem do osso da cabeça, cor/metal = material.
const CAPACETES := {
	"g_gladiador": {"p": "res://assets/3d/cap/h_gladiador.fbx", "w": 0.36, "rot": 0.0, "dy": -0.07, "dz": -0.02, "cor": "9c8a55", "metal": 0.7},
	"g_grego": {"p": "res://assets/3d/cap/h_grego.fbx", "w": 0.29, "rot": 0.0, "dy": -0.07, "dz": 0.02, "cor": "b08a3c", "metal": 0.7},
	"g_espartano": {"p": "res://assets/3d/cap/h_espartano.fbx", "w": 0.30, "rot": 0.0, "dy": -0.12, "dz": 0.02, "cor": "a67c3a", "metal": 0.7},
	"g_metal": {"p": "res://assets/3d/cap/h_metal.fbx", "w": 0.37, "rot": 0.0, "dy": -0.05, "dz": 0.03, "cor": "8a8f98", "metal": 0.8},
}


static func nome(id: String) -> String:
	return str(ESTILOS.get(id, {}).get("nome", id))


## Tira o cabelo da malha (triângulos com 2+ vértices de cabelo) para o capacete não ter fios atravessando.
## A máscara vem de tools/gerar_mascara_cabelo.gd.
static func sem_cabelo(inst: Node3D) -> void:
	var mask_img := load("res://assets/3d/glad2/cabelo_mask.res") as Image
	if mask_img == null:
		return
	var mask := mask_img.get_data()
	var mi := inst.find_children("*", "MeshInstance3D", true, false)[0] as MeshInstance3D
	var am := mi.mesh as ArrayMesh
	var arr := am.surface_get_arrays(0)
	var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX]
	var novo := PackedInt32Array()
	for t in range(0, idx.size(), 3):
		var n := 0
		for k in 3:
			if mask[idx[t + k]] != 0:
				n += 1
		if n < 2:
			novo.append(idx[t])
			novo.append(idx[t + 1])
			novo.append(idx[t + 2])
	arr[Mesh.ARRAY_INDEX] = novo
	var mat := am.surface_get_material(0)
	var m2 := ArrayMesh.new()
	m2.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr, [], {}, Mesh.ARRAY_FLAG_USE_8_BONE_WEIGHTS)
	m2.surface_set_material(0, mat)
	mi.mesh = m2


# ---------- Medição e material ----------

## Caixa de todos os meshes de `n` no espaço do pai de `n` (inclui o transform de `n`; chamar antes de adicionar à árvore).
static func medir(n: Node3D) -> AABB:
	var bb := AABB()
	var pr := true
	for mi in n.find_children("*", "MeshInstance3D", true, false):
		var xf := Transform3D()
		var p: Node = mi
		while p != null:
			if p is Node3D:
				xf = (p as Node3D).transform * xf
			p = p.get_parent()
		var a: AABB = xf * (mi as MeshInstance3D).get_aabb()
		bb = a if pr else bb.merge(a)
		pr = false
	return bb


static func _mat(c: Color, metal := 0.0, rug := 0.7) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.metallic = metal
	m.roughness = rug
	return m


static func _pintar(n: Node, m: Material) -> void:
	for mi in n.find_children("*", "MeshInstance3D", true, false):
		(mi as MeshInstance3D).material_override = m


static func _carregar(caminho: String) -> Node3D:
	var ps := load(caminho) as PackedScene
	if ps == null:
		return null
	return ps.instantiate() as Node3D


## Ajustes feitos à mão no editor do treino: chave "estilo/item" -> {pos (cm, no espaço da T-pose), rot (graus), esc (fator)}.
static var ajustes: Dictionary = {}
static var _vivos: Dictionary = {}     ## chave -> {no, rb, bw, pw} do personagem atual (para ajustar ao vivo)
const ARQ_AJUSTES := "user://ajustes_estilos.json"


static func carregar_ajustes() -> void:
	ajustes = {}
	if not FileAccess.file_exists(ARQ_AJUSTES):
		return
	var d = JSON.parse_string(FileAccess.get_file_as_string(ARQ_AJUSTES))
	if d is Dictionary:
		ajustes = d


static func salvar_ajustes() -> void:
	var f := FileAccess.open(ARQ_AJUSTES, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(ajustes))


static func itens_vivos() -> Array:
	var r := []
	for k in _vivos:
		r.append(k)
	return r


## Ajustes definitivos (vindos do editor do treino). Um ajuste local do navegador, se existir, vale por cima.
const AJUSTES_PADRAO := {
	"murmilo/cap": {"esc": 1.02, "pos": [-9.6, -8.2, 11.6], "rot": [-11.0, 0.0, -6.0]},
	"murmilo/esc": {"esc": 1.0, "pos": [0.0, 0.0, 0.0], "rot": [35.0, 9.0, 95.0]},
	"samnita/cap": {"esc": 0.8, "pos": [-2.1, 7.2, -2.1], "rot": [15.0, 1.0, 0.0]},
	"samnita/esc": {"esc": 1.0, "pos": [0.0, 0.0, -1.0], "rot": [41.0, 0.0, 84.0]},
	"tracio/cap": {"esc": 0.88, "pos": [2.0, -3.0, 1.5], "rot": [-8.0, 3.0, 0.0]},
	"tracio/dir": {"esc": 1.0, "pos": [-3.0, 0.0, 0.0], "rot": [0.0, 0.0, 0.0]},
	"tracio/esc": {"esc": 1.0, "pos": [-1.0, -4.5, -3.5], "rot": [36.0, 4.0, 0.0]},
}


static func ajuste_de(chave: String) -> Dictionary:
	var a: Dictionary = ajustes.get(chave, AJUSTES_PADRAO.get(chave, {}))
	return {"pos": a.get("pos", [0.0, 0.0, 0.0]), "rot": a.get("rot", [0.0, 0.0, 0.0]), "esc": float(a.get("esc", 1.0))}


## Giro e tamanho são aplicados em torno da âncora (ponto de pegada da arma / base do capacete), para a peça não "andar" ao redimensionar.
static func _transf_ajustada(chave: String, rb: Basis, bw: Basis, pw: Vector3, ancora: Vector3) -> Transform3D:
	var a := ajuste_de(chave)
	var r: Array = a["rot"]
	var p: Array = a["pos"]
	var q := Basis.from_euler(Vector3(deg_to_rad(float(r[0])), deg_to_rad(float(r[1])), deg_to_rad(float(r[2]))))
	var bw2 := q * bw * Basis.from_scale(Vector3.ONE * float(a["esc"]))
	var m_a := bw.inverse() * (ancora - pw)   # a âncora no espaço do modelo
	var pw2 := ancora + Vector3(float(p[0]), float(p[1]), float(p[2])) * 0.01 * ESC_M - bw2 * m_a
	return Transform3D(rb.inverse() * bw2, rb.inverse() * pw2)


## Reaplica o ajuste de um item já montado (sliders do editor).
static func reaplicar(chave: String) -> void:
	var v: Dictionary = _vivos.get(chave, {})
	if v.is_empty() or not is_instance_valid(v["no"]):
		return
	if v.has("escudo"):
		_aplicar_escudo(chave)
		return
	(v["no"] as Node3D).transform = _transf_ajustada(chave, v["rb"], v["bw"], v["pw"], v["anc"])


static func _anexar(sk: Skeleton3D, osso: String, no: Node3D, basis_osso: Basis, bw: Basis, pw: Vector3, chave := "", ancora := Vector3.ZERO) -> BoneAttachment3D:
	var ba := BoneAttachment3D.new()
	ba.bone_name = osso
	sk.add_child(ba)
	if chave != "":
		_vivos[chave] = {"no": no, "rb": basis_osso, "bw": bw, "pw": pw, "anc": ancora}
		no.transform = _transf_ajustada(chave, basis_osso, bw, pw, ancora)
	else:
		no.transform = Transform3D(basis_osso.inverse() * bw, basis_osso.inverse() * pw)
	ba.add_child(no)
	return ba


static func _rest(sk: Skeleton3D, osso: String) -> Transform3D:
	return sk.get_bone_global_rest(sk.find_bone(osso))


static func _base_osso(sk: Skeleton3D, osso: String) -> Basis:
	return _rest(sk, osso).basis.orthonormalized()


# ---------- Montagem de um estilo ----------

## Monta o estilo em `sk`. Devolve {"escudo": Node3D|null} (o escudo é posicionado pelo EscudoMod).
static func montar(sk: Skeleton3D, id: String, escudo_base: Vector3) -> Dictionary:
	var e: Dictionary = ESTILOS.get(id, {})
	var res := {"escudo": null}
	_vivos.clear()
	if ajustes.is_empty():
		carregar_ajustes()
	var dir_id := str(e.get("dir", ""))
	var esq_id := str(e.get("esq", ""))
	if dir_id != "":
		_arma(sk, dir_id, true, id + "/dir")
	if esq_id != "":
		if ESCUDOS.has(esq_id):
			res["escudo"] = _escudo(esq_id, escudo_base, id + "/esc")
		else:
			_arma(sk, esq_id, false, id + "/esq")
	var cap := str(e.get("cap", ""))
	if cap != "":
		_capacete(sk, cap, id + "/cap")
	for x in e.get("ext", []):
		_extra(sk, str(x))
	return res


static func _arma(sk: Skeleton3D, id: String, direita: bool, chave := "") -> void:
	var a: Dictionary = ARMAS.get(id, {})
	if a.is_empty():
		return
	var no := _carregar(str(a["p"]))
	if no == null:
		return
	var bb := medir(no)
	var eixo: Vector3 = (a["eixo"] as Vector3).normalized()
	if a.get("inv", false):
		eixo = -eixo
	var comp := absf(bb.size.dot(eixo.abs()))
	var k: float = float(a["m"]) * ESC_M / comp
	var alvo: Vector3 = a.get("dir", Vector3(0, 0, 1))   # punho da T-pose fecha em torno de um eixo frente-trás
	if not direita and a.has("dir"):
		alvo = a["dir"]
	var q := _arco(eixo, alvo)
	q = Quaternion(alvo, deg_to_rad(float(a.get("roll", 0.0)))) * q
	var bw := Basis(q) * Basis.from_scale(Vector3.ONE * k)
	var grip_pt := bb.get_center() + eixo * ((float(a.get("grip", 0.15)) - 0.5) * comp)
	if a.get("axis0", false):   # armas longas: o cabo passa pelos vértices perto do ponto de pegada (não pelo centro da caixa)
		var along := bb.get_center().dot(eixo) + (float(a.get("grip", 0.15)) - 0.5) * comp
		grip_pt = eixo * along + _centro_do_cabo(no, eixo, along, comp)
	var g := Vector3(-0.075 if direita else 0.075, -0.03, 0.0) * ESC_M   # centro da palma (a mão da T-pose aponta para o lado)
	var pw := g - bw * grip_pt
	if a.get("tex", false):
		_pintar(no, _mat(Color("b9bcc2") if id == "sica" else Color("4a4d52"), 0.8, 0.35))
	if a.get("pilum", false):
		_pintar(no, _mat(Color("6d6a64"), 0.8, 0.5))
		_so_uma_variante(no)
	var osso := "mixamorig_RightHand" if direita else "mixamorig_LeftHand"
	_anexar(sk, osso, no, _base_osso(sk, osso), bw, pw, chave, g)


## Média (perpendicular ao eixo) dos vértices do modelo próximos de `along` ao longo do eixo: onde fica o cabo de fato.
static func _centro_do_cabo(no: Node3D, eixo: Vector3, along: float, comp: float) -> Vector3:
	var soma := Vector3.ZERO
	var n := 0
	for mi in no.find_children("*", "MeshInstance3D", true, false):
		if not (mi as MeshInstance3D).visible:
			continue
		var xf := Transform3D()
		var p: Node = mi
		while p != null:
			if p is Node3D:
				xf = (p as Node3D).transform * xf
			p = p.get_parent()
		var arr := (mi as MeshInstance3D).mesh.surface_get_arrays(0)
		for v in (arr[Mesh.ARRAY_VERTEX] as PackedVector3Array):
			var w := xf * v
			if absf(w.dot(eixo) - along) < comp * 0.03:
				soma += w - eixo * w.dot(eixo)
				n += 1
	return soma / float(n) if n > 0 else Vector3.ZERO


## O pilum vem com 6 malhas sobrepostas (3 acabamentos × 2 LOD): fica só uma.
static func _so_uma_variante(no: Node) -> void:
	var primeira := true
	for mi in no.find_children("*", "MeshInstance3D", true, false):
		if primeira and str(mi.name).ends_with("LOD0") and not str(mi.name).contains("AGED"):
			primeira = false
			continue
		(mi as MeshInstance3D).visible = false


static func _mat_textura(caminho: String) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_texture = load(caminho)
	m.roughness = 0.6
	return m


static func _escudo(id: String, base: Vector3, chave := "") -> Node3D:
	var s: Dictionary = ESCUDOS[id]
	var no := _carregar(str(s["p"]))
	var pivo := Node3D.new()
	if no == null:
		return pivo
	var bb := medir(no)
	# mesmo tamanho do escudo redondo padrão (diâmetro 2,0) vezes o fator
	var k: float = 2.0 * float(s["f"]) / maxf(bb.size.x, bb.size.y)
	no.transform = Transform3D(Basis(Vector3(0, 0, 1), deg_to_rad(float(s.get("z", 0.0)))) * Basis.from_scale(Vector3.ONE * k), Vector3.ZERO)
	no.position = -(no.basis * bb.get_center()) + Vector3(0, 0, 0)
	pivo.add_child(no)
	if chave != "":
		_vivos[chave] = {"no": pivo, "escudo": true}
		_aplicar_escudo(chave)
	return pivo


## O escudo é posicionado pelo EscudoMod; o ajuste vai no pivô (unidades do escudo: 1 ≈ 24,6 cm).
static func _aplicar_escudo(chave: String) -> void:
	var v: Dictionary = _vivos.get(chave, {})
	if v.is_empty() or not is_instance_valid(v["no"]):
		return
	var a := ajuste_de(chave)
	var r: Array = a["rot"]
	var p: Array = a["pos"]
	var q := Basis.from_euler(Vector3(deg_to_rad(float(r[0])), deg_to_rad(float(r[1])), deg_to_rad(float(r[2]))))
	(v["no"] as Node3D).transform = Transform3D(q * Basis.from_scale(Vector3.ONE * float(a["esc"])), Vector3(float(p[0]), float(p[1]), float(p[2])) / 24.6)


static func _capacete(sk: Skeleton3D, id: String, chave := "") -> void:
	var c: Dictionary = CAPACETES.get(id, {})
	var osso := "mixamorig_Head"
	var rb := _base_osso(sk, osso)
	if c.is_empty():
		var proc := capacete_proc(id.trim_prefix("p_"))
		var bw := Basis.from_scale(Vector3.ONE * ESC_M)
		_anexar(sk, osso, proc, rb, bw, Vector3(0, 0.155, 0.02) * ESC_M, chave, Vector3(0, 0.155, 0.02) * ESC_M)
		return
	var no := _carregar(str(c["p"]))
	if no == null:
		return
	var rot := Basis(Vector3.UP, deg_to_rad(float(c.get("rot", 0.0))))
	var cx := Transform3D(rot, Vector3.ZERO)
	var bb: AABB = cx * medir(no)
	var k: float = float(c["w"]) * ESC_M / bb.size.x
	var bw2 := rot * Basis.from_scale(Vector3.ONE * k)
	var base_pt := Vector3(bb.get_center().x, bb.position.y, bb.get_center().z)
	var alvo := Vector3(0, float(c.get("dy", -0.06)), 0.015 + float(c.get("dz", 0.0))) * ESC_M
	# a origem do osso da cabeça fica na base do crânio: o capacete sobe do queixo até o topo
	var pw := alvo - Basis(Vector3.UP, 0) * (base_pt * k)
	_pintar(no, _mat(Color(str(c["cor"])), float(c["metal"]), 0.4))
	_anexar(sk, osso, no, rb, bw2, pw, chave, alvo)


static func _arco(de: Vector3, para: Vector3) -> Quaternion:
	var d := de.normalized().dot(para.normalized())
	if d > 0.9999:
		return Quaternion.IDENTITY
	if d < -0.9999:
		return Quaternion(Vector3(0, 0, 1) if absf(de.z) < 0.9 else Vector3(1, 0, 0), PI)
	return Quaternion(de.cross(para).normalized(), de.angle_to(para))


# ---------- Peças extras (procedurais) ----------

## Cilindro acompanhando o osso `a` até o osso `b` (trecho de f0 a f1), raio em metros.
static func _tubo(sk: Skeleton3D, a: String, b: String, raio_m: float, f0: float, f1: float, mat: Material, afunila := 1.0) -> void:
	var ra := _rest(sk, a)
	var rb := _rest(sk, b)
	var ini := ra.origin.lerp(rb.origin, f0)
	var fim := ra.origin.lerp(rb.origin, f1)
	var comp := (fim - ini).length()
	var cil := CylinderMesh.new()
	cil.top_radius = raio_m * ESC_M * afunila
	cil.bottom_radius = raio_m * ESC_M
	cil.height = comp
	cil.radial_segments = 14
	var mi := MeshInstance3D.new()
	mi.mesh = cil
	mi.material_override = mat
	var rbo := ra.basis.orthonormalized()
	var eixo_local := rbo.inverse() * ((fim - ini) / comp)
	var ba := BoneAttachment3D.new()
	ba.bone_name = a
	sk.add_child(ba)
	mi.transform = Transform3D(Basis(Quaternion(Vector3.UP, eixo_local)), rbo.inverse() * ((ini + fim) / 2.0 - ra.origin))
	ba.add_child(mi)


static func _extra(sk: Skeleton3D, nome_extra: String) -> void:
	var couro := _mat(Color("5a3a22"), 0.0, 0.85)
	var bronze := _mat(Color("b08a3c"), 0.7, 0.4)
	var ferro := _mat(Color("7d8088"), 0.8, 0.45)
	match nome_extra:
		"manica_dir":
			_tubo(sk, "mixamorig_RightForeArm", "mixamorig_RightHand", 0.058, 0.08, 0.92, ferro)
		"manica_esq":
			_tubo(sk, "mixamorig_LeftForeArm", "mixamorig_LeftHand", 0.058, 0.08, 0.92, ferro)
		"greva_dir":
			_tubo(sk, "mixamorig_RightLeg", "mixamorig_RightFoot", 0.07, 0.1, 0.9, bronze, 0.85)
		"greva_esq":
			_tubo(sk, "mixamorig_LeftLeg", "mixamorig_LeftFoot", 0.07, 0.1, 0.9, bronze, 0.85)
		"peitoral":
			_tubo(sk, "mixamorig_Spine", "mixamorig_Spine2", 0.2, -0.3, 1.5, bronze, 0.9)
		"galerus":
			var ba := BoneAttachment3D.new()
			ba.bone_name = "mixamorig_LeftShoulder"
			sk.add_child(ba)
			var g := galerus_proc()
			g.transform = Transform3D(Basis.from_scale(Vector3.ONE * ESC_M), Vector3(0, 0.05, 0) * ESC_M)
			ba.add_child(g)


# ---------- Peças procedurais (em metros; o chamador escala) ----------

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
	s.height = r * 1.25   # calota um pouco achatada
	s.is_hemisphere = true
	s.radial_segments = 24
	s.rings = 10
	return s


## Capacete procedural: a origem fica na base do crânio; +Y cima, +Z frente.
static func capacete_proc(tipo: String) -> Node3D:
	var raiz := Node3D.new()
	var bronze := _mat(Color("b08a3c"), 0.7, 0.4)
	var ferro := _mat(Color("7d8088"), 0.8, 0.45)
	var pluma := _mat(Color("a32a1f"), 0.0, 0.9)
	if tipo == "tracio":
		raiz.add_child(_mi(_domo(0.16), ferro, Vector3(0, 0.0, 0)))
		raiz.add_child(_mi(_cil(0.21, 0.21, 0.012), ferro, Vector3(0, 0.0, 0)))
		raiz.add_child(_mi(_caixa(Vector3(0.03, 0.17, 0.19)), ferro, Vector3(0, 0.17, 0.0)))
		raiz.add_child(_mi(_domo(0.045), bronze, Vector3(0, 0.22, 0.1), Vector3(90, 0, 0)))
		raiz.add_child(_mi(_caixa(Vector3(0.015, 0.14, 0.09)), ferro, Vector3(0.15, -0.02, 0.03)))
		raiz.add_child(_mi(_caixa(Vector3(0.015, 0.14, 0.09)), ferro, Vector3(-0.15, -0.02, 0.03)))
	elif tipo == "aberto":
		raiz.add_child(_mi(_domo(0.165), ferro, Vector3(0, 0.0, 0)))
		raiz.add_child(_mi(_caixa(Vector3(0.016, 0.1, 0.09)), ferro, Vector3(0.16, 0.0, 0.02)))
		raiz.add_child(_mi(_caixa(Vector3(0.016, 0.1, 0.09)), ferro, Vector3(-0.16, 0.0, 0.02)))
		raiz.add_child(_mi(_caixa(Vector3(0.03, 0.06, 0.2)), pluma, Vector3(0, 0.14, -0.02)))
	return raiz


## Galerus: ombreira alta do retiário.
static func galerus_proc() -> Node3D:
	var raiz := Node3D.new()
	var bronze := _mat(Color("b08a3c"), 0.7, 0.4)
	raiz.add_child(_mi(_domo(0.15), bronze, Vector3.ZERO))
	raiz.add_child(_mi(_caixa(Vector3(0.012, 0.2, 0.2)), bronze, Vector3(0.0, 0.1, -0.03), Vector3(0, 0, -12)))
	return raiz
