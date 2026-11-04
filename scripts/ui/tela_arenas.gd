class_name TelaArenas
extends Tela
## Aba "arenas" (provisória: será substituída pela tela completa).

func construir() -> void:
	var v := rolagem()
	v.add_child(Tema.titulo("Arenas"))
	v.add_child(Tema.rotulo("Em construção."))
