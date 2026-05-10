extends Control

@export var allowed_mask: Texture2D
@export var max_tries: int = 3
@export var min_point_dist: float = 6.0
@export var start_radius: float = 120.0
@export var end_radius: float = 120.0
@export var instant_fail_on_outside: bool = true

@onready var bg: TextureRect = $BG
@onready var player_line: Line2D = $DrawLayer/PlayerLine
@onready var start_points: Node2D = $StartPoints
@onready var end_points: Node2D = $EndPoints

@onready var tries_label: Label = $UI/TriesLabel
@onready var message_label: Label = $UI/MessageBox/Margin/MessageLabel

@onready var overlay: Control = $UI/Overlay
@onready var result_label: Label = $UI/Overlay/Card/ResultLabel
@onready var redo_button: Button = $UI/Overlay/Card/RedoButton

var finished := false
var tries_left: int
var drawing := false

var mask_img: Image
var mask_size: Vector2i

var used_end_nodes: Dictionary = {}   # instance_id -> true, hash map to prevent same port being used 
var facts: Array[String] = []
var fact_index := 0

# Tracks whether the stroke started near a start-point or an end-point
# "start" | "end" | ""
var start_kind: String = ""

func _ready() -> void:
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$UI.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$UI/MessageBox.mouse_filter = Control.MOUSE_FILTER_IGNORE

	tries_left = max_tries
	_update_tries()

	player_line.z_index = 10
	player_line.width = max(player_line.width, 10.0)

	overlay.visible = false
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	redo_button.visible = false
	redo_button.pressed.connect(_on_redo_pressed)

	if allowed_mask == null:
		push_error("Assign res://assets/sprites/Quest1_Water_Mask.png to allowed_mask.")
		return

	mask_img = allowed_mask.get_image()
	mask_img.decompress()
	mask_size = Vector2i(mask_img.get_width(), mask_img.get_height())

	facts = [
		tr("Q1_FACT_1"),
		tr("Q1_FACT_2"),
		tr("Q1_FACT_3"),
		tr("Q1_FACT_4"),
		tr("Q1_FACT_5"),
		tr("Q1_FACT_6")
	]
	facts.shuffle()
	fact_index = 0

	message_label.text = tr("Q1_INSTRUCTIONS")
	_clear_line()

func _input(event: InputEvent) -> void: #input handling loop
	if overlay.visible:
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_begin_draw()
		else:
			_end_draw()

	if event is InputEventMouseMotion and drawing:
		_add_point(get_global_mouse_position())

func _begin_draw() -> void:
	drawing = true
	start_kind = ""
	_clear_line()

	var mouse_pos: Vector2 = get_global_mouse_position()

	var s = _nearest_node_within(start_points, mouse_pos, start_radius)
	var e = _nearest_node_within(end_points, mouse_pos, end_radius)

	# Must start near either a StartDot OR an EndDot
	if s == null and e == null:
		# Half-line: vanish, no penalty
		drawing = false
		_clear_line()
		return

	start_kind = "start" if s != null else "end"
	_add_point(mouse_pos)

func _end_draw() -> void: #Path validation by sampling, constraint checking against a mask
	if not drawing:
		return
	drawing = false

	# Must have drawn something meaningful
	if player_line.points.size() < 1:
		_clear_line()
		return

	var last_global: Vector2 = _line_last_global()

	var ended_on_start := _nearest_node_within(start_points, last_global, start_radius)
	var ended_on_end := _nearest_node_within(end_points, last_global, end_radius)

	# Must end near a valid opposite type
	var connected := false
	var end_node: CanvasItem = null

	if start_kind == "start" and ended_on_end != null:
		connected = true
		end_node = ended_on_end
	elif start_kind == "end" and ended_on_start != null:
		connected = true
		end_node = _nearest_end_to_first_point()

	if not connected:
		# Half-line: vanish, no penalty
		_clear_line()
		return

	if end_node != null:
		var end_id := end_node.get_instance_id()
		if used_end_nodes.has(end_id):
			# Half-line style: vanish, no penalty 
			_clear_line()
			return

	# Validate mask path
	for lp in player_line.points:
		var gp: Vector2 = player_line.to_global(lp)
		if not _is_point_allowed(gp):
			_fail_attempt(tr("Q1_FAIL_OUTSIDE"))
			return

	# Success: keep the line + lock the port + show next fact
	_commit_current_line()

	if end_node != null:
		used_end_nodes[end_node.get_instance_id()] = true

	_on_connection_success()

