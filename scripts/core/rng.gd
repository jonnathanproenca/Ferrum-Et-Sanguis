class_name Rng
extends RefCounted
## Gerador determinístico mulberry32 (idêntico ao do jogo em TypeScript).

var estado: int = 0

func _init(semente: int = 0) -> void:
	estado = semente & 0xFFFFFFFF

static func _imul(a: int, b: int) -> int:
	return (a * b) & 0xFFFFFFFF

## Número em [0, 1)
func proximo() -> float:
	estado = (estado + 0x6d2b79f5) & 0xFFFFFFFF
	var t: int = estado
	t = _imul(t ^ (t >> 15), t | 1)
	t = (t ^ ((t + _imul(t ^ (t >> 7), t | 61)) & 0xFFFFFFFF)) & 0xFFFFFFFF
	return float((t ^ (t >> 14)) & 0xFFFFFFFF) / 4294967296.0

## Inteiro em [minimo, maximo], inclusive
func inteiro(minimo: int, maximo: int) -> int:
	return minimo + int(floor(proximo() * float(maximo - minimo + 1)))

func d20() -> int:
	return inteiro(1, 20)
