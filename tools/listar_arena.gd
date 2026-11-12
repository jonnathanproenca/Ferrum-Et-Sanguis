extends SceneTree

func _init() -> void:
	var ps := load("res://assets/3d/arena/source/colosseum.fbx") as PackedScene
	var no := ps.instantiate() as Node3D
	root.add_child(no)
	for mi in no.find_children("*", "MeshInstance3D", true, false):
		var m := mi as MeshInstance3D
		var aabb := m.get_aabb()
		var mat := m.get_active_material(0)
		var tex := ""
		if mat is StandardMaterial3D and (mat as StandardMaterial3D).albedo_texture != null:
			tex = (mat as StandardMaterial3D).albedo_texture.resource_path
		print("%s | %s | size %s | mat %s | tex %s" % [str(no.get_path_to(m)), m.name, str(aabb.size.snapped(Vector3.ONE * 0.1)), mat.resource_name if mat else "-", tex.get_file()])
	quit()
