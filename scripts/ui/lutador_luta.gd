class_name LutadorLuta
extends Node2D
## Gladiador da cena de luta: um sprite que troca de pose conforme a ação (porte de CorpoSprite.ts), com
## deslocamentos por tween (avanço no golpe, recuo no dano, queda na morte). Coordenadas do palco de 1280x720.

const ALTURA_BASE := 181.0      ## altura do gladiador em guarda, em pixels do palco, na escala 1
const E := 4.0 / 3.0            ## fator entre os valores do original (palco 960x540) e este palco (1280x720)
const IMPACTO := {"corte": 340, "estocada": 250, "pesado": 420, "soco": 210}
const ARMA_CORTE := ["gladio", "gladio_largo", "espada_curta", "sica", "machadinha"]
const ARMA_ESTOCADA := ["adaga", "tridente"]
const ARMA_PESADA := ["maca"]

var id := ""
var classe := "murmilo"
var frente := 1
var base := Vector2.ZERO
var mov := 1.0
var vel := 1.0                  ## velocidade de reprodução (1x/2x), lida ao criar cada tween
var parado := false
var tamanho := 1.0              ## escala relativa (2 por lado = menor)
var _k := 1.0
var _sprite: Sprite2D
var _ocupado := false
var _ficha := 0
var _tempo := 0.0
var _fase := 0
var _tw_pos: Tween
var _pose_atual := ""

func _init(id_: String, classe_: String, escala: float, virado: bool, mov_: float, pos: Vector2) -> void:
	id = id_
	classe = classe_ if AncorasPoses.DADOS.has(classe_) else "murmilo"
	frente = -1 if virado else 1
	mov = mov_
	tamanho = escala
	base = pos
	position = pos
	_k = ALTURA_BASE * escala / AncorasPoses.altura_guarda(classe)
	scale = Vector2(frente * _k, _k)
	_sprite = Sprite2D.new()
	_sprite.centered = false
	_sprite.material = Sprites.material_variante(id)
	add_child(_sprite)
	_tempo = randf() * 2.0
	pose("guarda")

func _draw() -> void:
	# sombra no chão (em coordenadas locais, antes da escala do corpo)
	var pts := PackedVector2Array()
	for i in range(24):
		var a := TAU * i / 24.0
		pts.append(Vector2(cos(a) * 70.0, sin(a) * 11.0))
	draw_colored_polygon(pts, Color(0, 0, 0, 0.32))

func pose(nome: String) -> void:
	var usar := AncorasPoses.resolver(classe, nome)
	if usar == _pose_atual:
		return
	_pose_atual = usar
	_sprite.texture = Sprites.pose(classe, usar)
	_sprite.position = -AncorasPoses.ancora(classe, usar)

func _process(delta: float) -> void:
	_tempo += delta * vel
	if _ocupado or parado:
		return
	var f := int(_tempo * 1000.0 / 520.0) % 2
	if f != _fase:
		_fase = f
		pose("respira" if f == 1 else "guarda")

## Altura aproximada da cabeça em pixels do palco (para posicionar números flutuantes).
func topo() -> float:
	return base.y - ALTURA_BASE * tamanho * 1.05

func tipo_do_golpe(arma) -> String:
	if arma == null or str(arma) == "":
		return "soco"
	var a: String = str(arma).split("@")[0]
	if a.begins_with("basico_arma_"):
		return "estocada" if a.ends_with("retiario") else "corte"
	if a in ARMA_ESTOCADA:
		return "estocada"
	if a in ARMA_PESADA:
		return "pesado"
	return "corte"

func _acao(atraso_ms: float, passos: Array) -> void:
	if parado:
		return
	_ficha += 1
	var minha := _ficha
	_ocupado = true
	var tw := create_tween()
	tw.set_speed_scale(vel)
	tw.tween_interval(maxf(0.001, atraso_ms / 1000.0))
	for p in passos:
		var nome: String = p[1]
		var extra: Callable = p[2] if p.size() > 2 else Callable()
		tw.tween_callback(func() -> void:
			if _ficha == minha:
				pose(nome)
				if extra.is_valid():
					extra.call())
		tw.tween_interval(float(p[0]) / 1000.0)
	tw.tween_callback(func() -> void:
		if _ficha == minha:
			_ocupado = false
			pose("guarda"))

## Valores absolutos a partir do repouso (nunca relativos), para golpes sobrepostos não acumularem deslocamento.
func _deslocar(dx: float, dy: float, dur_ms: float, volta: bool = true) -> void:
	if _tw_pos:
		_tw_pos.kill()
	position = base
	_tw_pos = create_tween()
	_tw_pos.set_speed_scale(vel)
	_tw_pos.tween_property(self, "position", base + Vector2(dx * frente * mov * E, dy * mov * E), dur_ms / 1000.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	if volta:
		_tw_pos.tween_property(self, "position", base, dur_ms / 1000.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)

## Devolve o instante (ms) do contato com o alvo.
func golpear(tipo: String) -> float:
	var imp: float = float(IMPACTO[tipo])
	if parado:
		return imp
	var alt: bool = AncorasPoses.DADOS[classe]["ancoras"].has("alt") and randf() < 0.35
	_acao(0, [[imp - 90.0, "prepara"], [170.0, "alt" if alt else "impacto"], [240.0, "recupera"]])
	get_tree().create_timer(maxf(0.0, imp - 190.0) / 1000.0 / vel).timeout.connect(func() -> void:
		if is_instance_valid(self) and not parado:
			_deslocar(54.0, 0.0, 190.0))
	return imp

func esquivar(atraso_ms: float) -> void:
	_acao(atraso_ms, [[360.0, "esquiva", func() -> void: _deslocar(-42.0, -16.0, 180.0)]])

func defender(empurrao: bool) -> void:
	_acao(0, [[420.0 if empurrao else 340.0, "empurrao" if empurrao else "defende",
		(func() -> void: _deslocar(-18.0, 0.0, 200.0)) if empurrao else Callable()]])

func reagir(critico: bool) -> void:
	_acao(0, [[520.0 if critico else 380.0, "critico" if critico else "dano",
		func() -> void: _deslocar(-30.0 if critico else -14.0, 0.0, 180.0)]])

func cair() -> void:
	_ficha += 1
	var minha := _ficha
	_ocupado = true
	parado = true
	pose("cai")
	var tw := create_tween()
	tw.set_speed_scale(vel)
	tw.tween_interval(0.42)
	tw.tween_callback(func() -> void:
		if _ficha == minha:
			pose("morto"))

## Rendição: parado e agachado, meio apagado.
func recolher() -> void:
	_ficha += 1
	_ocupado = true
	parado = true
	pose("critico")
	create_tween().tween_property(self, "modulate:a", 0.5, 0.4)

func comemorar() -> void:
	if parado:
		return
	_ficha += 1
	_ocupado = true
	pose("guarda")
	var tw := create_tween().set_loops(3)
	tw.tween_property(self, "position:y", base.y - 26.0, 0.18).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "position:y", base.y, 0.18).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tw.tween_interval(0.25)

func tingir(cor: Color) -> void:
	var tw := create_tween()
	tw.tween_property(self, "self_modulate", cor, 0.12)
	tw.tween_property(self, "self_modulate", Color.WHITE, 0.5)
