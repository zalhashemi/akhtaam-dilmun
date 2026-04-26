extends Node2D

const _InstructionPanel = preload("res://scripts/InstructionPanel.gd")

@onready var dialog: DialogBox = $UI/DialogBox
@onready var dimmer: ColorRect = $UI/Dimmer
@onready var result_panel: CanvasLayer = $QuestResultPanel

const TOTAL_SEALS := 5
const PASS_MIN_CORRECT := 4

var finished := false
var expected_index := 0
var locked_count := 0
var correct_count := 0

var QUESTIONS := {}


func _ready() -> void:
	_build_questions()
	dialog.hide()
	dimmer.visible = false
	result_panel.retry_pressed.connect(_on_retry)
	result_panel.exit_pressed.connect(_on_exit)
	result_panel.continue_pressed.connect(_on_continue)
	dialog.answered.connect(_on_dialog_answered)
	for child in $Seals.get_children():
		if child is Seal:
			(child as Seal).dropped.connect(_on_seal_dropped)
	_apply_arabic_font_to_ui()
	_translate_slot_labels()
	_reset_state()
	var _input_overlay: Node = load("res://scripts/InputHintOverlay.gd").new()
	_input_overlay.setup("mouse")
	add_child(_input_overlay)
	_start_onboarding()


func _start_onboarding() -> void:
	var tut: Node = load("res://scripts/OnboardingTutorial.gd").new()
	tut.setup([
		{
			"en": "These are the 5 Seals — each one represents a quest you have completed.",
			"ar": "\u0647\u0630\u0647 \u0647\u064a \u0627\u0644\u0623\u062e\u062a\u0627\u0645 \u0627\u0644\u062e\u0645\u0633\u0629 \u2014 \u0643\u0644 \u062e\u062a\u0645 \u064a\u0645\u062b\u0644 \u0645\u0647\u0645\u0629 \u0623\u0643\u0645\u0644\u062a\u0647\u0627.",
			"target": Vector2(0.76, 0.68),
			"align": "top"
		},
		{
			"en": "Drag each seal to its matching numbered slot on the left.",
			"ar": "\u0627\u0633\u062d\u0628 \u0643\u0644 \u062e\u062a\u0645 \u0625\u0644\u0649 \u062e\u0627\u0646\u062a\u0647 \u0627\u0644\u0645\u0631\u0642\u0645\u0629 \u0639\u0644\u0649 \u0627\u0644\u064a\u0633\u0627\u0631.",
			"target": Vector2(0.22, 0.42),
			"align": "right"
		},
		{
			"en": "After each drop, a question appears — answer it to confirm your choice!",
			"ar": "\u0628\u0639\u062f \u0643\u0644 \u0625\u0633\u0642\u0627\u0637 \u062a\u0638\u0647\u0631 \u0645\u0633\u0623\u0644\u0629 \u2014 \u0623\u062c\u0628 \u0639\u0644\u064a\u0647\u0627 \u0644\u062a\u0623\u0643\u064a\u062f \u0627\u062e\u062a\u064a\u0627\u0631\u0643!",
			"target": Vector2(0.5, 0.5),
			"align": "bottom"
		},
	])
	add_child(tut)


func _build_questions() -> void:
	QUESTIONS = {
		"water": {
			"question": tr("Q6_WATER_Q"),
			"options": [tr("Q6_WATER_A"), tr("Q6_WATER_B"), tr("Q6_WATER_C"), tr("Q6_WATER_D")],
			"correct": 1,
			"explain": tr("Q6_WATER_EXPLAIN")
		},
		"earth": {
			"question": tr("Q6_EARTH_Q"),
			"options": [tr("Q6_EARTH_A"), tr("Q6_EARTH_B"), tr("Q6_EARTH_C"), tr("Q6_EARTH_D")],
			"correct": 1,
			"explain": tr("Q6_EARTH_EXPLAIN")
		},
		"pearls": {
			"question": tr("Q6_PEARLS_Q"),
			"options": [tr("Q6_PEARLS_A"), tr("Q6_PEARLS_B"), tr("Q6_PEARLS_C"), tr("Q6_PEARLS_D")],
			"correct": 2,
			"explain": tr("Q6_PEARLS_EXPLAIN")
		},
		"harvest": {
			"question": tr("Q6_HARVEST_Q"),
			"options": [tr("Q6_HARVEST_A"), tr("Q6_HARVEST_B"), tr("Q6_HARVEST_C"), tr("Q6_HARVEST_D")],
			"correct": 1,
			"explain": tr("Q6_HARVEST_EXPLAIN")
		},
		"unity": {
			"question": tr("Q6_UNITY_Q"),
			"options": [tr("Q6_UNITY_A"), tr("Q6_UNITY_B"), tr("Q6_UNITY_C"), tr("Q6_UNITY_D")],
			"correct": 1,
			"explain": tr("Q6_UNITY_EXPLAIN")
		}
	}


