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
	_resize_panel()
	_apply_arabic_font_to_ui()


func _resize_panel() -> void:
	anchor_left   = 0.0
	anchor_top    = 0.0
	anchor_right  = 1.0
	anchor_bottom = 1.0
	offset_left   = 0.0
	offset_top    = 0.0
	offset_right  = 0.0
	offset_bottom = 0.0
	layout_mode   = 1
	mouse_filter  = Control.MOUSE_FILTER_STOP

	var overlay := ColorRect.new()
	overlay.color = Color(0.0, 0.0, 0.0, 0.55)
	overlay.anchor_left   = 0.0
	overlay.anchor_top    = 0.0
	overlay.anchor_right  = 1.0
	overlay.anchor_bottom = 1.0
	overlay.offset_left   = 0.0
	overlay.offset_top    = 0.0
	overlay.offset_right  = 0.0
	overlay.offset_bottom = 0.0
	overlay.layout_mode   = 1
	overlay.mouse_filter  = Control.MOUSE_FILTER_IGNORE
	add_child(overlay)
	move_child(overlay, 0) 

	var panel := $Panel
	panel.anchor_left   = 0.1
	panel.anchor_right  = 0.9
	panel.anchor_top    = 0.1
	panel.anchor_bottom = 0.9
	panel.offset_left   = 0.0
	panel.offset_right  = 0.0
	panel.offset_top    = 0.0
	panel.offset_bottom = 0.0
	panel.layout_mode   = 1

	question_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	question_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	question_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	feedback_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	feedback_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	feedback_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	for node in [question_label, feedback_label]:
		node.add_theme_font_size_override("font_size", node.get_theme_font_size("font_size") + 4)
	for btn in [btn_a, btn_b, btn_c, btn_d, continue_btn]:
		btn.add_theme_font_size_override("font_size", btn.get_theme_font_size("font_size") + 4)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL

func _apply_arabic_font_to_ui() -> void:
	if Global.current_locale != "ar" or Global.arabic_font == null:
		return
	var text_nodes: Array = [
		question_label,
		feedback_label,
		continue_btn,
		btn_a,
		btn_b,
		btn_c,
		btn_d,
	]
	for node in text_nodes:
		if node != null and is_instance_valid(node):
			node.add_theme_font_override("font", Global.arabic_font)
			node.add_theme_font_size_override("font_size", node.get_theme_font_size("font_size") + Global.ARABIC_SIZE_BONUS)
			if node is Label:
				node.text_direction = Control.TEXT_DIRECTION_RTL
				node.layout_direction = Control.LAYOUT_DIRECTION_LTR
			elif node is Button:
				node.text_direction = Control.TEXT_DIRECTION_RTL

func show_question(q: Dictionary) -> void:
	_answered = false
	_correct_index = int(q["correct"])
	_explain_text = str(q.get("explain", ""))
	question_label.text = str(q["question"])

	var opts: Array = q["options"]
	var is_ar := Global.current_locale == "ar"

	btn_a.text = ("أ. " if is_ar else "A. ") + str(opts[0])
	btn_b.text = ("ب. " if is_ar else "B. ") + str(opts[1])
	btn_c.text = ("ج. " if is_ar else "C. ") + str(opts[2])
	btn_d.text = ("د. " if is_ar else "D. ") + str(opts[3])

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
	var is_ar := Global.current_locale == "ar"

	if is_ar:
		feedback_label.text = ("✔ صحيح! " if is_correct else "✖ ليس تماماً. ") + _explain_text
	else:
		feedback_label.text = ("✔ Correct! " if is_correct else "✖ Not quite. ") + _explain_text

	continue_btn.text = "متابعة" if is_ar else "Continue"
	continue_btn.visible = true
	answered.emit(is_correct)

func set_interactive(enabled: bool) -> void:
	btn_a.disabled      = not enabled
	btn_b.disabled      = not enabled
	btn_c.disabled      = not enabled
	btn_d.disabled      = not enabled
	continue_btn.disabled = not enabled

func _on_continue() -> void:
	hide()
