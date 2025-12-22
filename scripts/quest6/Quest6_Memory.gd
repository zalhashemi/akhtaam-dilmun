extends Node2D
class_name Quest6_Memory

@onready var dialog: DialogBox = $UI/DialogBox

# NEW: full-screen dimmer behind overlay (ColorRect under UI CanvasLayer)
@onready var dimmer: ColorRect = $UI/Dimmer

@onready var completion_overlay: Control = $UI/CompletionOverlay
@onready var final_seal: AnimatedSprite2D = $UI/CompletionOverlay/CenterContainer/VBox/FinalSeal
@onready var result_label: Label = $UI/CompletionOverlay/CenterContainer/VBox/ResultLabel
@onready var score_label: Label = $UI/CompletionOverlay/CenterContainer/VBox/ScoreLabel
@onready var retry_btn: Button = $UI/CompletionOverlay/CenterContainer/VBox/RetryBtn

const TOTAL_SEALS := 5
const PASS_MIN_CORRECT := 4  # 3/5 or less fails, so pass needs 4+

var expected_index := 0
var locked_count := 0
var correct_count := 0

var QUESTIONS := {
	"water": {
		"question": "Why is water still a precious resource in Bahrain today?",
		"options": [
			"Because Bahrain has many natural rivers",
			"Because Bahrain depends on desalination and must conserve water",
			"Because water is only used for farming",
			"Because rainfall is constant all year"
		],
		"correct": 1,
		"explain": "Bahrain relies heavily on desalination, so conserving water is important."
	},
	"earth": {
		"question": "How do historical sites and artifacts help Bahrain today?",
		"options": [
			"They are only useful for tourists",
			"They preserve national identity and educate future generations",
			"They replace modern buildings",
			"They are no longer relevant"
		],
		"correct": 1,
		"explain": "Heritage sites and museums preserve identity and support learning."
	},
	"pearls": {
		"question": "Why are pearls important in Bahrain’s history?",
		"options": [
			"They were used mainly for decoration",
			"They were discovered after oil",
			"Pearl diving was Bahrain’s main economy before oil",
			"Pearls were imported from other countries"
		],
		"correct": 2,
		"explain": "Pearling shaped Bahrain’s economy and culture long before oil."
	},
	"harvest": {
		"question": "How do Bahrainis honor tradition while embracing modern life?",
		"options": [
			"By rejecting technology",
			"By preserving traditions while using modern tools and education",
			"By forgetting old customs",
			"By only focusing on the past"
		],
		"correct": 1,
		"explain": "Modern progress can happen while respecting and celebrating traditions."
	},
	"unity": {
		"question": "Why is cooperation important in Bahraini society today?",
		"options": [
			"It reduces competition",
			"It strengthens community and shared national values",
			"It slows development",
			"It is only important in history"
		],
		"correct": 1,
		"explain": "Unity supports community strength and shared progress."
	}
}

func _ready() -> void:
	dialog.hide()

	# start hidden
	dimmer.visible = false
	completion_overlay.visible = false
	final_seal.visible = false
	retry_btn.visible = false

	retry_btn.pressed.connect(_on_retry_pressed)
	dialog.answered.connect(_on_dialog_answered)

	# Connect seals
	for child in $Seals.get_children():
		if child is Seal:
			(child as Seal).dropped.connect(_on_seal_dropped)

	_reset_state()

func _reset_state() -> void:
	expected_index = 0
	locked_count = 0
	correct_count = 0

	dimmer.visible = false
	completion_overlay.visible = false
	final_seal.visible = false
	retry_btn.visible = false
	result_label.text = ""
	score_label.text = ""

func _clean_id(id: String) -> String:
	var s := id.strip_edges()
	s = s.replace('"', "")
	s = s.replace("'", "")
	return s

func _on_seal_dropped(seal: Seal) -> void:
	# Block dragging during dialog or result screen
	if dialog.visible or completion_overlay.visible:
		seal.return_to_start()
		return

	# Must place in correct order
	if seal.order_index != expected_index:
		seal.return_to_start()
		return

	# Must be dropped onto matching slot
	var slot := _get_matching_slot_under(seal)
	if slot == null:
		seal.return_to_start()
		return

	# Lock + spin
	seal.lock_to(slot.global_position)

	locked_count += 1
	expected_index += 1

	# Ask question
	var sid := _clean_id(seal.seal_id)
	if not QUESTIONS.has(sid):
		push_error("No question found for seal_id: " + sid + " (raw: " + seal.seal_id + ")")
		return

	dialog.show_question(QUESTIONS[sid])

func _get_matching_slot_under(seal: Seal) -> Slot:
	var overlapping := seal.get_overlapping_areas()
	for a in overlapping:
		if a is Slot:
			var s := a as Slot
			if s.seal_id == seal.seal_id:
				return s
	return null

func _on_dialog_answered(is_correct: bool) -> void:
	if is_correct:
		correct_count += 1

	# last seal answered -> hide dialog automatically, then show overlay + dimmer
	if locked_count >= TOTAL_SEALS:
		dialog.hide()
		await get_tree().process_frame
		_finish_quest()

func _finish_quest() -> void:
	# Dim the whole scene to ~80% brightness
	# (Make sure Dimmer is Full Rect + alpha 0.2)
	dimmer.visible = true

	# Show overlay contents on top
	completion_overlay.visible = true
	score_label.text = "Score: %d/%d" % [correct_count, TOTAL_SEALS]

	if correct_count >= PASS_MIN_CORRECT:
		result_label.text = "Quest Completed"
		retry_btn.visible = false

		final_seal.visible = true
		final_seal.play("spin")
	else:
		result_label.text = "Quest Failed"
		final_seal.visible = false
		retry_btn.visible = true

func _on_retry_pressed() -> void:
	get_tree().reload_current_scene()
