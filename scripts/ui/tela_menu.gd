class_name TelaMenu
extends Control
## Menu principal (provisório).

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var v := Tema.vbox(14)
	v.set_anchors_preset(Control.PRESET_CENTER)
	add_child(v)
	v.add_child(Tema.titulo("FERRUM ET SANGUIS", 48))
	var n := Tema.botao("Novo ludus", "primario")
	n.pressed.connect(func(): Jogo.navegar.emit("selecao"))
	v.add_child(n)
	var c := Tema.botao("Continuar")
	c.disabled = not Jogo.tem_save()
	c.pressed.connect(func(): if Jogo.continuar(): Jogo.navegar.emit("jogo"))
	v.add_child(c)
