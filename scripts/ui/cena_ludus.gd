class_name CenaLudus
extends Control
## Cena do ludus no alto do morro (provisória; será substituída). Mantém a proporção da imagem base (1024x572).
func _ready() -> void:
	custom_minimum_size = Vector2(0, 360)
	var t := TextureRect.new()
	t.texture = Tema.textura("assets/ludus/base.png")
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	t.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(t)
