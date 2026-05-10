extends Node2D

@onready var active_quest_label: Label = $CanvasLayer/HeaderBar/ActiveQuest
@onready var seal_count_label: Label = $CanvasLayer/HeaderBar/SealCount
@onready var start_quest_label: Label = $CanvasLayer/StartQuest
@onready var player_spawn: Marker2D = $PlayerSpawn
@onready var quest_locations: Array[Sprite2D] = [
	$Quest1Location,
	$Quest2Location,
	$Quest3Location,
	$Quest4Location,
	$Quest5Location,
	$Quest6Location,
]

const PROXIMITY_DISTANCE = 200.0
const QUEST_KEYS := {
	1: "QUEST_1_NAME",
	2: "QUEST_2_NAME",
	3: "QUEST_3_NAME",
	4: "QUEST_4_NAME",
	5: "QUEST_5_NAME",
	6: "QUEST_6_NAME",
}
const QUEST_SCENES := {
	1: "res://scenes/Quest1_Water_MapTracing.tscn",
	2: "res://scenes/Quest2_Earth.tscn",
	3: "res://scenes/Quest3_Pearls.tscn",
	4: "res://scenes/Seal4_Harvest.tscn",
	5: "res://scenes/Quest5_Unity.tscn",
	6: "res://scenes/Quest6_Memory.tscn",
}

const FAISAL_SCENE = preload("res://characters/faisal/faisal.tscn")
const DINA_SCENE   = preload("res://characters/dina/dina.tscn")

var near_quest_index := 0
var player: CharacterBody2D = null
var quiz_active := false
var last_player_position := Vector2.ZERO
var _active_hint_panel: Node = null

func _ready() -> void:
	_spawn_player()
	TranslationServer.set_locale(Global.current_locale)
	_apply_arabic_font_to_ui()
	_update_ui()
	_update_location_visuals()
	start_quest_label.visible = false
	start_quest_label.add_theme_font_size_override("font_size", 36)
	start_quest_label.add_theme_constant_override("outline_size", 2)
	start_quest_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_save_progress()
	if Global.pending_quiz_for_quest > 0:
		await get_tree().create_timer(0.5).timeout
		_launch_narrator_quiz()
	elif not Global.tutorial_done:
		_start_tutorial()
	elif Global.hint_shown_for_quest < Global.quest_index and Global.quest_index <= 6:
		_maybe_show_quest_hint()

func _spawn_player() -> void:
	var character := Global.player_character
	if character == "":
		character = "faisal"
	var packed: PackedScene
	match character:
		"dina": packed = DINA_SCENE
		_:      packed = FAISAL_SCENE
	player = packed.instantiate()
	player.global_position = player_spawn.global_position
	add_child(player)
	last_player_position = player.global_position

func _process(_delta: float) -> void:
	if player == null or quiz_active:
		return
	if player.global_position.distance_to(last_player_position) > 5.0:
		last_player_position = player.global_position
		_check_quest_proximity()

func _check_quest_proximity() -> void:
	near_quest_index = 0
	start_quest_label.visible = false
	for i in range(quest_locations.size()):
		var quest_num := i + 1
		var location_sprite: Sprite2D = quest_locations[i]
		var distance := player.global_position.distance_to(location_sprite.global_position)
		if distance <= PROXIMITY_DISTANCE:
			var key := "quest%d" % quest_num
			var is_completed: bool = Global.completed_quests.get(key, false)
			var is_active := (quest_num == Global.quest_index)
			var is_locked := (quest_num > Global.quest_index)
			if is_completed:
				start_quest_label.visible = true
				start_quest_label.text = tr("QUEST_COMPLETED_LABEL") % tr(QUEST_KEYS.get(quest_num, "QUEST_FALLBACK"))
				near_quest_index = 0
			elif is_active:
				start_quest_label.visible = true
				start_quest_label.text = tr("PRESS_E_TO_START") % tr(QUEST_KEYS.get(quest_num, "QUEST_FALLBACK"))
				near_quest_index = quest_num
				if _active_hint_panel != null and is_instance_valid(_active_hint_panel):
					_active_hint_panel.call("on_quest_found")
					_active_hint_panel = null
			elif is_locked:
				start_quest_label.visible = false
				near_quest_index = 0
			break

