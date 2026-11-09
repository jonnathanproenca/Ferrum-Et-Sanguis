extends SceneTree
## Gera res://assets/3d/glad/gladiador.scn (esqueleto + malha limpa, sem a malha/textura embutidas do FBX).
func _init() -> void:
	var inst: Node3D = (load("res://assets/3d/glad/gladiador.fbx") as PackedScene).instantiate()
	for mi in inst.find_children("*", "MeshInstance3D", true, false):
		(mi as MeshInstance3D).mesh = load("res://assets/3d/glad/malha.res")
		(mi as MeshInstance3D).material_override = null
	for n in inst.find_children("*", "", true, false):
		n.owner = inst
	var ps := PackedScene.new()
	print("PACK ", ps.pack(inst))
	print("SALVO ", ResourceSaver.save(ps, "res://assets/3d/glad/gladiador.scn"))
	quit()
