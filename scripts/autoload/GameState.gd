extends Node

var trust: int = 0
var bonds: Dictionary = {}
var inventory: Dictionary = {}
var flags: Dictionary = {}
var sleepers: Array[String] = []
var promises: Array[Dictionary] = []

func mark_sleeper(id: String) -> void:
	if not sleepers.has(id):
		sleepers.append(id)
