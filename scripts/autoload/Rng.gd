extends Node

var generator := RandomNumberGenerator.new()

func seed_rng(value: int) -> void:
	generator.seed = value

func randf() -> float:
	return generator.randf()
