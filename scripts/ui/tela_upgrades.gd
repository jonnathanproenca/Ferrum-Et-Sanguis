class_name TelaUpgrades
extends Tela
## Aba "upgrades" (provisória: será substituída pela tela completa).

func construir() -> void:
	var v := rolagem()
	v.add_child(Tema.titulo("Upgrades"))
	v.add_child(Tema.rotulo("Em construção."))
