extends Control
class_name DialogBox

signal answered(is_correct: bool)

@onready var question_label: Label = $Panel/VBox/QuestionLabel
@onready var feedback_label: Label = $Panel/VBox/FeedbackLabel
@onready var continue_btn: Button = $Panel/VBox/ContinueBtn

@onready var btn_a: Button = $Panel/VBox/Answers/BtnA
@onready var btn_b: Button = $Panel/VBox/Answers/BtnB
@onready var btn_c: Button = $Panel/VBox/Answers/BtnC
@onready var btn_d: Button = $Panel/VBox/Answers/BtnD

var _correct_index: int = 0
var _answered := false
var _explain_text := ""

func _ready() -> void:
	hide()
	feedback_label.text = ""
	continue_btn.visible = false

	btn_a.pressed.connect(func(): _choose(0))
	btn_b.pressed.connect(func(): _choose(1))
	btn_c.pressed.connect(func(): _choose(2))
	btn_d.pressed.connect(func(): _choose(3))
	continue_btn.pressed.connect(_on_continue)

func show_question(q: Dictionary) -> void:
	_answered = false
	_correct_index = int(q["correct"])
	_explain_text = str(q.get("explain", ""))

	question_label.text = str(q["question"])

	var opts: Array = q["options"]
	btn_a.text = "A. " + str(opts[0])
	btn_b.text = "B. " + str(opts[1])
	btn_c.text = "C. " + str(opts[2])
	btn_d.text = "D. " + str(opts[3])

	feedback_label.text = ""
	continue_btn.visible = false

	btn_a.disabled = false
	btn_b.disabled = false
	btn_c.disabled = false
	btn_d.disabled = false

	show()

func _choose(index: int) -> void:
	if _answered:
		return
	_answered = true

	btn_a.disabled = true
	btn_b.disabled = true
	btn_c.disabled = true
	btn_d.disabled = true

	var is_correct := index == _correct_index
	feedback_label.text = ("✔ Correct! " if is_correct else "✖ Not quite. ") + _explain_text

	continue_btn.visible = true
	answered.emit(is_correct)

func _on_continue() -> void:
	hide()
