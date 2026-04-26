extends Node2D

const _InstructionPanel = preload("res://scripts/InstructionPanel.gd")

const PASS_PERCENTAGE := 0.6667
const TYPE_SPEED := 0.06
const FEEDBACK_PAUSE := 0.8

@onready var npc_bust: AnimatedSprite2D = $NpcBust
@onready var dialogue_label: Label = $UI/DialogRoot/DialogPanel/MarginContainer/DialogVBox/DialogueLabel
@onready var choice_button_1: Button = $UI/DialogRoot/DialogPanel/MarginContainer/DialogVBox/ChoicesHBox/ChoiceButton1
@onready var choice_button_2: Button = $UI/DialogRoot/DialogPanel/MarginContainer/DialogVBox/ChoicesHBox/ChoiceButton2
@onready var progress_label: Label = $UI/DialogRoot/DialogPanel/MarginContainer/DialogVBox/ProgressLabel
@onready var choices_hbox: HBoxContainer = $UI/DialogRoot/DialogPanel/MarginContainer/DialogVBox/ChoicesHBox
@onready var result_panel: CanvasLayer = $QuestResultPanel

var finished := false
var questions: Array = []
var current_index: int = 0
var correct_count: int = 0
var typing: bool = false
var rng := RandomNumberGenerator.new()
var _next_btn: Button = null

const NPC_NAMES_AR := {
	"Merchant": "التاجر",
	"Fisherman": "الصياد",
	"Storyteller": "الراوي"
}

func _get_npc_display_name(npc_key: String) -> String:
	if Global.current_locale == "ar":
		return NPC_NAMES_AR.get(npc_key, npc_key)
	return npc_key

var feedback_correct := {}
var feedback_wrong := {}

func _build_feedback_pools() -> void:
	feedback_correct = {
		"Merchant": [
			tr("Q5_CM_1"), tr("Q5_CM_2"), tr("Q5_CM_3"), tr("Q5_CM_4"),
			tr("Q5_CM_5"), tr("Q5_CM_6"), tr("Q5_CM_7"), tr("Q5_CM_8")
		],
		"Fisherman": [
			tr("Q5_CF_1"), tr("Q5_CF_2"), tr("Q5_CF_3"), tr("Q5_CF_4"),
			tr("Q5_CF_5"), tr("Q5_CF_6"), tr("Q5_CF_7"), tr("Q5_CF_8")
		],
		"Storyteller": [
			tr("Q5_CS_1"), tr("Q5_CS_2"), tr("Q5_CS_3"), tr("Q5_CS_4"),
			tr("Q5_CS_5"), tr("Q5_CS_6"), tr("Q5_CS_7"), tr("Q5_CS_8")
		]
	}
	feedback_wrong = {
		"Merchant": [
			tr("Q5_WM_1"), tr("Q5_WM_2"), tr("Q5_WM_3"), tr("Q5_WM_4"),
			tr("Q5_WM_5"), tr("Q5_WM_6"), tr("Q5_WM_7"), tr("Q5_WM_8")
		],
		"Fisherman": [
			tr("Q5_WF_1"), tr("Q5_WF_2"), tr("Q5_WF_3"), tr("Q5_WF_4"),
			tr("Q5_WF_5"), tr("Q5_WF_6"), tr("Q5_WF_7"), tr("Q5_WF_8")
		],
		"Storyteller": [
			tr("Q5_WS_1"), tr("Q5_WS_2"), tr("Q5_WS_3"), tr("Q5_WS_4"),
			tr("Q5_WS_5"), tr("Q5_WS_6"), tr("Q5_WS_7"), tr("Q5_WS_8")
		]
	}

func _ready() -> void:
	rng.randomize()
	choices_hbox.visible = false
	result_panel.retry_pressed.connect(_on_retry)
	result_panel.exit_pressed.connect(_on_exit)
	result_panel.continue_pressed.connect(_on_continue)
	_build_feedback_pools()
	# Set font sizes explicitly so they survive any Global font-strip pass
	_apply_base_font_sizes()
	_apply_arabic_font_to_ui()
	_setup_questions()
	_connect_buttons()
	_create_next_button()
	var _input_overlay: Node = load("res://scripts/InputHintOverlay.gd").new()
	_input_overlay.setup("mouse")
	add_child(_input_overlay)
	_start_onboarding()


