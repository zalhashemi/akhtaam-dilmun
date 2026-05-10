extends Node2D

const _InstructionPanel = preload("res://scripts/InstructionPanel.gd")

@onready var ui_label: Label = $UI/Label
@onready var shards_holder: Node = $Shards
@onready var timer_label: Label = $UI/TimerLabel
@onready var countdown_timer: Timer = $CountdownTimer
@onready var result_panel: CanvasLayer = $QuestResultPanel

var finished := false
var _game_started := false

func _ready():
	ui_label.text = tr("Q2_INTRO")
	countdown_timer.wait_time = 120.0
	countdown_timer.one_shot = true
	countdown_timer.timeout.connect(_on_timer_timeout)
	result_panel.retry_pressed.connect(_on_retry)
	result_panel.exit_pressed.connect(_on_exit)
	result_panel.continue_pressed.connect(_on_continue)
	_apply_arabic_font_to_ui()
	# Show labels immediately so they're visible during the tutorial
	ui_label.visible = true
	timer_label.visible = true
	var _init_time := "02:00"
	if Global.current_locale == "ar":
		timer_label.text = TextServerManager.get_primary_interface().format_number(_init_time)
	else:
		timer_label.text = _init_time
	var _input_overlay: Node = load("res://scripts/InputHintOverlay.gd").new()
	_input_overlay.setup("mouse")
	add_child(_input_overlay)
	_start_onboarding()


func _start_onboarding() -> void:
	var tut: Node = load("res://scripts/OnboardingTutorial.gd").new()
	tut.setup([
		{
			"en": "These are the broken artifact pieces \u2014 scattered across the board.",
			"ar": "\u0647\u0630\u0647 \u0642\u0637\u0639 \u0627\u0644\u0623\u062b\u0631 \u0627\u0644\u0645\u0643\u0633\u0648\u0631 \u0627\u0644\u0645\u0628\u0639\u062b\u0631\u0629 \u0639\u0644\u0649 \u0627\u0644\u0644\u0648\u062d\u0629.",
			"target": Vector2(0.19, 0.40),
			"align": "right"
		},
		{
			"en": "Drag each piece and drop it into its matching spot. It snaps when correct!",
			"ar": "\u0627\u0633\u062d\u0628 \u0643\u0644 \u0642\u0637\u0639\u0629 \u0648\u0623\u0641\u0644\u062a\u0647\u0627 \u0641\u064a \u0645\u0643\u0627\u0646\u0647\u0627 \u0627\u0644\u0635\u062d\u064a\u062d. \u0633\u062a\u0644\u062a\u0635\u0642 \u0639\u0646\u062f \u0627\u0644\u0635\u0648\u0627\u0628!",
			"target": Vector2(0.5, 0.38),
			"align": "bottom"
		},
		{
			"en": "The timer starts now! You have 2 minutes \u2014 finish before it runs out.",
			"ar": "\u0627\u0644\u0645\u0624\u0642\u062a \u064a\u0628\u062f\u0623 \u0627\u0644\u0622\u0646! \u0644\u062f\u064a\u0643 \u062f\u0642\u064a\u0642\u062a\u0627\u0646 \u2014 \u0623\u0646\u0647\u0650 \u0642\u0628\u0644 \u0646\u0641\u0627\u062f\u0647.",
			"target": Vector2(0.88, 0.04),
			"target_ar": Vector2(0.11, 0.06),
			"align": "bottom"
		},
	])
	tut.tutorial_done.connect(func():
		_game_started = true
		countdown_timer.start()
	)
	add_child(tut)

func _process(_delta):
	if finished or not _game_started:
		return
	_update_timer_label()

func _update_timer_label():
	var remaining := int(ceil(countdown_timer.time_left))
	var minutes := remaining / 60
	var seconds := remaining % 60
	var formatted := "%02d:%02d" % [minutes, seconds]
	if Global.current_locale == "ar":
		timer_label.text = TextServerManager.get_primary_interface().format_number(formatted)
	else:
		timer_label.text = formatted

func _check_puzzle_complete():
	if finished:
		return
	for shard in shards_holder.get_children():
		if shard is Area2D and not shard.placed_correctly:
			return
	_on_puzzle_complete()

func _on_puzzle_complete():
	if finished:
		return
	finished = true
	countdown_timer.stop()
	timer_label.visible = false
	Global.complete_quest(2)
	result_panel.show_success(tr("QUEST_COMPLETED_ALT"))

func _on_timer_timeout():
	if finished:
		return
	finished = true
	timer_label.visible = false
	result_panel.show_failure(tr("QUEST_FAILED"))

func _on_retry() -> void:
	get_tree().reload_current_scene()

func _on_continue() -> void:
	get_tree().change_scene_to_file("res://scenes/loading_screen.tscn")

func _on_exit() -> void:
	Global.next_scene = "res://overworld.tscn"
	get_tree().change_scene_to_file("res://scenes/loading_screen.tscn")

func _apply_arabic_font_to_ui() -> void:
	if Global.current_locale != "ar" or Global.arabic_font == null:
		return
	var lbl := $UI/Label
	if lbl != null:
		lbl.add_theme_font_override("font", Global.arabic_font)
		lbl.add_theme_font_size_override("font_size", lbl.get_theme_font_size("font_size") + Global.ARABIC_SIZE_BONUS - 2)
		lbl.add_theme_constant_override("line_spacing", -12)
		lbl.text_direction = Control.TEXT_DIRECTION_RTL
	var tmr := $UI/TimerLabel
	if tmr != null:
		tmr.add_theme_font_override("font", Global.arabic_font)
		tmr.add_theme_font_size_override("font_size", tmr.get_theme_font_size("font_size") + Global.ARABIC_SIZE_BONUS)
		tmr.text_direction = Control.TEXT_DIRECTION_RTL
