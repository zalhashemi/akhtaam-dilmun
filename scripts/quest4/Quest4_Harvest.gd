extends Node2D

const _InstructionPanel = preload("res://scripts/InstructionPanel.gd")

@export var harvest_item_scene: PackedScene

@onready var items_root: Node2D = $Items
@onready var basket_barley: Area2D = $Baskets/BasketBarley
@onready var basket_wheat: Area2D = $Baskets/BasketWheat
@onready var basket_dates: Area2D = $Baskets/BasketDates
@onready var spawn_left: Marker2D = $SpawnArea/SpawnLeft
@onready var spawn_right: Marker2D = $SpawnArea/SpawnRight
@onready var spawn_timer: Timer = $SpawnTimer

@onready var score_label: Label = $UI/ScoreLabel
@onready var lives_label: Label = $UI/LivesLabel
@onready var status_label: Label = $UI/StatusLabel
@onready var feedback_label: Label = $UI/FeedbackLabel
@onready var label_barley: Label = $UI/Barley
@onready var label_wheat: Label = $UI/Wheat
@onready var label_dates: Label = $UI/Dates
@onready var result_panel: CanvasLayer = $QuestResultPanel

var tex_barley: Texture2D
var tex_wheat: Texture2D
var tex_dates: Texture2D
var tex_rotten: Texture2D

var barley_collected: int = 0
var wheat_collected: int = 0
var dates_collected: int = 0
var lives: int = 3
var feedback_timer: Timer

const TARGET_PER_TYPE: int = 5
var game_ended: bool = false

func _ready() -> void:
	score_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	lives_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	randomize()

	tex_barley = load("res://assets/sprites/harvest_barley.png")
	tex_wheat = load("res://assets/sprites/harvest_wheat.png")
	tex_dates = load("res://assets/sprites/harvest_dates.png")
	tex_rotten = load("res://assets/sprites/harvest_rotten.png")

	if harvest_item_scene == null:
		harvest_item_scene = load("res://scenes/objects/HarvestItem.tscn")

	_apply_arabic_font_to_ui()
	_translate_basket_labels()
	_add_basket_fruit_images()
	update_ui()

	feedback_label.text = ""
	feedback_timer = Timer.new()
	feedback_timer.wait_time = 2.0
	feedback_timer.one_shot = true
	add_child(feedback_timer)
	feedback_timer.timeout.connect(_clear_feedback)

	spawn_timer.wait_time = 2.0
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)

	result_panel.retry_pressed.connect(_on_retry)
	result_panel.exit_pressed.connect(_on_exit)
	result_panel.continue_pressed.connect(_on_continue)
	var _input_overlay: Node = load("res://scripts/InputHintOverlay.gd").new()
	_input_overlay.setup("mouse")
	add_child(_input_overlay)
	_start_onboarding()


func _start_onboarding() -> void:
	var tut: Node = load("res://scripts/OnboardingTutorial.gd").new()
	tut.setup([
		{
			"en": "Fruits fall from above! They keep coming as you play.",
			"ar": "\u0627\u0644\u062b\u0645\u0627\u0631 \u062a\u0633\u0642\u0637 \u0645\u0646 \u0627\u0644\u0623\u0639\u0644\u0649! \u0633\u062a\u0633\u062a\u0645\u0631 \u0641\u064a \u0627\u0644\u0638\u0647\u0648\u0631 \u0637\u0648\u0627\u0644 \u0627\u0644\u0644\u0639\u0628\u0629.",
			"target": Vector2(0.5, 0.18),
			"align": "bottom"
		},
		{
			"en": "Drag each fruit into its matching basket. Barley \u2192 Barley, Wheat \u2192 Wheat, Dates \u2192 Dates.",
			"ar": "\u0627\u0633\u062d\u0628 \u0643\u0644 \u062b\u0645\u0631\u0629 \u0625\u0644\u0649 \u0633\u0644\u062a\u0647\u0627 \u0627\u0644\u0635\u062d\u064a\u062d\u0629. \u0634\u0639\u064a\u0631 \u0645\u0639 \u0634\u0639\u064a\u0631\u060c \u0642\u0645\u062d \u0645\u0639 \u0642\u0645\u062d\u060c \u062a\u0645\u0631 \u0645\u0639 \u062a\u0645\u0631.",
			"target": Vector2(0.45, 0.85),
			"align": "top"
		},
		{
			"en": "Watch out for rotten fruit \u2014 do NOT put it in any basket!",
			"ar": "\u0627\u062d\u0630\u0631 \u0645\u0646 \u0627\u0644\u062b\u0645\u0627\u0631 \u0627\u0644\u0641\u0627\u0633\u062f\u0629 \u2014 \u0644\u0627 \u062a\u0636\u0639\u0647\u0627 \u0641\u064a \u0623\u064a \u0633\u0644\u0629!",
			"target": Vector2(0.5, 0.5),
			"align": "bottom"
		},
		{
			"en": "You have 3 lives. A wrong basket or a missed fruit costs one life!",
			"ar": "\u0644\u062f\u064a\u0643 3 \u0623\u0631\u0648\u0627\u062d. \u0627\u0644\u0633\u0644\u0629 \u0627\u0644\u062e\u0637\u0623\u0629 \u0623\u0648 \u062a\u0641\u0648\u064a\u062a \u062b\u0645\u0631\u0629 \u064a\u0643\u0644\u0641\u0643 \u062d\u064a\u0627\u0629!",
			"target": Vector2(0.88, 0.07),
			"align": "bottom"
		},
	])
	add_child(tut)

