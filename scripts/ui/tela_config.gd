class_name TelaConfig
extends Tela
## Aba "config" (provisória: será substituída pela tela completa).

func construir() -> void:
	var v := rolagem()
	v.add_child(Tema.titulo("Config"))
	v.add_child(Tema.rotulo("Em construção."))