func _start_onboarding() -> void:
	var tut: Node = load("res://scripts/OnboardingTutorial.gd").new()
	tut.setup([
		{
			"en": "A character will appear and ask you a question — read it carefully!",
			"ar": "\u0633\u062a\u0638\u0647\u0631 \u0634\u062e\u0635\u064a\u0629 \u0648\u062a\u0637\u0631\u062d \u0639\u0644\u064a\u0643 \u0633\u0624\u0627\u0644\u0627\u064b \u2014 \u0627\u0642\u0631\u0623\u0647 \u0628\u0639\u0646\u0627\u064a\u0629!",
			"target": Vector2(0.5, 0.32),
			"align": "bottom"
		},
		{
			"en": "Click one of these two buttons to give your answer.",
			"ar": "\u0627\u0636\u063a\u0637 \u0639\u0644\u0649 \u0623\u062d\u062f \u0627\u0644\u0632\u0631\u064a\u0646 \u0644\u062a\u0642\u062f\u064a\u0645 \u0625\u062c\u0627\u0628\u062a\u0643.",
			"target": Vector2(0.5, 0.72),
			"align": "top"
		},
		{
			"en": "Answer at least 6 out of 9 questions correctly to win the seal!",
			"ar": "\u0623\u062c\u0628 \u0639\u0644\u0649 \u0666 \u0645\u0646 \u0623\u0635\u0644 \u0669 \u0623\u0633\u0626\u0644\u0629 \u0635\u062d\u064a\u062d\u0629 \u0644\u0644\u0641\u0648\u0632 \u0628\u0627\u0644\u062e\u062a\u0645!",
			"target": Vector2(0.5, 0.5),
			"align": "bottom"
		},
	])
	tut.tutorial_done.connect(_show_current_question)
	add_child(tut)

func _connect_buttons() -> void:
	choice_button_1.pressed.connect(_on_choice_1_pressed)
	choice_button_2.pressed.connect(_on_choice_2_pressed)

func _setup_questions() -> void:
	questions = [
		{
			"npc": "Merchant",
			"animation_idle": "merchant_idle",
			"animation_talk": "merchant_talk",
			"prompt": tr("Q5_Q1_PROMPT"),
			"choices": [tr("Q5_Q1_A"), tr("Q5_Q1_B")],
			"correct": 0
		},
		{
			"npc": "Merchant",
			"animation_idle": "merchant_idle",
			"animation_talk": "merchant_talk",
			"prompt": tr("Q5_Q2_PROMPT"),
			"choices": [tr("Q5_Q2_A"), tr("Q5_Q2_B")],
			"correct": 1
		},
		{
			"npc": "Merchant",
			"animation_idle": "merchant_idle",
			"animation_talk": "merchant_talk",
			"prompt": tr("Q5_Q3_PROMPT"),
			"choices": [tr("Q5_Q3_A"), tr("Q5_Q3_B")],
			"correct": 0
		},
		{
			"npc": "Fisherman",
			"animation_idle": "fisherman_idle",
			"animation_talk": "fisherman_talk",
			"prompt": tr("Q5_Q4_PROMPT"),
			"choices": [tr("Q5_Q4_A"), tr("Q5_Q4_B")],
			"correct": 0
		},
		{
			"npc": "Fisherman",
			"animation_idle": "fisherman_idle",
			"animation_talk": "fisherman_talk",
			"prompt": tr("Q5_Q5_PROMPT"),
			"choices": [tr("Q5_Q5_A"), tr("Q5_Q5_B")],
			"correct": 0
		},
		{
			"npc": "Fisherman",
			"animation_idle": "fisherman_idle",
			"animation_talk": "fisherman_talk",
			"prompt": tr("Q5_Q6_PROMPT"),
			"choices": [tr("Q5_Q6_A"), tr("Q5_Q6_B")],
			"correct": 1
		},
		{
			"npc": "Storyteller",
			"animation_idle": "storyteller_idle",
			"animation_talk": "storyteller_talk",
			"prompt": tr("Q5_Q7_PROMPT"),
			"choices": [tr("Q5_Q7_A"), tr("Q5_Q7_B")],
			"correct": 0
		},
		{
			"npc": "Storyteller",
			"animation_idle": "storyteller_idle",
			"animation_talk": "storyteller_talk",
			"prompt": tr("Q5_Q8_PROMPT"),
			"choices": [tr("Q5_Q8_A"), tr("Q5_Q8_B")],
			"correct": 0
		},
		{
			"npc": "Storyteller",
			"animation_idle": "storyteller_idle",
			"animation_talk": "storyteller_talk",
			"prompt": tr("Q5_Q9_PROMPT"),
			"choices": [tr("Q5_Q9_A"), tr("Q5_Q9_B")],
			"correct": 0
		},
	]

