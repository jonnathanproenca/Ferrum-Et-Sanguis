extends Control
## Raiz do jogo: alterna entre menu, escolha de lanista e o HUD da partida.

var _atual: Control

func _ready() -> void:
	theme = Tema.tema()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var fundo := ColorRect.new()
	fundo.color = Tema.BG
	fundo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(fundo)
	Jogo.navegar.connect(_ir)
	_ir("menu")

func _ir(destino: String) -> void:
	if _atual:
		remove_child(_atual)
		_atual.queue_free()
	match destino:
		"menu":
			_atual = TelaMenu.new()
		"selecao":
			_atual = TelaSelecao.new()
		_:
			_atual = Hud.new()
	add_child(_atual)
