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
		# Não remove da árvore: tweens ligados a ela (ex.: zoom do menu) acusam erro se o nó sai antes de ser liberado.
		_atual.hide()
		_atual.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_atual.process_mode = Node.PROCESS_MODE_DISABLED
		_atual.queue_free()
	match destino:
		"menu":
			_atual = TelaMenu.new()
		"perfis":
			_atual = TelaPerfis.new()
		"modos":
			_atual = TelaModos.new()
		"selecao":
			_atual = TelaSelecao.new()
		_:
			_atual = Hud.new()
	add_child(_atual)