func _update_location_visuals() -> void:
	for i in range(quest_locations.size()):
		var quest_num := i + 1
		var location_sprite: Sprite2D = quest_locations[i]
		var key := "quest%d" % quest_num
		var is_completed: bool = Global.completed_quests.get(key, false)
		if is_completed:
			location_sprite.modulate = Color(1.0, 1.0, 1.0, 1.0)
		else:
			location_sprite.modulate = Color(0.4, 0.4, 0.4, 1.0)

func _update_ui() -> void:
	var all_done := (Global.seal_count >= 6) or (Global.quest_index > 6)
	if all_done:
		active_quest_label.text = tr("ALL_QUESTS_COMPLETED")
		seal_count_label.text = tr("SEALS_MAX")
		start_quest_label.text = tr("THE_END")
		start_quest_label.visible = true
		_update_location_visuals()
		return
	var q := Global.quest_index
	active_quest_label.text = tr(QUEST_KEYS.get(q, "ALL_QUESTS_COMPLETED"))
	if Global.current_locale == "ar":
		var ts := TextServerManager.get_primary_interface()
		var formatted_count := ts.format_number("%d" % Global.seal_count)
		var formatted_total := ts.format_number("6")
		seal_count_label.text = "الأختام: %s/%s" % [formatted_count, formatted_total]
	else:
		seal_count_label.text = tr("SEALS_COUNT") % Global.seal_count
	_update_location_visuals()

func _save_progress() -> void:
	if Global.current_save_slot > 0:
		SaveManager.save_game(Global.current_save_slot)

func _unhandled_input(event: InputEvent) -> void:
	if quiz_active:
		return
	if Input.is_action_just_pressed("interact") and near_quest_index > 0:
		if QUEST_SCENES.has(near_quest_index):
			get_tree().change_scene_to_file(QUEST_SCENES[near_quest_index])

func _launch_narrator_quiz() -> void:
	var quiz := $NarratorQuiz
	if quiz == null:
		push_error("Overworld: NarratorQuiz node not found.")
		return
	quiz_active = true
	if player != null:
		player.set_process(false)
		player.set_physics_process(false)
	quiz.start_quiz(Global.pending_quiz_for_quest)

func _on_narrator_quiz_finished() -> void:
	quiz_active = false
	if player != null:
		player.set_process(true)
		player.set_physics_process(true)
	_update_ui()
	_save_progress()
	# Quest 6 just passed — play the outro video
	if Global.quest_index > 6:
		await get_tree().create_timer(0.8).timeout
		get_tree().change_scene_to_file("res://scenes/OutroVideo.tscn")
	elif Global.hint_shown_for_quest < Global.quest_index and Global.quest_index <= 6:
		_maybe_show_quest_hint()

func _start_tutorial() -> void:
	var tut_script := load("res://scripts/OverworldTutorial.gd")
	var tutorial : Node = tut_script.new()
	tutorial.call("init", player)
	add_child(tutorial)
	tutorial.connect("tutorial_finished", _on_tutorial_finished)


func _on_tutorial_finished() -> void:
	Global.tutorial_done = true
	_maybe_show_quest_hint()


func _maybe_show_quest_hint() -> void:
	var q := Global.quest_index
	if q > 6 or Global.hint_shown_for_quest >= q:
		return
	Global.hint_shown_for_quest = q

	if _active_hint_panel != null and is_instance_valid(_active_hint_panel):
		_active_hint_panel.queue_free()
		_active_hint_panel = null
	var quest_world_pos := Vector2.ZERO
	var idx := q - 1
	if idx >= 0 and idx < quest_locations.size():
		quest_world_pos = quest_locations[idx].global_position

	var panel_script := load("res://scripts/QuestHintPanel.gd")
	var panel : Node = panel_script.new()
	panel.call("setup", q, quest_world_pos, player)
	add_child(panel)
	_active_hint_panel = panel


func _apply_arabic_font_to_ui() -> void:
	if Global.current_locale != "ar" or Global.arabic_font == null:
		return
	var text_nodes: Array = [
		$CanvasLayer/HeaderBar/ActiveQuest,
		$CanvasLayer/HeaderBar/SealCount,
		$CanvasLayer/StartQuest,
	]
	for node in text_nodes:
		if node != null and is_instance_valid(node):
			node.add_theme_font_override("font", Global.arabic_font)
			if node is Label:
				node.text_direction = Control.TEXT_DIRECTION_RTL
				node.layout_direction = Control.LAYOUT_DIRECTION_LTR
