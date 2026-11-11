extends SceneTree
## Marca os vértices de cabelo do gladiador 2 (ligados à cabeça, acima da linha das sobrancelhas, cor escura na textura)
## e salva a máscara em assets/3d/glad2/cabelo_mask.res (Image L8, 1 byte por vértice). Rodar: godot --headless -s tools/gerar_mascara_cabelo.gd
func _init() -> void:
	var n: Node3D = (load("res://assets/3d/glad2/gladiador2_mixamo.fbx") as PackedScene).instantiate()
	var sk := n.find_children("*", "Skeleton3D", true, false)[0] as Skeleton3D
	var mi := n.find_children("*", "MeshInstance3D", true, false)[0] as MeshInstance3D
	var arr := mi.mesh.surface_get_arrays(0)
	var vs: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var uvs: PackedVector2Array = arr[Mesh.ARRAY_TEX_UV]
	var bones: PackedInt32Array = arr[Mesh.ARRAY_BONES]
	var ws: PackedFloat32Array = arr[Mesh.ARRAY_WEIGHTS]
	var per := bones.size() / vs.size()
	var img: Image = ((mi.mesh.surface_get_material(0) as StandardMaterial3D).albedo_texture as Texture2D).get_image()
	if img.is_compressed():
		img.decompress()
	var ho := sk.get_bone_global_rest(sk.find_bone("mixamorig_Head")).origin
	var corte_y: float = ho.y + float(OS.get_environment("CORTE") if OS.get_environment("CORTE") != "" else "0.0012")
	var luma_max: float = float(OS.get_environment("LUMA") if OS.get_environment("LUMA") != "" else "0.30")
	var mask := PackedByteArray()
	mask.resize(vs.size())
	var cont := 0
	for i in vs.size():
		var wh := 0.0
		for j in per:
			var nm := mi.skin.get_bind_name(bones[i * per + j])
			if nm == "mixamorig_Head" or nm == "mixamorig_HeadTop_End":
				wh += ws[i * per + j]
		if wh < 0.5 or vs[i].y < corte_y:
			continue
		var px := img.get_pixel(clampi(int(uvs[i].x * img.get_width()), 0, img.get_width() - 1), clampi(int(uvs[i].y * img.get_height()), 0, img.get_height() - 1))
		if px.get_luminance() < luma_max:
			mask[i] = 255
			cont += 1
	print("CABELO vertices marcados: ", cont, " de ", vs.size(), " (corte y ", corte_y, ")")
	var out := Image.create_from_data(vs.size(), 1, false, Image.FORMAT_L8, mask)
	ResourceSaver.save(out, "res://assets/3d/glad2/cabelo_mask.res")
	quit()
