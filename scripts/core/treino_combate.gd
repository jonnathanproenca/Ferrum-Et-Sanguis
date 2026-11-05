class_name TreinoCombate
extends RefCounted
## Lógica do treino de combate (mini-arena contra o boneco): sem vida e sem estamina, só os comandos.
## Andar, esquiva para trás, defesa (segurar) com parry na janela certa, ataque leve e pesado (segurar o botão).
## A cena (tela_treino_combate.gd) só lê o estado e as poses; tudo que decide acerto/parry/esquiva está aqui.

const VEL := 260.0
const VEL_DEFESA := 0.4          ## fração da velocidade andando com a guarda erguida
const X_MIN := 150.0
const X_BONECO := 1000.0
const DIST_MIN := 210.0
const ALCANCE_JOGADOR := 380.0
const ALCANCE_BONECO := 380.0

const LEVE := {"prep": 0.12, "golpe": 0.08, "rec": 0.28}
const PESADO := {"prep": 0.30, "golpe": 0.10, "rec": 0.55}
const CARGA_PESADO := 0.40       ## segurar o ataque por esse tempo vira golpe pesado
const ESQUIVA_DUR := 0.35
const ESQUIVA_INVUL := [0.05, 0.28]
const ESQUIVA_DIST := 170.0
const ESQUIVA_CD := 0.2
const PARRY_JANELA := 0.25
const DEFESA_CD := 0.45          ## depois de baixar a guarda, espera para erguer de novo (evita spam de parry)
const DANO_DUR := 0.4

const BONECO_PREPARA := 0.7      ## telegrafia do golpe do boneco
const BONECO_GOLPE := 0.25
const BONECO_REC := 0.5
const BONECO_ATORDOA := 1.3
const BONECO_QUEBRA := 0.8
const BONECO_REACAO := 0.3

var x := 660.0
var estado := "livre"            ## livre, leve, pesado, esquiva, dano
var fase := ""                   ## prep, golpe, rec (ataques)
var t := 0.0
var direcao := 0                 ## -1, 0, 1
var defendendo := false
var t_defesa := 99.0             ## tempo desde que ergueu a guarda
var cd_defesa := 0.0
var cd_esquiva := 0.0
var carga := 0.0
var carregando := false
var _impacto_feito := false
var _x_esquiva0 := 0.0

var b_estado := "espera"         ## espera, prepara, golpe, recupera, atordoado, reage
var b_t := 0.0
var b_prox := 3.0
var _b_resolvido := false

var rng := RandomNumberGenerator.new()
var eventos: Array = []          ## {"tipo": "feedback"|"p_pose"|"b_pose", ...}; a cena esvazia com pegar_eventos()
var placar := {"parries": 0, "esquivas": 0, "bloqueios": 0, "levados": 0, "leves": 0, "pesados": 0, "criticos": 0}


func _init(semente: int = 1) -> void:
	rng.seed = semente
	b_prox = rng.randf_range(2.0, 3.0)


func pegar_eventos() -> Array:
	var r := eventos
	eventos = []
	return r


func _fb(texto: String, cor := "branco") -> void:
	eventos.append({"tipo": "feedback", "texto": texto, "cor": cor})


func _pose_p(nome: String) -> void:
	eventos.append({"tipo": "p_pose", "pose": nome})


func _pose_b(nome: String, tinta := "") -> void:
	eventos.append({"tipo": "b_pose", "pose": nome, "tinta": tinta})


func ocupado() -> bool:
	return estado != "livre"


# ---------- Entradas ----------

func definir_direcao(d: int) -> void:
	direcao = clampi(d, -1, 1)


func defesa(pressionado: bool) -> void:
	if pressionado:
		if defendendo or cd_defesa > 0.0 or estado != "livre":
			return
		defendendo = true
		t_defesa = 0.0
		_pose_p("defende")
	elif defendendo:
		defendendo = false
		cd_defesa = DEFESA_CD
		if estado == "livre":
			_pose_p("guarda")


func esquiva() -> void:
	if estado == "esquiva" or cd_esquiva > 0.0 or estado == "dano":
		return
	if defendendo:
		defendendo = false
		cd_defesa = DEFESA_CD
	carregando = false
	carga = 0.0
	estado = "esquiva"
	fase = ""
	t = 0.0
	_x_esquiva0 = x
	_pose_p("esquiva")


## Botão de ataque apertado (mouse): começa a carregar; ao soltar decide leve ou pesado.
func atacar_pressionar() -> void:
	if estado != "livre" or defendendo:
		return
	carregando = true
	carga = 0.0


func atacar_soltar() -> void:
	if not carregando:
		return
	carregando = false
	if carga >= CARGA_PESADO:
		_iniciar_ataque("pesado")
	else:
		_iniciar_ataque("leve")
	carga = 0.0


## Botões separados (toque).
func ataque_leve() -> void:
	if estado == "livre" and not defendendo:
		carregando = false
		_iniciar_ataque("leve")


func ataque_pesado() -> void:
	if estado == "livre" and not defendendo:
		carregando = false
		_iniciar_ataque("pesado")


func _iniciar_ataque(tipo: String) -> void:
	estado = tipo
	fase = "prep"
	t = 0.0
	_impacto_feito = false
	_pose_p("prepara")


# ---------- Simulação ----------

