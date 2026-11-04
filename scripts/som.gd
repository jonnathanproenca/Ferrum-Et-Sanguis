extends Node
## Música e efeitos sonoros. Registrado como autoload "Som". Arquivos em res://assets/audio/.

var _musica: AudioStreamPlayer
var _musica_saindo: AudioStreamPlayer
var _efeitos: Array[AudioStreamPlayer] = []
var _atual := ""
var _cache := {}

func _ready() -> void:
	_musica = AudioStreamPlayer.new()
	_musica_saindo = AudioStreamPlayer.new()
	add_child(_musica)
	add_child(_musica_saindo)
	for i in range(8):
		var p := AudioStreamPlayer.new()
		add_child(p)
		_efeitos.append(p)
	_aplicar_volume()

func _carregar(caminho: String) -> AudioStream:
	if not _cache.has(caminho):
		_cache[caminho] = load(caminho) if ResourceLoader.exists(caminho) else null
	return _cache[caminho]

func _prefs() -> Dictionary:
	return Jogo.prefs["audio"]

func _db(v: float) -> float:
	return -80.0 if v <= 0.001 else linear_to_db(v)

func _aplicar_volume() -> void:
	var p := _prefs()
	_musica.volume_db = _db(float(p["musica"])) if p["ativo"] else -80.0

## Toca a trilha em loop (chave: menu, gestao, pompeia, capua, coliseu, poco, campanha). Repetir a mesma chave não reinicia.
func musica(chave: String) -> void:
	if chave == _atual:
		return
	_atual = chave
	var s := _carregar("res://assets/audio/musica/%s.mp3" % chave)
	_musica_saindo.stop()
	if _musica.playing:
		var t := _musica_saindo
		_musica_saindo = _musica
		_musica = t
		var tw := create_tween()
		tw.tween_property(_musica_saindo, "volume_db", -80.0, 0.8)
		tw.tween_callback(_musica_saindo.stop)
	if s == null:
		return
	var inst: AudioStream = s.duplicate()
	if inst is AudioStreamMP3:
		inst.loop = true
	_musica.stream = inst
	_aplicar_volume()
	if _prefs()["ativo"]:
		_musica.play()

func parar_musica() -> void:
	_atual = ""
	_musica.stop()

## Efeito sonoro: "sfx/moeda", "sfx/bocejo", "sfx/cheat", "cena/bigorna"... (sem extensão).
func sfx(nome: String, volume: float = 1.0) -> void:
	if not _prefs()["ativo"]:
		return
	var s := _carregar("res://assets/audio/%s.mp3" % nome)
	if s == null:
		return
	for p in _efeitos:
		if not p.playing:
			p.stream = s
			p.volume_db = _db(float(_prefs()["efeitos"]) * volume)
			p.play()
			return

## Voz aleatória de um personagem: "engenheiro", "medico" ou "mercador".
func voz(quem: String) -> void:
	sfx("voz/%s-%d" % [quem, randi_range(1, 3)])

func definir_prefs(valores: Dictionary) -> void:
	for k in valores:
		_prefs()[k] = valores[k]
	Jogo.salvar_prefs()
	_aplicar_volume()
	if not _prefs()["ativo"]:
		_musica.stop()
	elif _atual != "" and not _musica.playing:
		var a := _atual
		_atual = ""
		musica(a)