func _translate_basket_labels() -> void:
	var is_ar := Global.current_locale == "ar"
	label_barley.text = "شعير" if is_ar else "Barley"
	label_wheat.text = "قمح" if is_ar else "Wheat"
	label_dates.text = "تمر" if is_ar else "Dates"
	if is_ar and Global.arabic_font != null:
		for lbl in [label_barley, label_wheat, label_dates]:
			lbl.add_theme_font_override("font", Global.arabic_font)
			lbl.add_theme_font_size_override("font_size", lbl.get_theme_font_size("font_size") + Global.ARABIC_SIZE_BONUS)
			lbl.text_direction = Control.TEXT_DIRECTION_RTL
			lbl.layout_direction = Control.LAYOUT_DIRECTION_LTR
	else:
		for lbl in [label_barley, label_wheat, label_dates]:
			lbl.text_direction = Control.TEXT_DIRECTION_LTR
			lbl.layout_direction = Control.LAYOUT_DIRECTION_LTR

func show_feedback(msg: String) -> void:
	feedback_label.text = msg
	if not feedback_timer.is_stopped():
		feedback_timer.stop()
	feedback_timer.start()

func _clear_feedback() -> void:
	feedback_label.text = ""

func update_ui() -> void:
	var total_needed: int = TARGET_PER_TYPE * 3
	var total_now: int = barley_collected + wheat_collected + dates_collected
	if Global.current_locale == "ar":
		var ts := TextServerManager.get_primary_interface()
		score_label.text = tr("Q4_HARVEST_SCORE") % [
			ts.format_number("%d" % total_now),
			ts.format_number("%d" % total_needed)
		]
		lives_label.text = tr("LIVES_LABEL") % ts.format_number("%d" % lives)
	else:
		score_label.text = tr("Q4_HARVEST_SCORE") % [total_now, total_needed]
		lives_label.text = tr("LIVES_LABEL") % lives

func _on_spawn_timer_timeout() -> void:
	if game_ended:
		return
	var types := ["barley", "wheat", "dates", "barley", "wheat", "dates", "rotten"]
	var item_type: String = types[randi() % types.size()]
	spawn_item(item_type)

func spawn_item(item_type: String) -> void:
	if game_ended:
		return

	var item = harvest_item_scene.instantiate()
	items_root.add_child(item)

	var x_pos: float = randf_range(spawn_left.global_position.x, spawn_right.global_position.x)
	var y_pos: float = spawn_left.global_position.y
	item.global_position = Vector2(x_pos, y_pos)

	var texture: Texture2D
	match item_type:
		"barley": texture = tex_barley
		"wheat":  texture = tex_wheat
		"dates":  texture = tex_dates
		"rotten": texture = tex_rotten
		_:        texture = tex_barley

	item.setup_item(item_type, texture)
	item.scale = Vector2(0.25, 0.25)
	item.dropped.connect(_on_item_dropped)

	if item.has_signal("missed"):
		item.missed.connect(_on_item_missed)
	if item.has_signal("fell_into_basket"):
		item.fell_into_basket.connect(_on_item_fell_into_basket)

