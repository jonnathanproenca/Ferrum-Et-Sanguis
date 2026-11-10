extends RefCounted
## Tela de perfis (DESTINO=modos abre a escolha de modo).
func preparar(arvore: SceneTree) -> void:
	for s in range(1, 4):
		Jogo.apagar_save(s)
	Jogo.slot_novo = 1
	Jogo.novo(Game.lanistas()[3]["id"], "medio", "imperial")
	Jogo.e["turno"] = 23
	Jogo.e["vitoriasTotais"] = 9
	Jogo.e["batalhasTotais"] = 12
	Jogo.renomear_perfil(1, "Ludus de Capua")
	Jogo.slot_novo = 2
	Jogo.novo(Game.lanistas()[1]["id"], "dificil", "sangue")
	for g in Jogo.e["gladiadores"]:
		g["vivo"] = false
	Jogo.e["ouro"] = 0
	Jogo.salvar()
	Jogo.e = {}
	Jogo.slot = 0
	Jogo.navegar.emit(OS.get_environment("DESTINO") if OS.get_environment("DESTINO") != "" else "perfis")
