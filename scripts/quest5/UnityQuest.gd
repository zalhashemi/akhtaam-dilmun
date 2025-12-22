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

# RESULTS UI (make sure these nodes exist in your scene tree)
@onready var results_panel: Control = $UI/ResultsPanel
@onready var result_title: Label = $UI/ResultsPanel/Panel/MarginContainer/VBoxContainer/ResultTitle
@onready var result_score: Label = $UI/ResultsPanel/Panel/MarginContainer/VBoxContainer/ResultScore
@onready var retry_button: Button = $UI/ResultsPanel/Panel/MarginContainer/VBoxContainer/RetryButton

var questions: Array = []
var current_index: int = 0
var correct_count: int = 0
var typing: bool = false

var rng := RandomNumberGenerator.new()

# Lots of variations (NPC-specific)
var feedback_correct := {
	"Merchant": [
		"What a kind thing to do!",
		"That’s true honesty. Bless you.",
		"You have a generous heart.",
		"Fair and kind — that’s the Dilmun way.",
		"You chose mercy over money. Good.",
		"That would earn trust in any market.",
		"You did the right thing. Thank you.",
		"Your kindness will return to you."
	],
	"Fisherman": [
		"That’s a good heart out at sea.",
		"You share when others would take. Respect.",
		"That’s how communities survive.",
		"You’re the kind of crew I’d want.",
		"Good choice — the sea rewards the humble.",
		"That was generous. Well done.",
		"You helped, not judged. Nice.",
		"That’s real strength — helping others."
	],
	"Storyteller": [
		"Beautiful choice — you kept it gentle.",
		"That’s wisdom. Words matter.",
		"You made space for everyone. Well done.",
		"A kind story can heal, not harm.",
		"That’s how you keep peace in a crowd.",
		"You listened first — that’s rare.",
		"You chose compassion. Excellent.",
		"That’s the mark of a good storyteller."
	]
}

var feedback_wrong := {
	"Merchant": [
		"That wasn’t very nice.",
		"That would hurt someone who’s already tired.",
		"Not everything is about profit, you know.",
		"That choice would break trust in the market.",
		"You could have been kinder.",
		"That’s not fair… try again next time.",
		"That’s a cold way to treat people.",
		"That choice would leave someone feeling small."
	],
	"Fisherman": [
		"That choice leaves someone hungry.",
		"That’s not how we look after each other.",
		"You’d lose respect on the docks for that.",
		"That was selfish — the sea doesn’t like that.",
		"That wouldn’t help the community.",
		"That’s a harsh decision for a hard day.",
		"Not a good call… think of others.",
		"That’s not the kind of help they needed."
	],
	"Storyteller": [
		"That would make someone feel left out.",
		"Those words could sting.",
		"That’s not a gentle way to lead.",
		"That choice could start more fighting.",
		"You could have handled that with more care.",
		"Stories should bring people together, not apart.",
		"That wasn’t considerate.",
		"That choice would quiet someone who needs courage."
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
			"prompt": "A tired woman can only pay part of the price for dates. What should you do?",
			"choices": [
				"Give her the dates anyway and wish her well.",
				"Tell her to leave if she can't pay."
			],
			"correct": 0
		},
		{
			"npc": "Merchant",
			"animation_idle": "merchant_idle",
			"animation_talk": "merchant_talk",
			"prompt": "You receive extra coins by mistake. What is the kindest choice?",
			"choices": [
				"Keep the extra coins.",
				"Tell them and return the extra coins."
			],
			"correct": 1
		},
		{
			"npc": "Merchant",
			"animation_idle": "merchant_idle",
			"animation_talk": "merchant_talk",
			"prompt": "A small boy is shy to ask about prices. What do you do?",
			"choices": [
				"Speak gently and explain clearly.",
				"Ignore him and talk only to adults."
			],
			"correct": 0
		},

		# FISHERMAN (3)
		{
			"npc": "Fisherman",
			"animation_idle": "fisherman_idle",
			"animation_talk": "fisherman_talk",
			"prompt": "The catch is small. A family hasn't eaten. What should you do?",
			"choices": [
				"Share some fish with them.",
				"Sell only to high-paying customers."
			],
			"correct": 0
		},
		{
			"npc": "Fisherman",
			"animation_idle": "fisherman_idle",
			"animation_talk": "fisherman_talk",
			"prompt": "A young fisherman keeps making mistakes. How do you help?",
			"choices": [
				"Teach him patiently.",
				"Tell him to give up."
			],
			"correct": 0
		},
		{
			"npc": "Fisherman",
			"animation_idle": "fisherman_idle",
			"animation_talk": "fisherman_talk",
			"prompt": "You find a dropped basket of pearls. What do you do?",
			"choices": [
				"Keep it.",
				"Ask around to find the owner."
			],
			"correct": 1
		},

		# STORYTELLER (3)
		{
			"npc": "Storyteller",
			"animation_idle": "storyteller_idle",
			"animation_talk": "storyteller_talk",
			"prompt": "Two children argue over who heard the story first. What should you do?",
			"choices": [
				"Let both sit and tell it kindly.",
				"Choose one child and ignore the other."
			],
			"correct": 0
		},
		{
			"npc": "Storyteller",
			"animation_idle": "storyteller_idle",
			"animation_talk": "storyteller_talk",
			"prompt": "Your story might hurt someone's feelings. What should you do?",
			"choices": [
				"Tell it more gently.",
				"Say it anyway."
			],
			"correct": 0
		},
		{
			"npc": "Storyteller",
			"animation_idle": "storyteller_idle",
			"animation_talk": "storyteller_talk",
			"prompt": "A shy listener wants to speak. What do you do?",
			"choices": [
				"Give them time and thank them.",
				"Tell them to speak louder or leave."
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

	progress_label.text = "Question %d of %d" % [current_index + 1, questions.size()]


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
	if typing:
		return
	_handle_answer(0)


func _on_choice_2_pressed() -> void:
	if typing:
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
		pool = ["Well done."] if was_correct else ["That wasn’t the best choice."]

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
	choices_hbox.visible = false
	choice_button_1.disabled = true
	choice_button_2.disabled = true

	var total: int = questions.size()
	var percent: float = float(correct_count) / float(total)
	var passed: bool = (percent >= PASS_PERCENTAGE)

	# Show results panel
	results_panel.visible = true
	result_title.text = "Quest Completed!" if passed else "Quest Failed"
	result_score.text = "Score: %d/%d" % [correct_count, total]
	retry_button.visible = not passed

	# Optional: stop NPC animation on results
	# npc_bust.stop()


func _on_retry_pressed() -> void:
	# Reset run
	current_index = 0
	correct_count = 0
	typing = false

	results_panel.visible = false
	choice_button_1.disabled = false
	choice_button_2.disabled = false

	_show_current_question()
