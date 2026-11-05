class_name Glifo
extends Control
## Ícones desenhados em código (a fonte não tem estes símbolos): "ok", "falha", "caveira", "espadas".

var tipo := "ok"
var cor := Color("7fbf5a")

static func novo(tipo_: String, tam: float = 20.0, cor_: Color = Color.WHITE) -> Glifo:
	var g := Glifo.new()
	g.tipo = tipo_
	g.cor = cor_
	g.custom_minimum_size = Vector2(tam, tam)
	g.mouse_filter = Control.MOUSE_FILTER_IGNORE
	g.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return g

func _draw() -> void:
	var s := minf(size.x, size.y)
	if s <= 0.0:
		return
	var o := (size - Vector2(s, s)) / 2.0
	var sombra := Color(0, 0, 0, 0.65)
	var lw := maxf(2.0, s * 0.16)
	match tipo:
		"ok":
			var pts := PackedVector2Array([o + Vector2(s * 0.18, s * 0.54), o + Vector2(s * 0.42, s * 0.76), o + Vector2(s * 0.84, s * 0.26)])
			draw_polyline(pts, sombra, lw + 2.0, true)
			draw_polyline(pts, cor, lw, true)
		"falha":
			var a1 := o + Vector2(s * 0.22, s * 0.22)
			var a2 := o + Vector2(s * 0.78, s * 0.78)
			var b1 := o + Vector2(s * 0.78, s * 0.22)
			var b2 := o + Vector2(s * 0.22, s * 0.78)
			draw_line(a1, a2, sombra, lw + 2.0, true)
			draw_line(b1, b2, sombra, lw + 2.0, true)
			draw_line(a1, a2, cor, lw, true)
			draw_line(b1, b2, cor, lw, true)
		"caveira":
			var c := o + Vector2(s * 0.5, s * 0.44)
			draw_circle(c, s * 0.38, sombra)
			draw_circle(c, s * 0.34, cor)
			draw_rect(Rect2(o + Vector2(s * 0.30, s * 0.66), Vector2(s * 0.40, s * 0.26)), cor)
			var osso := Color(0.1, 0.05, 0.04)
			draw_circle(o + Vector2(s * 0.36, s * 0.46), s * 0.1, osso)
			draw_circle(o + Vector2(s * 0.64, s * 0.46), s * 0.1, osso)
			draw_colored_polygon(PackedVector2Array([o + Vector2(s * 0.5, s * 0.56), o + Vector2(s * 0.45, s * 0.66), o + Vector2(s * 0.55, s * 0.66)]), osso)
			for k in range(3):
				draw_line(o + Vector2(s * (0.38 + 0.12 * k), s * 0.72), o + Vector2(s * (0.38 + 0.12 * k), s * 0.9), osso, maxf(1.0, s * 0.05))
		"espadas":
			for d in [1.0, -1.0]:
				var p1 := o + Vector2(s * (0.5 - 0.34 * d), s * 0.12)
				var p2 := o + Vector2(s * (0.5 + 0.28 * d), s * 0.8)
				draw_line(p1, p2, sombra, lw + 2.0, true)
				draw_line(p1, p2, cor, lw * 0.75, true)
				var cg := (p1 + p2) / 2.0 + (p2 - p1).normalized() * s * 0.22
				var perp := (p2 - p1).normalized().orthogonal() * s * 0.16
				draw_line(cg - perp, cg + perp, cor.darkened(0.2), lw * 0.7, true)