func _show_current_question() -> void:
	choices_hbox.visible = false

	if current_index >= questions.size():
		_finish_quiz()
		return

	var q: Dictionary = questions[current_index]
	var display_name := _get_npc_display_name(str(q["npc"]))

	# Set button text and progress label before typing starts
	choice_button_1.text = str(q["choices"][0])
	choice_button_2.text = str(q["choices"][1])
	if Global.current_locale == "ar":
		var ts := TextServerManager.get_primary_interface()
		progress_label.text = tr("QUESTION_PROGRESS") % [
			ts.format_number("%d" % (current_index + 1)),
			ts.format_number("%d" % questions.size())
		]
	else:
		progress_label.text = tr("QUESTION_PROGRESS") % [current_index + 1, questions.size()]

	npc_bust.play(str(q["animation_talk"]))
	await _type_text("%s: %s" % [display_name, str(q["prompt"])], false)
	_show_choices_after_typing()

func _type_text(full_text: String, show_next: bool = false) -> void:
	typing = true
	dialogue_label.text = ""
	for i in range(full_text.length()):
		dialogue_label.text = full_text.substr(0, i + 1)
		await get_tree().create_timer(TYPE_SPEED).timeout
	typing = false
	if show_next and _next_btn != null:
		_next_btn.visible = true
		await _next_btn.pressed
		_next_btn.visible = false

func _show_choices_after_typing() -> void:
	var q: Dictionary = questions[current_index]
	npc_bust.play(str(q["animation_idle"]))
	choices_hbox.visible = true

func _on_choice_1_pressed() -> void:
	if typing or finished:
		return
	_handle_answer(0)

func _on_choice_2_pressed() -> void:
	if typing or finished:
		return
	_handle_answer(1)

func _handle_answer(chosen_index: int) -> void:
	var q: Dictionary = questions[current_index]
	choices_hbox.visible = false
	choice_button_1.disabled = true
	choice_button_2.disabled = true

	var was_correct: bool = (chosen_index == int(q["correct"]))
	if was_correct:
		correct_count += 1

	_show_feedback(q, was_correct)

func _show_feedback(q: Dictionary, was_correct: bool) -> void:
	var npc_key: String = str(q["npc"])
	var display_name := _get_npc_display_name(npc_key)
	var talk_anim: String = str(q["animation_talk"])
	var idle_anim: String = str(q["animation_idle"])

	var pool: Array = feedback_correct.get(npc_key, []) if was_correct else feedback_wrong.get(npc_key, [])
	if pool.is_empty():
		pool = [tr("WELL_DONE")] if was_correct else [tr("NOT_BEST_CHOICE")]

	var msg: String = str(pool[rng.randi_range(0, pool.size() - 1)])

	npc_bust.play(talk_anim)
	await _type_text("%s: %s" % [display_name, msg], true)

	npc_bust.play(idle_anim)
	choice_button_1.disabled = false
	choice_button_2.disabled = false
	current_index += 1
	_show_current_question()

