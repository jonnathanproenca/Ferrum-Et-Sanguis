class_name Util
extends RefCounted
## Utilidades. O JSON do Godot lê todo número como float; `normalizar` devolve inteiros onde o valor é inteiro.

static func normalizar(v: Variant) -> Variant:
	if v is float:
		if v == floor(v) and absf(v) < 9.0e15:
			return int(v)
		return v
	if v is Array:
		var r: Array = []
		for x in v:
			r.append(normalizar(x))
		return r
	if v is Dictionary:
		var d := {}
		for k in v:
			d[k] = normalizar(v[k])
		return d
	return v

static func ler_json(caminho: String) -> Variant:
	var f := FileAccess.open(caminho, FileAccess.READ)
	if f == null:
		push_error("Arquivo não encontrado: " + caminho)
		return null
	var r = JSON.parse_string(f.get_as_text())
	return normalizar(r)

static func canon(v: Variant) -> String:
	return JSON.stringify(normalizar(v), "", true)
