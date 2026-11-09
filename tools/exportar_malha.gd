extends SceneTree
func _init() -> void:
	var inst: Node = (load("res://assets/3d/glad/gladiador.fbx") as PackedScene).instantiate()
	var mi: MeshInstance3D = inst.find_children("*", "MeshInstance3D", true, false)[0]
	var arr: Array = mi.mesh.surface_get_arrays(0)
	var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var f := FileAccess.open("/tmp/gi/old.bin", FileAccess.WRITE)
	f.store_32(v.size())
	f.store_buffer(v.to_byte_array())
	f.store_buffer((arr[Mesh.ARRAY_BONES] as PackedInt32Array).to_byte_array())
	f.store_buffer((arr[Mesh.ARRAY_WEIGHTS] as PackedFloat32Array).to_byte_array())
	f.close()
	print("OK ", v.size(), " skin binds ", mi.skin.get_bind_count() if mi.skin else -1)
	quit()
