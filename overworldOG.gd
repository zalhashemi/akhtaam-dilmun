extends Node2D

@onready var active_quest_label: Label = $ActiveQuest
@onready var seal_count_label: Label = $SealCount
@onready var start_quest_label: Label = $StartQuest
@onready var player: CharacterBody2D = $Player

@onready var quest_locations: Array[Sprite2D] = [
	$Quest1Location,
	$Quest2Location,
	$Quest3Location,
	$Quest4Location,
	$Quest5Location,
	$Quest6Location,
]

const PROXIMITY_DISTANCE = 200.0

const QUEST_NAMES := {
	1: "Quest 1: Water",
	2: "Quest 2: Earth",
	3: "Quest 3: Pearls",
	4: "Quest 4: Harvest",
	5: "Quest 5: Unity",
	6: "Quest 6: Memory",
}

const QUEST_SCENES := {
	1: "res://scenes/Quest1_Water_MapTracing.tscn",
	2: "res://scenes/Quest2_Earth.tscn",
	3: "res://scenes/Quest3_Pearls.tscn",
	4: "res://scenes/Seal4_Harvest.tscn",
	5: "res://scenes/Quest5_Unity.tscn",
	6: "res://scenes/Quest6_Memory.tscn",
}

# Tracks which quest location the player is currently near (1–6), or 0 if none
var near_quest_index := 0

func _ready() -> void:
	_update_ui()
	_update_location_visuals()
	start_quest_label.visible = false

func _process(_delta: float) -> void:
	_check_quest_proximity()

func _check_quest_proximity() -> void:
	near_quest_index = 0
	start_quest_label.visible = false

	for i in range(quest_locations.size()):
		var quest_num := i + 1  # Quest numbers are 1–6
		var location_sprite: Sprite2D = quest_locations[i]
		var distance := player.global_position.distance_to(location_sprite.global_position)

		if distance <= PROXIMITY_DISTANCE:
			var key := "quest%d" % quest_num
			var is_completed: bool = Global.completed_quests.get(key, false)
			var is_active := (quest_num == Global.quest_index)
			var is_locked := (quest_num > Global.quest_index)

			if is_completed:
				# Show "Completed" label but don't allow re-entry
				start_quest_label.visible = true
				start_quest_label.text = "%s — Completed ✓" % QUEST_NAMES.get(quest_num, "Quest %d" % quest_num)
				near_quest_index = 0  # Can't interact with completed quests
			elif is_active:
				# This is the next quest to play
				start_quest_label.visible = true
				start_quest_label.text = "Press E to start %s" % QUEST_NAMES.get(quest_num, "Quest %d" % quest_num)
				near_quest_index = quest_num
			elif is_locked:
				# Don't show anything for locked quests
				start_quest_label.visible = false
				near_quest_index = 0

			# Only respond to the closest/first found location
			break

func _update_location_visuals() -> void:
	for i in range(quest_locations.size()):
		var quest_num := i + 1
		var location_sprite: Sprite2D = quest_locations[i]
		var key := "quest%d" % quest_num
		var is_completed: bool = Global.completed_quests.get(key, false)

		if is_completed:
			# Full color for completed quests
			location_sprite.modulate = Color(1.0, 1.0, 1.0, 1.0)
		else:
			# Grayscale for locked or active-but-not-yet-completed quests
			location_sprite.modulate = Color(0.4, 0.4, 0.4, 1.0)

func _update_ui() -> void:
	var all_done := (Global.seal_count >= 6) or (Global.quest_index > 6)
	if all_done:
		active_quest_label.text = "All quests completed"
		seal_count_label.text = "Seals: 6/6"
		start_quest_label.text = "The End"
		start_quest_label.visible = true
		_update_location_visuals()
		return

	var q := Global.quest_index
	active_quest_label.text = QUEST_NAMES.get(q, "All quests completed")
	seal_count_label.text = "Seals: %d/6" % Global.seal_count
	_update_location_visuals()

func _unhandled_input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("interact") and near_quest_index > 0:
		if QUEST_SCENES.has(near_quest_index):
			get_tree().change_scene_to_file(QUEST_SCENES[near_quest_index])
