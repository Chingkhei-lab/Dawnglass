extends Node

var generator := RandomNumberGenerator.new()

func seed_rng(value: int) -> void:
	generator.seed = value

func randf() -> float:
	return generator.randf()

func randi_range(from: int, to: int) -> int:
	return generator.randi_range(from, to)
