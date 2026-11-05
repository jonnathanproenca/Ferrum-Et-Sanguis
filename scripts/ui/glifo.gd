class_name Glifo
extends Control
## Ícones desenhados em código (a fonte não tem estes símbolos): "ok", "falha", "caveira", "espadas", "mais", "seta_esq", "coroa" e um por atributo
## "peso" e "coroa_fama"; ("forca" espada, "destreza" alvo, "vitalidade" coração, "resistencia" raio, "inteligencia" olho, "aura" estrela).

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

		"mais":
			var h1 := o + Vector2(s * 0.2, s * 0.5)
			var h2 := o + Vector2(s * 0.8, s * 0.5)
			var w1 := o + Vector2(s * 0.5, s * 0.2)
			var w2 := o + Vector2(s * 0.5, s * 0.8)
			draw_line(h1, h2, sombra, lw + 2.0, true)
			draw_line(w1, w2, sombra, lw + 2.0, true)
			draw_line(h1, h2, cor, lw, true)
			draw_line(w1, w2, cor, lw, true)
		"seta_esq":
			_poli([o + Vector2(s * 0.7, s * 0.2), o + Vector2(s * 0.7, s * 0.8), o + Vector2(s * 0.25, s * 0.5)], cor, sombra)
		"coroa":
			_poli([o + Vector2(s * 0.1, s * 0.8), o + Vector2(s * 0.1, s * 0.32), o + Vector2(s * 0.32, s * 0.52), o + Vector2(s * 0.5, s * 0.18),
				o + Vector2(s * 0.68, s * 0.52), o + Vector2(s * 0.9, s * 0.32), o + Vector2(s * 0.9, s * 0.8)], cor, sombra)
			draw_rect(Rect2(o + Vector2(s * 0.1, s * 0.84), Vector2(s * 0.8, s * 0.08)), cor.darkened(0.25))
		"forca":
			var p1 := o + Vector2(s * 0.78, s * 0.12)
			var p2 := o + Vector2(s * 0.3, s * 0.7)
			draw_line(p1, p2, sombra, lw + 2.0, true)
			draw_line(p1, p2, cor, lw * 0.8, true)
			var dir := (p2 - p1).normalized()
			var cg := p2 - dir * s * 0.02
			var perp := dir.orthogonal() * s * 0.22
			draw_line(cg - perp, cg + perp, cor.darkened(0.2), lw * 0.8, true)
			draw_line(cg, cg + dir * s * 0.2, cor.darkened(0.35), lw * 0.9, true)
		"destreza":
			var c2 := o + Vector2(s * 0.5, s * 0.5)
			draw_arc(c2, s * 0.4, 0, TAU, 28, sombra, lw * 0.6 + 2.0, true)
			draw_arc(c2, s * 0.4, 0, TAU, 28, cor, lw * 0.6, true)
			draw_arc(c2, s * 0.22, 0, TAU, 24, cor, lw * 0.5, true)
			draw_circle(c2, s * 0.08, cor)
		"vitalidade":
			var pts_c: Array = []
			for k in range(33):
				var a := TAU * float(k) / 32.0
				var cx := 16.0 * pow(sin(a), 3)
				var cy := -(13.0 * cos(a) - 5.0 * cos(2.0 * a) - 2.0 * cos(3.0 * a) - cos(4.0 * a))
				pts_c.append(o + Vector2(s * (0.5 + cx / 36.0), s * (0.46 + cy / 36.0)))
			_poli(pts_c, cor, sombra)
		"resistencia":
			_poli([o + Vector2(s * 0.62, s * 0.05), o + Vector2(s * 0.24, s * 0.56), o + Vector2(s * 0.46, s * 0.56), o + Vector2(s * 0.36, s * 0.95),
				o + Vector2(s * 0.78, s * 0.4), o + Vector2(s * 0.55, s * 0.4)], cor, sombra)
		"inteligencia":
			var topo: Array = []
			var baixo: Array = []
			for k in range(13):
				var t := float(k) / 12.0
				var x := 0.06 + 0.88 * t
				var dy := 0.3 * sin(PI * t)
				topo.append(o + Vector2(s * x, s * (0.5 - dy)))
				baixo.append(o + Vector2(s * x, s * (0.5 + dy)))
			baixo.reverse()
			var contorno := PackedVector2Array(topo + baixo)
			contorno.append(contorno[0])
			draw_polyline(contorno, sombra, lw * 0.7 + 2.0, true)
			draw_polyline(contorno, cor, lw * 0.7, true)
			draw_circle(o + Vector2(s * 0.5, s * 0.5), s * 0.17, cor)
			draw_circle(o + Vector2(s * 0.5, s * 0.5), s * 0.07, Color(0.1, 0.05, 0.04))
		"aura":
			var est: Array = []
			for k in range(10):
				var a := -PI / 2.0 + PI * float(k) / 5.0
				var r := s * (0.46 if k % 2 == 0 else 0.2)
				est.append(o + Vector2(s * 0.5, s * 0.54) + Vector2(cos(a), sin(a)) * r)
			_poli(est, cor, sombra)
		"peso":
			# pesa: trapézio com alça em anel
			var al := PackedVector2Array()
			for k in range(13):
				var a := PI + PI * float(k) / 12.0
				al.append(o + Vector2(s * 0.5, s * 0.3) + Vector2(cos(a), sin(a)) * s * 0.17)
			draw_polyline(al, sombra, lw * 0.7 + 2.0, true)
			draw_polyline(al, cor, lw * 0.7, true)
			_poli([o + Vector2(s * 0.32, s * 0.3), o + Vector2(s * 0.68, s * 0.3), o + Vector2(s * 0.92, s * 0.9), o + Vector2(s * 0.08, s * 0.9)], cor, sombra)
		"coroa_fama":
			# coroa de louros: dois ramos de folhas em arco e uma estrela no topo
			for lado in [-1.0, 1.0]:
				for k in range(5):
					var t := float(k) / 4.0
					var pos := o + Vector2(s * (0.5 + lado * (0.34 - 0.16 * t)), s * (0.82 - 0.5 * t))
					var fo := PackedVector2Array([pos + Vector2(0, -s * 0.12), pos + Vector2(lado * s * 0.12, 0), pos + Vector2(0, s * 0.12), pos + Vector2(-lado * s * 0.04, 0)])
					draw_colored_polygon(fo, cor)
					if s > 40.0:
						draw_polyline(PackedVector2Array([fo[0], fo[1], fo[2], fo[3], fo[0]]), sombra, 1.0, true)
			var est2: Array = []
			for k in range(10):
				var a2 := -PI / 2.0 + PI * float(k) / 5.0
				var r2 := s * (0.2 if k % 2 == 0 else 0.09)
				est2.append(o + Vector2(s * 0.5, s * 0.3) + Vector2(cos(a2), sin(a2)) * r2)
			_poli(est2, cor, sombra)
		"cadeado":
			var ar := PackedVector2Array()
			for k in range(13):
				var a := PI + PI * float(k) / 12.0
				ar.append(o + Vector2(s * 0.5, s * 0.4) + Vector2(cos(a), sin(a)) * s * 0.22)
			draw_polyline(ar, sombra, lw * 0.8 + 2.0, true)
			draw_polyline(ar, cor, lw * 0.8, true)
			draw_rect(Rect2(o + Vector2(s * 0.2, s * 0.42), Vector2(s * 0.6, s * 0.46)), cor)
			draw_rect(Rect2(o + Vector2(s * 0.2, s * 0.42), Vector2(s * 0.6, s * 0.46)), sombra, false, 1.0)

func _poli(pts: Array, cor_: Color, sombra: Color) -> void:
	var a := PackedVector2Array(pts)
	var b := PackedVector2Array()
	for p in a:
		b.append(p + Vector2(0, 1.2))
	draw_colored_polygon(b, sombra)
	draw_colored_polygon(a, cor_)
