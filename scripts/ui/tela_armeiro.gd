class_name TelaArmeiro
extends Tela
## Aba "armeiro" (provisória: será substituída pela tela completa).

func construir() -> void:
	var v := rolagem()
	v.add_child(Tema.titulo("Armeiro"))
	v.add_child(Tema.rotulo("Em construção."))
