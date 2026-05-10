extends Area2D

@export var accepts_type: String = "barley" # "barley", "wheat", "dates"
@export var lip_extra_offset: float = 0.0

var collected: int = 0

@onready var col: CollisionShape2D = $CollisionShape2D

func add_correct_item() -> void:
	collected += 1

func can_accept(t: String) -> bool:
	return t == accepts_type

func get_lip_global_y() -> float:
	var rect: RectangleShape2D = col.shape as RectangleShape2D
	if rect == null:
		return global_position.y + lip_extra_offset

	var half_h: float = rect.size.y * 0.5
	return global_position.y - half_h + lip_extra_offset
