extends Area2D

signal dropped(item, basket)
signal fell_into_basket(item, basket)

@export var fall_speed: float = 180.0
@export var offscreen_y: float = 1200.0

var item_type: String = ""
var _dragging: bool = false
var _drag_offset: Vector2 = Vector2.ZERO
var _current_basket: Area2D = null
var _landed: bool = false

@onready var sprite: Sprite2D = $Sprite

func _ready() -> void:
	input_pickable = true
	monitoring = true
	monitorable = true

	# Make sure signals work even if not wired in the editor
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)

	# Handles “spawns already inside basket”
	call_deferred("_refresh_current_basket")

func setup_item(t: String, tex: Texture2D) -> void:
	item_type = t
	sprite.texture = tex

func _input_event(viewport, event, shape_idx) -> void:
	if _landed:
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_dragging = true
			_drag_offset = global_position - event.position
			z_index = 999
		else:
			if _dragging:
				_dragging = false
				z_index = 0
				_refresh_current_basket()
				# Released by user
				dropped.emit(self, _current_basket)

func _physics_process(delta: float) -> void:
	if _landed:
		return
	if _dragging:
		var screen_size = get_viewport_rect().size
		var raw_pos = get_viewport().get_mouse_position() + _drag_offset
		global_position = Vector2(
			clamp(raw_pos.x, 0, screen_size.x),
			clamp(raw_pos.y, 0, screen_size.y)
		)
		_refresh_current_basket()
	else:
		global_position.y += fall_speed * delta
		_refresh_current_basket()
		if _current_basket != null:
			_landed = true
			fell_into_basket.emit(self, _current_basket)
			dropped.emit(self, _current_basket)
			queue_free()
			return
		if global_position.y > offscreen_y:
			queue_free()

func _on_area_entered(area: Area2D) -> void:
	_current_basket = area

func _on_area_exited(area: Area2D) -> void:
	if _current_basket == area:
		_current_basket = null

func _refresh_current_basket() -> void:
	var areas := get_overlapping_areas()
	_current_basket = null
	for a in areas:
		if a is Area2D:
			_current_basket = a
			return