func atualizar(dt: float) -> void:
	cd_esquiva = maxf(0.0, cd_esquiva - dt)
	if not defendendo:
		cd_defesa = maxf(0.0, cd_defesa - dt)
	else:
		t_defesa += dt
	if carregando:
		carga += dt
	_atualizar_jogador(dt)
	_atualizar_boneco(dt)


func _limite_direito() -> float:
	return X_BONECO - DIST_MIN


func _atualizar_jogador(dt: float) -> void:
	t += dt
	match estado:
		"livre":
			if direcao != 0:
				var v := VEL * (VEL_DEFESA if defendendo else 1.0)
				x = clampf(x + float(direcao) * v * dt, X_MIN, _limite_direito())
		"esquiva":
			var k := clampf(t / ESQUIVA_DUR, 0.0, 1.0)
			var e := 1.0 - (1.0 - k) * (1.0 - k)
			x = maxf(X_MIN, _x_esquiva0 - ESQUIVA_DIST * e)
			if t >= ESQUIVA_DUR:
				estado = "livre"
				cd_esquiva = ESQUIVA_CD
				_pose_p("guarda")
		"leve", "pesado":
			var d: Dictionary = LEVE if estado == "leve" else PESADO
			if fase == "prep" and t >= float(d["prep"]):
				fase = "golpe"
				t = 0.0
				_pose_p("impacto")
				_impacto_jogador(estado)
			elif fase == "golpe" and t >= float(d["golpe"]):
				fase = "rec"
				t = 0.0
				_pose_p("recupera")
			elif fase == "rec" and t >= float(d["rec"]):
				estado = "livre"
				fase = ""
				_pose_p("defende" if defendendo else "guarda")
		"dano":
			if t >= DANO_DUR:
				estado = "livre"
				_pose_p("defende" if defendendo else "guarda")


func esta_invulneravel() -> bool:
	return estado == "esquiva" and t >= float(ESQUIVA_INVUL[0]) and t <= float(ESQUIVA_INVUL[1])


func _impacto_jogador(tipo: String) -> void:
	if _impacto_feito:
		return
	_impacto_feito = true
	if absf(X_BONECO - x) > ALCANCE_JOGADOR:
		_fb("Fora de alcance", "cinza")
		return
	if tipo == "leve":
		placar["leves"] += 1
	else:
		placar["pesados"] += 1
	match b_estado:
		"prepara":
			if tipo == "pesado":
				b_estado = "atordoado"
				b_t = 0.0
				_b_resolvido = true
				_pose_b("dano", "atordoado")
				_fb("Quebrou o golpe!", "ouro")
			else:
				_fb("Acerto leve", "branco")
		"atordoado":
			if tipo == "pesado":
				placar["criticos"] += 1
				_fb("CRÍTICO!", "ouro")
			else:
				_fb("Acerto no atordoado", "branco")
			_pose_b("dano", "atordoado")
		"golpe", "recupera":
			_fb("Acerto leve" if tipo == "leve" else "Acerto pesado", "branco")
		_:
			b_estado = "reage"
			b_t = 0.0
			_pose_b("dano")
			_fb("Acerto leve" if tipo == "leve" else "Acerto pesado", "branco")


func _atualizar_boneco(dt: float) -> void:
	b_t += dt
	match b_estado:
		"espera":
			b_prox -= dt
			if b_prox <= 0.0:
				b_estado = "prepara"
				b_t = 0.0
				_b_resolvido = false
				_pose_b("prepara", "alerta")
		"prepara":
			if b_t >= BONECO_PREPARA:
				b_estado = "golpe"
				b_t = 0.0
				_pose_b("impacto")
				_golpe_do_boneco()
		"golpe":
			if b_t >= BONECO_GOLPE:
				b_estado = "recupera"
				b_t = 0.0
				_pose_b("recupera")
		"recupera":
			if b_t >= BONECO_REC:
				_voltar_espera()
		"atordoado":
			if b_t >= BONECO_ATORDOA:
				_voltar_espera(1.5)
		"reage":
			if b_t >= BONECO_REACAO:
				_voltar_espera(1.0)


func _voltar_espera(min_espera: float = 0.0) -> void:
	b_estado = "espera"
	b_t = 0.0
	b_prox = maxf(min_espera, rng.randf_range(2.5, 4.0))
	_pose_b("guarda")


func _golpe_do_boneco() -> void:
	# durante a esquiva vale a posição de onde ela começou (a esquiva anula o golpe que já estava no alcance)
	var dist := X_BONECO - (_x_esquiva0 if estado == "esquiva" else x)
	if dist > ALCANCE_BONECO:
		_fb("Golpe errou (longe)", "cinza")
		return
	if esta_invulneravel():
		placar["esquivas"] += 1
		_fb("ESQUIVOU!", "verde")
		return
	if defendendo and estado == "livre":
		if t_defesa <= PARRY_JANELA:
			placar["parries"] += 1
			b_estado = "atordoado"
			b_t = 0.0
			_pose_b("dano", "atordoado")
			_pose_p("empurrao")
			_fb("PARRY!", "ouro")
		else:
			placar["bloqueios"] += 1
			x = maxf(X_MIN, x - 24.0)
			_fb("Bloqueou", "branco")
		return
	placar["levados"] += 1
	estado = "dano"
	fase = ""
	t = 0.0
	carregando = false
	carga = 0.0
	_pose_p("dano")
	_fb("Levou o golpe", "vermelho")
