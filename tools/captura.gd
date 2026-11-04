extends Node
## Captura de tela headless (rodada como cena, para os autoloads existirem). Veja tools/captura.sh.
## `setup.gd` é um script com `func preparar(arvore: SceneTree)` (pode usar await); use "-" para só abrir a cena principal.
func _ready() -> void:
	var a := OS.get_cmdline_user_args()
	var frames: int = int(a[2]) if a.size() > 2 else 20
	var tree := get_tree()
	var principal: Node = load("res://scenes/main.tscn").instantiate()
	tree.root.add_child.call_deferred(principal)
	for i in range(4):
		await tree.process_frame
	if a[0] != "-":
		var s = load(a[0]).new()
		await s.preparar(tree)
	for i in range(frames):
		await tree.process_frame
	tree.root.get_texture().get_image().save_png(a[1])
	tree.quit()
