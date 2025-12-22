extends Area2D
class_name Seal

signal dropped(seal: Seal)

@export var seal_id: String = ""
@export var order_index: int = 0

@onready var sprite: AnimatedSprite2D = $Sprite

var _dragging := false
var _locked := false
var _drag_offset := Vector2.ZERO
var start_pos := Vector2.ZERO

# Tweak these if you want
const DRAG_Z := 2000
const LOCKED_Z := 1500
const NORMAL_Z := 10

func _ready() -> void:
	start_pos = global_position

	# Ensure seal renders above placeholders reliably
	z_as_relative = false
	z_index = NORMAL_Z

	if sprite:
		sprite.play("idle")

func lock_to(pos: Vector2) -> void:
	_locked = true
	_dragging = false
	global_position = pos

	# Keep it on top after snapping
	z_as_relative = false
	z_index = LOCKED_Z

	# stop interaction
	input_pickable = false

	if sprite:
		sprite.play("spin")

func return_to_start() -> void:
	global_position = start_pos

	# Reset draw order when sent back
	z_as_relative = false
	z_index = NORMAL_Z

func _input_event(_viewport: Viewport, event: InputEvent, _shape_idx: int) -> void:
	if _locked:
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_dragging = true
			_drag_offset = global_position - get_global_mouse_position()

			# Bring to front while dragging
			z_as_relative = false
			z_index = DRAG_Z
		else:
			if _dragging:
				_dragging = false
				# Back to normal unless it gets locked by the quest script
				z_as_relative = false
				z_index = NORMAL_Z
				dropped.emit(self)

func _process(_delta: float) -> void:
	if _dragging and not _locked:
		global_position = get_global_mouse_position() + _drag_offset
