extends Control

const _InstructionPanel = preload("res://scripts/InstructionPanel.gd")

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

@onready var result_panel: CanvasLayer = $QuestResultPanel

var finished := false
var tries_left: int
var drawing := false

var mask_img: Image
var mask_size: Vector2i

var used_end_nodes: Dictionary = {}
var facts: Array[String] = []
var fact_index := 0

var start_kind: String = ""

func _ready() -> void:
	self.layout_direction = Control.LAYOUT_DIRECTION_LTR
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.layout_direction = Control.LAYOUT_DIRECTION_LTR
	$UI.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$UI/MessageBox.mouse_filter = Control.MOUSE_FILTER_IGNORE

	tries_left = max_tries
	_update_tries()

	player_line.z_index = 10
	player_line.width = max(player_line.width, 10.0)

	# Wire result panel signals
	result_panel.retry_pressed.connect(_on_retry)
	result_panel.exit_pressed.connect(_on_exit)
	result_panel.continue_pressed.connect(_on_continue)

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
	_apply_arabic_font_to_ui()
	_translate_map_labels()
	var _input_overlay: Node = load("res://scripts/InputHintOverlay.gd").new()
	_input_overlay.setup("mouse")
	add_child(_input_overlay)
	_start_onboarding()
	_add_endpoint_dots()


func _start_onboarding() -> void:
	var tut: Node = load("res://scripts/OnboardingTutorial.gd").new()
	tut.setup([
		{
			"en": "The blue dots are Ports \u2014 start or end your path here.",
			"ar": "\u0627\u0644\u0646\u0642\u0627\u0637 \u0627\u0644\u0632\u0631\u0642\u0627\u0621 \u0647\u064a \u0627\u0644\u0645\u0648\u0627\u0646\u0626 \u2014 \u0627\u0628\u062f\u0623 \u0645\u0633\u0627\u0631\u0643 \u0623\u0648 \u0623\u0646\u0647\u0650\u0647 \u0645\u0646\u0647\u0627.",
			"target": Vector2(0.16, 0.34),
			"align": "bottom"
		},
		{
			"en": "The golden dots are Landmarks \u2014 connect every single one!",
			"ar": "\u0627\u0644\u0646\u0642\u0627\u0637 \u0627\u0644\u0630\u0647\u0628\u064a\u0629 \u0647\u064a \u0627\u0644\u0645\u0639\u0627\u0644\u0645 \u2014 \u064a\u062c\u0628 \u0631\u0628\u0637 \u0643\u0644 \u0648\u0627\u062d\u062f\u0629!",
			"target": Vector2(0.55, 0.21),
			"align": "bottom"
		},
		{
			"en": "Click and drag between a Port and a Landmark to draw a path. Stay inside the lines!",
			"ar": "\u0627\u0636\u063a\u0637 \u0648\u0627\u0633\u062d\u0628 \u0628\u064a\u0646 \u0645\u064a\u0646\u0627\u0621 \u0648\u0645\u0639\u0644\u0645 \u0644\u0631\u0633\u0645 \u0645\u0633\u0627\u0631. \u0627\u0628\u0642\u064e \u062f\u0627\u062e\u0644 \u0627\u0644\u062e\u0637\u0648\u0637!",
			"target": Vector2(0.46, 0.54),
			"align": "top"
		},
		{
			"en": "Connect every Landmark to a Port to win. You have 3 tries \u2014 good luck!",
			"ar": "\u0627\u0631\u0628\u0637 \u0643\u0644 \u0645\u0639\u0644\u0645 \u0628\u0645\u064a\u0646\u0627\u0621 \u0644\u0644\u0641\u0648\u0632. \u0644\u062f\u064a\u0643 3 \u0645\u062d\u0627\u0648\u0644\u0627\u062a \u2014 \u062d\u0638\u0627\u064b \u0645\u0648\u0641\u0642\u0627\u064b!",
			"target": Vector2(0.18, 0.06),
			"align": "bottom"
		},
	])
	add_child(tut)


func _add_endpoint_dots() -> void:
	# Wait one frame so Control nodes have finalised their layout positions.
	await get_tree().process_frame

	var draw_layer: Node2D = $DrawLayer

	# Port dots (start points) — blue-white
	for child in start_points.get_children():
		if child is CanvasItem:
			var gp: Vector2 = _global_center(child)
			var lp: Vector2 = draw_layer.to_local(gp)
			draw_layer.add_child(_make_dot(lp, 11.0, Color(0.2, 0.75, 1.0, 1.0)))

	# Landmark dots (end points) — golden
	for child in end_points.get_children():
		if child is CanvasItem:
			var gp: Vector2 = _global_center(child)
			var lp: Vector2 = draw_layer.to_local(gp)
			draw_layer.add_child(_make_dot(lp, 11.0, Color(1.0, 0.75, 0.15, 1.0)))


