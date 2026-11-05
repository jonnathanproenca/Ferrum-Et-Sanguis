extends RefCounted
## Seleção de lanista. SEL=n (0..9) marca o lanista, DIF=facil|medio|dificil|extremo.
func preparar(arvore: SceneTree) -> void:
	Jogo.e = {}
	Jogo.navegar.emit("selecao")
	await arvore.process_frame
	await arvore.process_frame
	var t = arvore.root.find_children("*", "TelaSelecao", true, false)[0]
	if OS.get_environment("SEL") != "":
		t._marcar(int(OS.get_environment("SEL")))
	if OS.get_environment("DIF") != "":
		t._dif = OS.get_environment("DIF")
		t._atualizar_dif()
