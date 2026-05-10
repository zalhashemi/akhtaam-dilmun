extends Node2D

const PASS_PERCENTAGE := 0.75
const TYPE_SPEED := 0.03
const FEEDBACK_PAUSE := 0.8

@onready var npc_bust: AnimatedSprite2D = $NpcBust
@onready var dialogue_label: Label = $UI/DialogRoot/DialogPanel/MarginContainer/DialogVBox/DialogueLabel
@onready var choice_button_1: Button = $UI/DialogRoot/DialogPanel/MarginContainer/DialogVBox/ChoicesHBox/ChoiceButton1
@onready var choice_button_2: Button = $UI/DialogRoot/DialogPanel/MarginContainer/DialogVBox/ChoicesHBox/ChoiceButton2
@onready var progress_label: Label = $UI/DialogRoot/DialogPanel/MarginContainer/DialogVBox/ProgressLabel
@onready var choices_hbox: HBoxContainer = $UI/DialogRoot/DialogPanel/MarginContainer/DialogVBox/ChoicesHBox

@onready var results_panel: Control = $UI/ResultsPanel
@onready var result_title: Label = $UI/ResultsPanel/Panel/MarginContainer/VBoxContainer/ResultTitle
@onready var result_score: Label = $UI/ResultsPanel/Panel/MarginContainer/VBoxContainer/ResultScore
@onready var retry_button: Button = $UI/ResultsPanel/Panel/MarginContainer/VBoxContainer/RetryButton

var finished := false

var questions: Array = []
var current_index: int = 0
var correct_count: int = 0
var typing: bool = false

var rng := RandomNumberGenerator.new()