func _make_dot(center: Vector2, radius: float, color: Color) -> Node2D:
	var container := Node2D.new()
	container.z_index = 5

	# Dark outline circle
	var outline := Polygon2D.new()
	outline.color = Color(0.0, 0.0, 0.0, 0.75)
	var outline_pts := PackedVector2Array()
	for i in range(32):
		var a := TAU * i / 32.0
		outline_pts.append(center + Vector2(cos(a), sin(a)) * (radius + 3.0))
	outline.polygon = outline_pts
	container.add_child(outline)

	# Filled colour circle
	var fill := Polygon2D.new()
	fill.color = color
	var fill_pts := PackedVector2Array()
	for i in range(32):
		var a := TAU * i / 32.0
		fill_pts.append(center + Vector2(cos(a), sin(a)) * radius)
	fill.polygon = fill_pts
	container.add_child(fill)

	return container


func _input(event: InputEvent) -> void:
	# Block drawing while result panel is visible
	if result_panel.panel.visible:
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

	if s == null and e == null:
		drawing = false
		_clear_line()
		return

	start_kind = "start" if s != null else "end"
	_add_point(mouse_pos)

func _end_draw() -> void:
	if not drawing:
		return
	drawing = false

	if player_line.points.size() < 1:
		_clear_line()
		return

	var last_global: Vector2 = _line_last_global()

	var ended_on_start := _nearest_node_within(start_points, last_global, start_radius)
	var ended_on_end := _nearest_node_within(end_points, last_global, end_radius)

	var connected := false
	var end_node: CanvasItem = null

	if start_kind == "start" and ended_on_end != null:
		connected = true
		end_node = ended_on_end
	elif start_kind == "end" and ended_on_start != null:
		connected = true
		end_node = _nearest_end_to_first_point()

	if not connected:
		_clear_line()
		return

	if end_node != null:
		var end_id := end_node.get_instance_id()
		if used_end_nodes.has(end_id):
			_clear_line()
			return

	for lp in player_line.points:
		var gp: Vector2 = player_line.to_global(lp)
		if not _is_point_allowed(gp):
			_fail_attempt(tr("Q1_FAIL_OUTSIDE"))
			return

	_commit_current_line()

	if end_node != null:
		used_end_nodes[end_node.get_instance_id()] = true

	_on_connection_success()

func _nearest_end_to_first_point() -> CanvasItem:
	var first_global: Vector2 = player_line.to_global(player_line.points[0])
	return _nearest_node_within(end_points, first_global, end_radius)

func _commit_current_line() -> void:
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
		Global.complete_quest(1)
		result_panel.show_success(tr("QUEST_COMPLETED"))

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
		finished = true
		result_panel.show_failure(tr("Q1_FAIL_RESULT") % reason)
	else:
		message_label.text = tr("Q1_TRIES_LEFT") % [reason, tries_left, max_tries]

func _on_retry() -> void:
	finished = false
	tries_left = max_tries
	used_end_nodes.clear()
	facts.shuffle()
	fact_index = 0

	for child in player_line.get_children():
		if child is Line2D:
			child.queue_free()

	message_label.text = tr("Q1_INSTRUCTIONS")
	_update_tries()
	_clear_line()

func _on_continue() -> void:
	get_tree().change_scene_to_file("res://scenes/loading_screen.tscn")

func _on_exit() -> void:
	Global.next_scene = "res://overworld.tscn"
	get_tree().change_scene_to_file("res://scenes/loading_screen.tscn")

func _clear_line() -> void:
	player_line.clear_points()

func _update_tries() -> void:
	tries_label.text = tr("TRIES_LABEL") % [tries_left, max_tries]

func _apply_arabic_font_to_ui() -> void:
	if Global.current_locale != "ar" or Global.arabic_font == null:
		return
	var text_nodes: Array = [
		$UI/TriesLabel,
		$UI/MessageBox/Margin/MessageLabel,
		$UI/LandmarkLabel,
		$UI/LandmarkLabel2,
		$UI/LandmarkLabel3,
		$UI/LandmarkLabel4,
		$UI/LandmarkLabel5,
		$UI/PortLabel,
		$UI/PortLabel2,
		$UI/PortLabel3,
		$UI/PortLabel4,
	]
	for node in text_nodes:
		if node != null:
			node.add_theme_font_override("font", Global.arabic_font)
			node.add_theme_font_size_override("font_size", node.get_theme_font_size("font_size") + Global.ARABIC_SIZE_BONUS)

func _translate_map_labels() -> void:
	var is_ar := Global.current_locale == "ar"
	var port_text := "ميناء" if is_ar else "Port"
	var landmark_text := "معلم" if is_ar else "Landmark"

	var label_nodes: Array = [
		$UI/LandmarkLabel,
		$UI/LandmarkLabel2,
		$UI/LandmarkLabel3,
		$UI/LandmarkLabel4,
		$UI/LandmarkLabel5,
		$UI/PortLabel,
		$UI/PortLabel2,
		$UI/PortLabel3,
		$UI/PortLabel4,
	]

	for label in label_nodes:
		if label == null:
			continue
		if "Landmark" in label.name:
			label.text = landmark_text
		else:
			label.text = port_text
		label.add_theme_constant_override("outline_size", 5)
		label.add_theme_color_override("font_outline_color", Color.BLACK)
		if is_ar and Global.arabic_font != null:
			label.add_theme_font_override("font", Global.arabic_font)
			label.add_theme_font_size_override("font_size", label.get_theme_font_size("font_size") + Global.ARABIC_SIZE_BONUS)
			label.text_direction = Control.TEXT_DIRECTION_RTL
		else:
			label.text_direction = Control.TEXT_DIRECTION_LTR
