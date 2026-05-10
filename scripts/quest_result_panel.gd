extends CanvasLayer

signal retry_pressed
signal continue_pressed
signal exit_pressed

@onready var panel        : Control       = $Panel
@onready var result_label : Label         = $Panel/VBox/ResultLabel
@onready var continue_btn : TextureButton = $Panel/VBox/ContinueButton
@onready var retry_btn    : TextureButton = $Panel/VBox/RetryButton
@onready var exit_btn     : TextureButton = $Panel/VBox/ExitButton
@onready var continue_lbl : Label         = $Panel/VBox/ContinueButton/Label
@onready var retry_lbl    : Label         = $Panel/VBox/RetryButton/Label
@onready var exit_lbl     : Label         = $Panel/VBox/ExitButton/Label

var _preload_started: bool = false


func _ready() -> void:
	panel.visible = false
	continue_btn.pressed.connect(_on_continue_pressed)
	retry_btn.pressed.connect(_on_retry_pressed)
	exit_btn.pressed.connect(_on_exit_pressed)
	_apply_language()


func _apply_language() -> void:
	var is_ar := Global.language == "ar"
	continue_lbl.text = "متابعة"        if is_ar else "Continue"
	retry_lbl.text    = "حاول مجدداً"   if is_ar else "Retry"
	exit_lbl.text     = "الخريطة"       if is_ar else "Back to Overworld"

	var dir := Control.LAYOUT_DIRECTION_RTL if is_ar else Control.LAYOUT_DIRECTION_LTR
	for node in [result_label, continue_lbl, retry_lbl, exit_lbl]:
		node.layout_direction = dir
		node.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	if is_ar:
		result_label.add_theme_constant_override("line_spacing", -20)
	else:
		result_label.remove_theme_constant_override("line_spacing")

	if is_ar and Global.arabic_font != null:
		for node in [result_label, continue_lbl, retry_lbl, exit_lbl]:
			node.add_theme_font_override("font", Global.arabic_font)
			if node is Label:
				node.text_direction = Control.TEXT_DIRECTION_RTL
				node.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER


func show_success(message: String = "") -> void:
	var is_ar := Global.language == "ar"
	result_label.text = message if message != "" else ("أحسنت! اكتملت المهمة" if is_ar else "Quest Completed!")
	result_label.add_theme_color_override("font_color", Color("#F2B983"))
	continue_btn.visible = true
	retry_btn.visible    = false
	exit_btn.visible     = false
	panel.visible        = true
	get_tree().paused    = true
	_begin_preload()


func show_failure(message: String = "") -> void:
	var is_ar := Global.language == "ar"
	result_label.text = message if message != "" else ("فشلت المهمة" if is_ar else "Quest Failed!")
	result_label.add_theme_color_override("font_color", Color("#C12621"))
	continue_btn.visible = false
	retry_btn.visible    = true
	exit_btn.visible     = true
	panel.visible        = true
	get_tree().paused    = true


func _begin_preload() -> void:
	if _preload_started:
		return
	_preload_started = true
	Global.next_scene = "res://overworld.tscn"
	ResourceLoader.load_threaded_request("res://overworld.tscn")


func hide_panel() -> void:
	panel.visible     = false
	get_tree().paused = false


func _on_continue_pressed() -> void:
	hide_panel()
	continue_pressed.emit()


func _on_retry_pressed() -> void:
	hide_panel()
	retry_pressed.emit()


func _on_exit_pressed() -> void:
	hide_panel()
	exit_pressed.emit()