func _translate_slot_labels() -> void:
	var is_ar := Global.current_locale == "ar"

	# Numbered English labels
	var slot_names_en := {
		"Slot_Water":   "1. Water",
		"Slot_Earth":   "2. Earth",
		"Slot_Pearls":  "3. Pearls",
		"Slot_Harvest": "4. Harvest",
		"Slot_Unity":   "5. Unity",
	}
	# Numbered Arabic labels (Arabic-Indic numerals ١٢٣٤٥)
	var slot_names_ar := {
		"Slot_Water":   "\u0661. \u0627\u0644\u0645\u0627\u0621",
		"Slot_Earth":   "\u0662. \u0627\u0644\u0623\u0631\u0636",
		"Slot_Pearls":  "\u0663. \u0627\u0644\u0644\u0624\u0644\u0624",
		"Slot_Harvest": "\u0664. \u0627\u0644\u062d\u0635\u0627\u062f",
		"Slot_Unity":   "\u0665. \u0627\u0644\u0648\u062d\u062f\u0629",
	}

	const BASE_SIZE := 20

	for slot in $Slots.get_children():
		var label := slot.get_node_or_null("SlotLabel")
		if label == null:
			continue

		# Shared styling — outline and position shift
		label.add_theme_constant_override("outline_size", 4)
		label.add_theme_color_override("font_outline_color", Color.BLACK)
		label.position.x -= 20

		if is_ar:
			label.text = slot_names_ar.get(slot.name, slot.name)
			label.add_theme_font_size_override("font_size", BASE_SIZE + Global.ARABIC_SIZE_BONUS)
			if Global.arabic_font != null:
				label.add_theme_font_override("font", Global.arabic_font)
			label.text_direction   = Control.TEXT_DIRECTION_RTL
			label.layout_direction = Control.LAYOUT_DIRECTION_LTR
		else:
			label.text = slot_names_en.get(slot.name, slot.name)
			label.add_theme_font_size_override("font_size", BASE_SIZE)
			label.text_direction   = Control.TEXT_DIRECTION_LTR
			label.layout_direction = Control.LAYOUT_DIRECTION_LTR


func _apply_arabic_font_to_ui() -> void:
	pass


func _reset_state() -> void:
	finished       = false
	expected_index = 0
	locked_count   = 0
	correct_count  = 0
	dimmer.visible = false


func _clean_id(id: String) -> String:
	var s := id.strip_edges()
	s = s.replace('"', "")
	s = s.replace("'", "")
	return s


func _on_seal_dropped(seal: Seal) -> void:
	if dialog.visible or result_panel.panel.visible:
		seal.return_to_start()
		return

	if seal.order_index != expected_index:
		seal.return_to_start()
		return

	var slot := _get_matching_slot_under(seal)
	if slot == null:
		seal.return_to_start()
		return

	seal.lock_to(slot.global_position)
	locked_count   += 1
	expected_index += 1

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
	if locked_count >= TOTAL_SEALS:
		dialog.hide()
		await get_tree().process_frame
		_finish_quest()


func _finish_quest() -> void:
	if finished:
		return
	finished = true

	dimmer.visible = true

	var score_text: String
	if Global.current_locale == "ar":
		var ts := TextServerManager.get_primary_interface()
		score_text = tr("SCORE_LABEL") % [
			ts.format_number("%d" % correct_count),
			ts.format_number("%d" % TOTAL_SEALS)
		]
	else:
		score_text = tr("SCORE_LABEL") % [correct_count, TOTAL_SEALS]

	if correct_count >= PASS_MIN_CORRECT:
		Global.complete_quest(6)
		result_panel.show_success(tr("QUEST_COMPLETED_ALT") + "\n" + score_text)
	else:
		finished = false
		result_panel.show_failure(tr("QUEST_FAILED") + "\n" + score_text)


func _on_retry() -> void:
	get_tree().reload_current_scene()


func _on_continue() -> void:
	get_tree().change_scene_to_file("res://scenes/loading_screen.tscn")


func _on_exit() -> void:
	Global.next_scene = "res://overworld.tscn"
	get_tree().change_scene_to_file("res://scenes/loading_screen.tscn")
