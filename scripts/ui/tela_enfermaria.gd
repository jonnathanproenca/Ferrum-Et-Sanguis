class_name TelaEnfermaria
extends Tela
## Aba "enfermaria" (provisória: será substituída pela tela completa).

func construir() -> void:
	var v := rolagem()
	v.add_child(Tema.titulo("Enfermaria"))
	v.add_child(Tema.rotulo("Em construção."))