func _nearest_end_to_first_point() -> CanvasItem:
	# The first point is local to player_line; convert to global
	var first_global: Vector2 = player_line.to_global(player_line.points[0])
	return _nearest_node_within(end_points, first_global, end_radius)

func _commit_current_line() -> void:
	# Freeze current line as a child so points stay aligned (local space)
	var frozen := Line2D.new()
	frozen.width = player_line.width
	frozen.default_color = player_line.default_color
	frozen.z_index = player_line.z_index - 1

	for p in player_line.points:
		frozen.add_point(p)

	player_line.add_child(frozen)

func _on_connection_success() -> void:
	_clear_line()

	if finished:
		return

	if fact_index < facts.size():
		message_label.text = facts[fact_index]
		fact_index += 1

	if used_end_nodes.size() >= 6:
		finished = true
		message_label.text = tr("QUEST_COMPLETED")
		Global.complete_quest(1)
		await get_tree().create_timer(1.2).timeout
		Global.next_scene = "res://overworld.tscn"
		get_tree().change_scene_to_file("res://scenes/loading_screen.tscn")


func _add_point(global_pos: Vector2) -> void:
	var local_pos: Vector2 = player_line.to_local(global_pos)

	if player_line.points.size() > 0:
		var last_local: Vector2 = player_line.points[-1]
		if local_pos.distance_to(last_local) < min_point_dist:
			return

	if instant_fail_on_outside and not _is_point_allowed(global_pos):
		_fail_attempt(tr("Q1_FAIL_OUTSIDE"))
		drawing = false
		return

	player_line.add_point(local_pos)

func _line_last_global() -> Vector2:
	return player_line.to_global(player_line.points[-1])

# SCALE-AWARE + Keep Aspect Centered sampling (works with BG scale 0.5)
func _is_point_allowed(global_pos: Vector2) -> bool:
	var tex: Texture2D = bg.texture
	if tex == null:
		return false

	var local_unscaled: Vector2 = bg.get_global_transform().affine_inverse() * global_pos

	var rect_size: Vector2 = bg.size * bg.scale
	var tex_size: Vector2 = tex.get_size()
	if rect_size.x <= 0.0 or rect_size.y <= 0.0:
		return false

	var scale_factor: float = min(rect_size.x / tex_size.x, rect_size.y / tex_size.y)
	var drawn_size: Vector2 = tex_size * scale_factor
	var offset: Vector2 = (rect_size - drawn_size) * 0.5

	var local_scaled: Vector2 = local_unscaled * bg.scale
	var p: Vector2 = local_scaled - offset

	if p.x < 0 or p.y < 0 or p.x > drawn_size.x or p.y > drawn_size.y:
		return false

	var u: float = p.x / drawn_size.x
	var v: float = p.y / drawn_size.y

	var px: int = int(u * float(mask_size.x - 1))
	var py: int = int(v * float(mask_size.y - 1))

	return mask_img.get_pixel(px, py).r > 0.5

func _nearest_node_within(container: Node, target: Vector2, radius: float) -> CanvasItem:
	var best_dist: float = INF
	var best_node: CanvasItem = null

	for child in container.get_children():
		if child is CanvasItem:
			var pos: Vector2 = _global_center(child)
			var d: float = target.distance_to(pos)
			if d <= radius and d < best_dist:
				best_dist = d
				best_node = child

	return best_node

func _global_center(node: CanvasItem) -> Vector2:
	if node is Control:
		var r = node.get_global_rect()
		return r.position + r.size * 0.5
	else:
		return node.get_global_transform().origin

func _fail_attempt(reason: String) -> void:
	tries_left -= 1
	_update_tries()
	_clear_line()

	if tries_left <= 0:
		overlay.visible = true
		result_label.text = tr("Q1_FAIL_RESULT") % reason
		redo_button.visible = true
	else:
		message_label.text = tr("Q1_TRIES_LEFT") % [reason, tries_left, max_tries]

func _on_redo_pressed() -> void:
	overlay.visible = false
	redo_button.visible = false

	tries_left = max_tries
	used_end_nodes.clear()
	facts.shuffle()
	fact_index = 0

	# Remove frozen lines
	for child in player_line.get_children():
		if child is Line2D:
			child.queue_free()

	message_label.text = tr("Q1_INSTRUCTIONS")
	_update_tries()
	_clear_line()

func _clear_line() -> void:
	player_line.clear_points()

func _update_tries() -> void:
	tries_label.text = tr("TRIES_LABEL") % [tries_left, max_tries]