func _on_item_dropped(item: Node, basket: Node) -> void:
	if game_ended:
		return

	var t: String = item.item_type
	if basket == null:
		return

	if t == "rotten":
		lives -= 1
		show_feedback(tr("Q4_SPOILED"))
		update_ui()
		check_game_over()
		return

	if not (basket is Area2D):
		return

	var accepts_type: String = basket.accepts_type

	if accepts_type == t:
		match t:
			"barley": barley_collected += 1
			"wheat":  wheat_collected += 1
			"dates":  dates_collected += 1
		if "add_correct_item" in basket:
			basket.add_correct_item()
	else:
		lives -= 1
		show_feedback(tr("Q4_WRONG_BASKET"))

	update_ui()
	check_game_over()

func _on_item_missed(item: Node) -> void:
	if game_ended:
		return
	lives -= 1
	show_feedback(tr("Q4_MISSED"))
	update_ui()
	check_game_over()

func _on_item_fell_into_basket(item, basket) -> void:
	if game_ended:
		return
	if item.item_type == "rotten":
		lives -= 1
		show_feedback(tr("Q4_SPOILED_FELL"))
		update_ui()
		check_game_over()

func check_game_over() -> void:
	if game_ended:
		return

	var total_needed: int = TARGET_PER_TYPE * 3
	var total_now: int = barley_collected + wheat_collected + dates_collected

	if total_now >= total_needed:
		game_ended = true
		spawn_timer.stop()
		show_feedback("")
		_show_result(true)
		return

	if lives <= 0:
		game_ended = true
		spawn_timer.stop()
		_show_result(false)

func _show_result(success: bool) -> void:
	# Stop all falling items
	for child in items_root.get_children():
		if child.has_method("set_process"):
			child.set_process(false)
		if child.has_method("set_physics_process"):
			child.set_physics_process(false)

	if success:
		Global.complete_quest(4)
		result_panel.show_success(tr("QUEST_COMPLETED"))
	else:
		result_panel.show_failure(tr("QUEST_FAILED"))

func _on_retry() -> void:
	get_tree().reload_current_scene()

func _on_continue() -> void:
	get_tree().change_scene_to_file("res://scenes/loading_screen.tscn")

func _on_exit() -> void:
	Global.next_scene = "res://overworld.tscn"
	get_tree().change_scene_to_file("res://scenes/loading_screen.tscn")

func _add_basket_fruit_images() -> void:
	# Use Sprite2D in world space — scale is always exact, unlike TextureRect in a CanvasLayer.
	# Basket Sprite2D centres from Seal4_Harvest.tscn.
	const BASKET_POSITIONS := [
		Vector2(262.0, 612.0),   # Barley
		Vector2(592.0, 611.0),   # Wheat
		Vector2(926.0, 612.0),   # Dates
	]
	var textures := [tex_barley, tex_wheat, tex_dates]
	# Scale so the icon is ~30 px tall regardless of source texture size.
	# Textures are roughly 350 px tall → 30 / 350 ≈ 0.086
	const TARGET_PX     := 44
	const BASKET_HALF_W := 30.0
	const GAP           := 8.0
	const LOWER         := 35.0
	const SHIFT_RIGHT   := 30.0
	for i in range(3):
		var tex: Texture2D = textures[i]
		var bpos: Vector2 = BASKET_POSITIONS[i]
		var spr := Sprite2D.new()
		spr.texture = tex
		var tex_h: float = float(tex.get_height())
		var s: float = TARGET_PX / tex_h if tex_h > 0.0 else 0.086
		spr.scale = Vector2(s, s)
		# Centre the sprite to the left of the basket
		var half_w: float = float(tex.get_width()) * s * 0.5
		spr.position = Vector2(
			bpos.x - BASKET_HALF_W - GAP - half_w + SHIFT_RIGHT,
			bpos.y + LOWER
		)
		add_child(spr)


func _apply_arabic_font_to_ui() -> void:
	if Global.current_locale != "ar" or Global.arabic_font == null:
		return
	var text_nodes: Array = [
		$UI/ScoreLabel,
		$UI/LivesLabel,
		$UI/StatusLabel,
		$UI/FeedbackLabel,
	]
	for node in text_nodes:
		if node != null and is_instance_valid(node):
			node.add_theme_font_override("font", Global.arabic_font)
			node.add_theme_font_size_override("font_size", node.get_theme_font_size("font_size") + Global.ARABIC_SIZE_BONUS)
			if node is Label:
				node.text_direction = Control.TEXT_DIRECTION_RTL
				node.layout_direction = Control.LAYOUT_DIRECTION_LTR
