@tool
extends Area2D

# Stored as LOCAL position relative to shard's parent (usually $Shards)
@export var correct_position: Vector2
@export var snap_distance: float = 24.0

@export var CAPTURE_CORRECT_NOW: bool = false:
	set(value):
		# Only run when user toggles it in the editor
		if Engine.is_editor_hint() and value:
			_capture_correct_from_current()
		CAPTURE_CORRECT_NOW = false  # reset so you can click again

var dragging := false
var offset := Vector2.ZERO
var placed_correctly := false
var _start_position := Vector2.ZERO

@onready var polygon: Polygon2D = $Polygon2D


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	_start_position = global_position


func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		return
	if dragging:
		global_position = get_global_mouse_position() + offset


func _input_event(_vp: Viewport, event: InputEvent, _shape_idx: int) -> void:
	if Engine.is_editor_hint():
		return

	if placed_correctly:
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			dragging = true
			offset = global_position - get_global_mouse_position()
			polygon.modulate = Color(1, 1, 1)
		else:
			if dragging:
				dragging = false
				_check_snap()


func _check_snap() -> void:
	# Convert LOCAL correct_position → GLOBAL
	var target_global: Vector2 = get_parent().to_global(correct_position)
	var dist := global_position.distance_to(target_global)

	print("%s | current=%s | target=%s | dist=%s" % [name, global_position, target_global, dist])

	if dist <= snap_distance:
		global_position = target_global
		placed_correctly = true
		set_process(false)
		polygon.modulate = Color(0.7, 1.0, 0.7)
		var controllers = get_tree().get_nodes_in_group("quest2_controller")
		if controllers.size() > 0:
			controllers[0].call_deferred("_check_puzzle_complete")

	else:
		polygon.modulate = Color(1, 1, 1)
		var tween := create_tween()
		tween.tween_property(self, "global_position", _start_position, 0.35) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _capture_correct_from_current() -> void:
	if get_parent() == null:
		push_warning("%s: No parent, can't capture." % name)
		return

	# Save the shard's current position (global) into the parent's local space.
	correct_position = get_parent().to_local(global_position)
	print("%s captured correct_position=%s (parent local)" % [name, correct_position])

	notify_property_list_changed()
