extends Node2D

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

@onready var result_panel: Control = $UI/ResultPanel
@onready var result_label: Label = $UI/ResultPanel/MessageLabel
@onready var retry_button: Button = $UI/ResultPanel/RetryButton

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
	randomize()

	tex_barley = load("res://assets/sprites/harvest_barley.png")
	tex_wheat = load("res://assets/sprites/harvest_wheat.png")
	tex_dates = load("res://assets/sprites/harvest_dates.png")
	tex_rotten = load("res://assets/sprites/harvest_rotten.png")

	if harvest_item_scene == null:
		harvest_item_scene = load("res://scenes/objects/HarvestItem.tscn")

	update_ui()
	feedback_label.text = ""
	feedback_timer = Timer.new()
	feedback_timer.wait_time = 2.0
	feedback_timer.one_shot = true
	add_child(feedback_timer)
	feedback_timer.timeout.connect(_clear_feedback)

	spawn_timer.timeout.connect(_on_spawn_timer_timeout)

	result_panel.visible = false
	retry_button.visible = false
	retry_button.pressed.connect(_on_retry_pressed)

func show_feedback(msg: String) -> void:
	feedback_label.text = msg
	if feedback_timer.is_stopped() == false:
		feedback_timer.stop()
	feedback_timer.start()

func _clear_feedback() -> void:
	feedback_label.text = ""

func update_ui() -> void:
	var total_needed: int = TARGET_PER_TYPE * 3
	var total_now: int = barley_collected + wheat_collected + dates_collected
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
	result_panel.visible = true

	for child in items_root.get_children():
		if child.has_method("set_process"):
			child.set_process(false)
		if child.has_method("set_physics_process"):
			child.set_physics_process(false)

	if success:
		result_label.text = tr("QUEST_COMPLETED")
		retry_button.visible = false

		Global.complete_quest(4)
		await get_tree().create_timer(1.2).timeout
		Global.next_scene = "res://overworld.tscn"
		get_tree().change_scene_to_file("res://scenes/loading_screen.tscn")
	else:
		result_label.text = tr("QUEST_FAILED")
		retry_button.visible = true

func _on_retry_pressed() -> void:
	get_tree().reload_current_scene()
