class_name TelaSelecao
extends Control
## Escolha do lanista e da dificuldade (provisório: assume o primeiro lanista no Médio).

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var v := Tema.vbox(14)
	v.set_anchors_preset(Control.PRESET_CENTER)
	add_child(v)
	v.add_child(Tema.titulo("Escolha seu lanista"))
	var b := Tema.botao("Assumir o ludus", "primario")
	b.pressed.connect(func(): Jogo.novo(Game.lanistas()[0]["id"], "medio"); Jogo.navegar.emit("jogo"))
	v.add_child(b)