var feedback_correct := {
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

var feedback_wrong := {
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

	# Hide results at start
	results_panel.visible = false

	# Wire retry
	retry_button.pressed.connect(_on_retry_pressed)

	choices_hbox.visible = false
	_setup_questions()
	_connect_buttons()
	_show_current_question()


func _connect_buttons() -> void:
	choice_button_1.pressed.connect(_on_choice_1_pressed)
	choice_button_2.pressed.connect(_on_choice_2_pressed)


func _setup_questions() -> void:
	questions = [

		# MERCHANT (3)
		{
			"npc": "Merchant",
			"animation_idle": "merchant_idle",
			"animation_talk": "merchant_talk",
			"prompt": tr("Q5_Q1_PROMPT"),
			"choices": [
				tr("Q5_Q1_A"),
				tr("Q5_Q1_B")
			],
			"correct": 0
		},
		{
			"npc": "Merchant",
			"animation_idle": "merchant_idle",
			"animation_talk": "merchant_talk",
			"prompt": tr("Q5_Q2_PROMPT"),
			"choices": [
				tr("Q5_Q2_A"),
				tr("Q5_Q2_B")
			],
			"correct": 1
		},
		{
			"npc": "Merchant",
			"animation_idle": "merchant_idle",
			"animation_talk": "merchant_talk",
			"prompt": tr("Q5_Q3_PROMPT"),
			"choices": [
				tr("Q5_Q3_A"),
				tr("Q5_Q3_B")
			],
			"correct": 0
		},

		# FISHERMAN (3)
		{
			"npc": "Fisherman",
			"animation_idle": "fisherman_idle",
			"animation_talk": "fisherman_talk",
			"prompt": tr("Q5_Q4_PROMPT"),
			"choices": [
				tr("Q5_Q4_A"),
				tr("Q5_Q4_B")
			],
			"correct": 0
		},
		{
			"npc": "Fisherman",
			"animation_idle": "fisherman_idle",
			"animation_talk": "fisherman_talk",
			"prompt": tr("Q5_Q5_PROMPT"),
			"choices": [
				tr("Q5_Q5_A"),
				tr("Q5_Q5_B")
			],
			"correct": 0
		},
		{
			"npc": "Fisherman",
			"animation_idle": "fisherman_idle",
			"animation_talk": "fisherman_talk",
			"prompt": tr("Q5_Q6_PROMPT"),
			"choices": [
				tr("Q5_Q6_A"),
				tr("Q5_Q6_B")
			],
			"correct": 1
		},

		# STORYTELLER (3)
		{
			"npc": "Storyteller",
			"animation_idle": "storyteller_idle",
			"animation_talk": "storyteller_talk",
			"prompt": tr("Q5_Q7_PROMPT"),
			"choices": [
				tr("Q5_Q7_A"),
				tr("Q5_Q7_B")
			],
			"correct": 0
		},
		{
			"npc": "Storyteller",
			"animation_idle": "storyteller_idle",
			"animation_talk": "storyteller_talk",
			"prompt": tr("Q5_Q8_PROMPT"),
			"choices": [
				tr("Q5_Q8_A"),
				tr("Q5_Q8_B")
			],
			"correct": 0
		},
		{
			"npc": "Storyteller",
			"animation_idle": "storyteller_idle",
			"animation_talk": "storyteller_talk",
			"prompt": tr("Q5_Q9_PROMPT"),
			"choices": [
				tr("Q5_Q9_A"),
				tr("Q5_Q9_B")
			],
			"correct": 0
		},
	]


func _show_current_question() -> void:
	# Always hide results while playing
	results_panel.visible = false

	choices_hbox.visible = false

	if current_index >= questions.size():
		_finish_quiz()
		return

	var q: Dictionary = questions[current_index]

	npc_bust.play(str(q["animation_talk"]))
	_type_text("%s: %s" % [str(q["npc"]), str(q["prompt"])])

	choice_button_1.text = str(q["choices"][0])
	choice_button_2.text = str(q["choices"][1])

	progress_label.text = tr("QUESTION_PROGRESS") % [current_index + 1, questions.size()]


func _type_text(full_text: String) -> void:
	typing = true
	dialogue_label.text = ""

	for i in range(full_text.length()):
		dialogue_label.text = full_text.substr(0, i + 1)
		await get_tree().create_timer(TYPE_SPEED).timeout

	typing = false
	_show_choices_after_typing()


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

	# Hide choices immediately and stop double-taps
	choices_hbox.visible = false
	choice_button_1.disabled = true
	choice_button_2.disabled = true

	var was_correct: bool = (chosen_index == int(q["correct"]))
	if was_correct:
		correct_count += 1

	_show_feedback(q, was_correct)


func _show_feedback(q: Dictionary, was_correct: bool) -> void:
	var npc_name: String = str(q["npc"])
	var talk_anim: String = str(q["animation_talk"])
	var idle_anim: String = str(q["animation_idle"])

	var pool: Array = feedback_correct.get(npc_name, []) if was_correct else feedback_wrong.get(npc_name, [])
	if pool.is_empty():
		pool = [tr("WELL_DONE")] if was_correct else ["That wasn’t the best choice."]

	var msg: String = str(pool[rng.randi_range(0, pool.size() - 1)])

	npc_bust.play(talk_anim)
	await _type_feedback_text("%s: %s" % [npc_name, msg])

	npc_bust.play(idle_anim)
	await get_tree().create_timer(FEEDBACK_PAUSE).timeout

	# Re-enable for next question
	choice_button_1.disabled = false
	choice_button_2.disabled = false

	current_index += 1
	_show_current_question()


func _type_feedback_text(full_text: String) -> void:
	typing = true
	dialogue_label.text = ""

	for i in range(full_text.length()):
		dialogue_label.text = full_text.substr(0, i + 1)
		await get_tree().create_timer(TYPE_SPEED).timeout

	typing = false


func _finish_quiz() -> void:
	if finished:
		return

	choices_hbox.visible = false
	choice_button_1.disabled = true
	choice_button_2.disabled = true

	var total: int = questions.size()
	var percent: float = float(correct_count) / float(total)
	var passed: bool = (percent >= PASS_PERCENTAGE)

	results_panel.visible = true
	result_title.text = tr("QUEST_COMPLETED") if passed else tr("QUEST_FAILED")
	result_score.text = tr("SCORE_LABEL") % [correct_count, total]
	retry_button.visible = not passed

	if passed:
		finished = true
		Global.complete_quest(5)
		await get_tree().create_timer(1.2).timeout
		Global.next_scene = "res://overworld.tscn"
		get_tree().change_scene_to_file("res://scenes/loading_screen.tscn")



func _on_retry_pressed() -> void:
	current_index = 0
	correct_count = 0
	typing = false
	finished = false

	results_panel.visible = false
	choice_button_1.disabled = false
	choice_button_2.disabled = false

	_show_current_question()
