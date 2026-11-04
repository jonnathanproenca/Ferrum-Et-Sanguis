class_name PainelEscalacao
extends VBoxContainer
## Escolha dos gladiadores da próxima luta (compartilha `Jogo.equipe`). Provisório e funcional; a tela de Arenas o refina.
## API: `formato` (1 ou 2 gladiadores; 0 = livre entre 1 e 2), `atualizar()`, `ids()`. Sinal `mudou_equipe`.
signal mudou_equipe

var formato := 0
var _lista: HFlowContainer

func _ready() -> void:
	add_theme_constant_override("separation", 8)
	_lista = HFlowContainer.new()
	_lista.add_theme_constant_override("h_separation", 8)
	_lista.add_theme_constant_override("v_separation", 8)
	add_child(_lista)
	Jogo.mudou.connect(atualizar)
	atualizar()

func ids() -> Array:
	return Jogo.equipe_valida().map(func(g): return g["id"])

func atualizar() -> void:
	if Jogo.e.is_empty() or _lista == null:
		return
	Tema.limpar(_lista)
	Jogo.equipe_valida()
	for g in Jogo.e["gladiadores"]:
		if not g["vivo"] or g.get("semEstilo", false):
			continue
		var b := Tema.botao("%s (%s)" % [g["nome"], Model.classes()[g["classe"]]["nome"]], "ouro" if g["id"] in Jogo.equipe else "normal")
		b.pressed.connect(func(): _alternar(g["id"]))
		_lista.add_child(b)

func _alternar(id: String) -> void:
	if id in Jogo.equipe:
		Jogo.equipe.erase(id)
	else:
		var max_n: int = formato if formato > 0 else 2
		if Jogo.equipe.size() >= max_n:
			Jogo.equipe.pop_front()
		Jogo.equipe.append(id)
	atualizar()
	mudou_equipe.emit()
