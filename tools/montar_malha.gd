extends SceneTree
## Lê /tmp/gi/novo.bin (malha limpa + UV + pesos) e salva res://assets/3d/glad/malha.res
func _init() -> void:
	var f := FileAccess.open("/tmp/gi/novo.bin", FileAccess.READ)
	var n := f.get_32()
	var ni := f.get_32()
	var v := PackedVector3Array(); v.resize(n)
	var nr := PackedVector3Array(); nr.resize(n)
	var uv := PackedVector2Array(); uv.resize(n)
	var ix := PackedInt32Array(); ix.resize(ni)
	var b := PackedInt32Array(); b.resize(n * 8)
	var w := PackedFloat32Array(); w.resize(n * 8)
	v = _v3(f.get_buffer(n * 12))
	nr = _v3(f.get_buffer(n * 12))
	var ub := f.get_buffer(n * 8).to_float32_array()
	for i in n:
		uv[i] = Vector2(ub[i * 2], ub[i * 2 + 1])
	var ib := f.get_buffer(ni * 4).to_int32_array()
	for i in ni:
		ix[i] = ib[i]
	b = f.get_buffer(n * 32).to_int32_array()
	w = f.get_buffer(n * 32).to_float32_array()
	var arr := []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = v
	arr[Mesh.ARRAY_NORMAL] = nr
	arr[Mesh.ARRAY_TEX_UV] = uv
	arr[Mesh.ARRAY_INDEX] = ix
	arr[Mesh.ARRAY_BONES] = b
	arr[Mesh.ARRAY_WEIGHTS] = w
	var m := ArrayMesh.new()
	m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr, [], {}, Mesh.ARRAY_FLAG_USE_8_BONE_WEIGHTS)
	print("SALVO ", ResourceSaver.save(m, "res://assets/3d/glad/malha.res"), " v ", n, " tri ", ni / 3)
	quit()

func _v3(buf: PackedByteArray) -> PackedVector3Array:
	var fl := buf.to_float32_array()
	var out := PackedVector3Array()
	out.resize(fl.size() / 3)
	for i in out.size():
		out[i] = Vector3(fl[i * 3], fl[i * 3 + 1], fl[i * 3 + 2])
	return out
