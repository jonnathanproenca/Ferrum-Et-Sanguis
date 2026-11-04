class_name Tela
extends Control
## Base das telas (abas) do HUD. Sobrescreva `construir` (cria os nós uma vez) e `atualizar` (redesenha a partir de Jogo.e).

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	Jogo.mudou.connect(_ao_mudar)
	construir()
	if not Jogo.e.is_empty():
		atualizar()

func _ao_mudar() -> void:
	if is_visible_in_tree() and not Jogo.e.is_empty():
		atualizar()

func construir() -> void:
	pass

func atualizar() -> void:
	pass

## Chamado quando a aba passa a ficar visível (tocar voz, música, reiniciar animações).
func ao_mostrar() -> void:
	if not Jogo.e.is_empty():
		atualizar()

## ScrollContainer de tela cheia com um VBox dentro (margem de 16 px); devolve o VBox.
func rolagem(sep: int = 12) -> VBoxContainer:
	var sc := ScrollContainer.new()
	sc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(sc)
	var m := MarginContainer.new()
	m.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for lado in ["left", "right", "top", "bottom"]:
		m.add_theme_constant_override("margin_" + lado, 16)
	sc.add_child(m)
	var v := Tema.vbox(sep)
	m.add_child(v)
	return v
