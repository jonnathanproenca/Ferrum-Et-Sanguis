class_name TelaMercado
extends Tela
## Aba "mercado" (provisória: será substituída pela tela completa).

func construir() -> void:
	var v := rolagem()
	v.add_child(Tema.titulo("Mercado"))
	v.add_child(Tema.rotulo("Em construção."))
