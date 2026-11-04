class_name TelaCampanha
extends Tela
## Aba "campanha" (provisória: será substituída pela tela completa).

func construir() -> void:
	var v := rolagem()
	v.add_child(Tema.titulo("Campanha"))
	v.add_child(Tema.rotulo("Em construção."))
