extends Area2D

var collected := false

func _ready():
	body_entered.connect(_on_hit)


func _on_hit(body):
	if collected:
		return

	if body.name == "Boat":
		collected = true

		get_tree().call_group("quest3_game", "on_pearl_collected")

		queue_free()
