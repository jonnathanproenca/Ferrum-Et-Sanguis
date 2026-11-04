class_name TelaLudus
extends Tela
## Aba "ludus" (provisória: será substituída pela tela completa).

func construir() -> void:
	var v := rolagem()
	v.add_child(Tema.titulo("Ludus"))
	v.add_child(Tema.rotulo("Em construção."))