func _finish_quiz() -> void:
	if finished:
		return

	choices_hbox.visible = false
	choice_button_1.disabled = true
	choice_button_2.disabled = true

	var total: int = questions.size()
	var percent: float = float(correct_count) / float(total)
	var passed: bool = (percent >= PASS_PERCENTAGE)

	var score_text: String
	if Global.current_locale == "ar":
		var ts := TextServerManager.get_primary_interface()
		score_text = tr("SCORE_LABEL") % [
			ts.format_number("%d" % correct_count),
			ts.format_number("%d" % total)
		]
	else:
		score_text = tr("SCORE_LABEL") % [correct_count, total]

	if passed:
		finished = true
		Global.complete_quest(5)
		result_panel.show_success(tr("QUEST_COMPLETED") + "\n" + score_text)
	else:
		result_panel.show_failure(tr("QUEST_FAILED") + "\n" + score_text)

func _on_retry() -> void:
	current_index = 0
	correct_count = 0
	typing = false
	finished = false
	choice_button_1.disabled = false
	choice_button_2.disabled = false
	_show_current_question()

func _on_continue() -> void:
	get_tree().change_scene_to_file("res://scenes/loading_screen.tscn")

func _on_exit() -> void:
	Global.next_scene = "res://overworld.tscn"
	get_tree().change_scene_to_file("res://scenes/loading_screen.tscn")

func _apply_base_font_sizes() -> void:
	dialogue_label.add_theme_font_size_override("font_size", 20)
	choice_button_1.add_theme_font_size_override("font_size", 18)
	choice_button_2.add_theme_font_size_override("font_size", 18)
	progress_label.add_theme_font_size_override("font_size", 16)


func _create_next_button() -> void:
	var is_ar := Global.current_locale == "ar"
	_next_btn = Button.new()
	if is_ar:
		_next_btn.text = "◄ التالي"
		_next_btn.text_direction = Control.TEXT_DIRECTION_RTL
		if Global.arabic_font != null:
			_next_btn.add_theme_font_override("font", Global.arabic_font)
			_next_btn.add_theme_font_size_override("font_size", 18 + Global.ARABIC_SIZE_BONUS)
		# bottom-left in Arabic
		_next_btn.anchor_left   = 0.0
		_next_btn.anchor_right  = 0.0
		_next_btn.anchor_top    = 1.0
		_next_btn.anchor_bottom = 1.0
		_next_btn.offset_left   = 16.0
		_next_btn.offset_right  = 180.0
		_next_btn.offset_top    = -60.0
		_next_btn.offset_bottom = -16.0
	else:
		_next_btn.text = "Next ►"
		_next_btn.add_theme_font_size_override("font_size", 18)
		# bottom-right in English
		_next_btn.anchor_left   = 1.0
		_next_btn.anchor_right  = 1.0
		_next_btn.anchor_top    = 1.0
		_next_btn.anchor_bottom = 1.0
		_next_btn.offset_left   = -180.0
		_next_btn.offset_right  = -16.0
		_next_btn.offset_top    = -60.0
		_next_btn.offset_bottom = -16.0
	_next_btn.layout_mode = 1
	_next_btn.custom_minimum_size = Vector2(140, 44)
	_next_btn.visible = false
	# Attach to the dialog root so it sits inside the dialog canvas
	get_node("UI/DialogRoot").add_child(_next_btn)


func _apply_arabic_font_to_ui() -> void:
	if Global.current_locale != "ar" or Global.arabic_font == null:
		return
	var sized_nodes := {
		dialogue_label:  20,
		progress_label:  16,
		choice_button_1: 18,
		choice_button_2: 18,
	}
	for node in sized_nodes:
		if node != null and is_instance_valid(node):
			node.add_theme_font_override("font", Global.arabic_font)
			node.add_theme_font_size_override("font_size", sized_nodes[node] + Global.ARABIC_SIZE_BONUS)
			if node is Label:
				node.text_direction       = Control.TEXT_DIRECTION_RTL
				node.layout_direction     = Control.LAYOUT_DIRECTION_LTR
				node.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			elif node is Button:
				node.text_direction = Control.TEXT_DIRECTION_RTL
