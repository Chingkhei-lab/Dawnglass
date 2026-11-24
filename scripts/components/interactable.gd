extends Area2D

@export_multiline var interaction_text := "The sign points toward the lighthouse."

func interact() -> String:
	return interaction_text
