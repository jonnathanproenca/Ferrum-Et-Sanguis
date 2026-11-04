shader_type canvas_item;
// Variante de cor do gladiador: gira o matiz do tecido e escurece/clareia a pele (igual ao jogo em TypeScript).
uniform float rot = 0.0;
uniform float pele = 1.0;

vec3 rgb2hsv(vec3 c) {
	float mx = max(c.r, max(c.g, c.b));
	float mn = min(c.r, min(c.g, c.b));
	float d = mx - mn;
	float h = 0.0;
	if (d > 0.0) {
		if (mx == c.r) h = mod((c.g - c.b) / d, 6.0);
		else if (mx == c.g) h = (c.b - c.r) / d + 2.0;
		else h = (c.r - c.g) / d + 4.0;
		h *= 60.0;
		if (h < 0.0) h += 360.0;
	}
	return vec3(h, mx == 0.0 ? 0.0 : d / mx, mx);
}

vec3 hsv2rgb(vec3 hsv) {
	float h = hsv.x; float s = hsv.y; float v = hsv.z;
	float c = v * s;
	float x = c * (1.0 - abs(mod(h / 60.0, 2.0) - 1.0));
	float m = v - c;
	vec3 r;
	if (h < 60.0) r = vec3(c, x, 0.0);
	else if (h < 120.0) r = vec3(x, c, 0.0);
	else if (h < 180.0) r = vec3(0.0, c, x);
	else if (h < 240.0) r = vec3(0.0, x, c);
	else if (h < 300.0) r = vec3(x, 0.0, c);
	else r = vec3(c, 0.0, x);
	return r + vec3(m);
}

void fragment() {
	vec4 t = texture(TEXTURE, UV);
	if (t.a > 0.03 && (rot != 0.0 || pele != 1.0)) {
		vec3 hsv = rgb2hsv(t.rgb);
		float h = hsv.x; float s = hsv.y; float v = hsv.z;
		bool tecido = (s > 0.35 && (h < 14.0 || h > 340.0)) || (s > 0.3 && h >= 190.0 && h <= 340.0) || (s > 0.35 && h >= 14.0 && h <= 40.0 && v < 0.5);
		bool ispele = !tecido && s >= 0.2 && s <= 0.7 && h >= 8.0 && h <= 36.0 && v >= 0.5;
		if (tecido) { hsv.x = mod(h + rot, 360.0); t.rgb = hsv2rgb(hsv); }
		else if (ispele) { hsv.z = min(1.0, v * pele); t.rgb = hsv2rgb(hsv); }
	}
	COLOR = t;
}
